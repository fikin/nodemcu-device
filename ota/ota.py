import typing
import argparse
import os
import json
import io
import requests
import requests.auth
from typing import TypedDict
from rich.table import Table
import rich.progress
from rich.console import Console
import logging
import rich.logging
import hashlib

FORMAT = "%(message)s"
logging.basicConfig(
    level=logging.DEBUG, format=FORMAT, datefmt="[%X]", handlers=[rich.logging.RichHandler()]
)

log = logging.getLogger("rich")
console = Console()


class Opts(TypedDict):
    usr: str
    pwd: str
    includeBootstrap: bool
    listOnly: bool
    ignoreOtaReleaseErrs: bool
    noRestart: bool


def addmethod(obj, name, func):
    klass = obj.__class__
    subclass = type(klass.__name__, (klass,), {})
    setattr(subclass, name, func)
    obj.__class__ = subclass


def wrapGetResponseWithProgress(response: requests.Response) -> typing.BinaryIO:
    def readlinesFn(self, hint):
        '''mimic urlopen response capabilities but from requests lib'''
        return response.text.splitlines()
    addmethod(response, "readlines", readlinesFn)

    def readFn(self, hint):
        '''mimic urlopen response capabilities but from requests lib'''
        return response.text
    addmethod(response, "read", readFn)
    size = int(response.headers.get("Content-Length") or 0)
    return rich.progress.wrap_file(file=response, total=size, description="Reading %s..." % response.url)


def getFileMd5hash(fileLoc: str) -> str:
    with open(fileLoc, "rb") as ff:
        data = ff.read()
        return hashlib.md5(data).hexdigest()


def logHttpResponse(response: requests.Response) -> None:
    if response.status_code != 200:
        log.error("POST %s failed[\] : %d : %s" %
                  (response.url, response.status_code, response))


def indexSwRelease(data: list[str]) -> dict[str, str]:
    ret = {}
    for line in data:
        arr = line.split()
        ret[arr[1]] = arr[0]
    ss = ("\n".join(data) + "\n").encode()
    ret["release"] = hashlib.md5(ss).hexdigest()
    return ret


def readSwReleaseFile(fName: str) -> dict[str, str]:
    with rich.progress.open(fName, "r", description="Reading %s..." % fName) as f:
        return indexSwRelease(f.readlines())


def readRemoteSwVersion(usr: str, pwd: str, urlStr: str) -> str:
    bb = requests.auth.HTTPBasicAuth(usr, pwd)
    with requests.get(urlStr, auth=bb) as response:
        with wrapGetResponseWithProgress(response) as rr:
            return json.load(rr)


def readSwReleaseUrl(ignoreOtaErr: bool, usr: str, pwd: str, urlStr: str) -> dict[str, str]:
    bb = requests.auth.HTTPBasicAuth(usr, pwd)
    with requests.get(urlStr, auth=bb) as response:
        with wrapGetResponseWithProgress(response) as rr:
            if response.status_code != 200:
                log.error("failed getting %s : %d : %s", urlStr,
                          response.status_code, response)
                if ignoreOtaErr:
                    return {}
                else:
                    raise Exception("failed getting OTA release data")
            return indexSwRelease(rr.readlines())


def uploadFile(fName: str, usr: str, pwd: str,  destUrl: str) -> None:
    bb = requests.auth.HTTPBasicAuth(usr, pwd)
    with rich.progress.open(fName, "rb", description="Uploading %s ..." % fName) as data:
        log.debug("POST %s ...", destUrl)
        with requests.post(url=destUrl, data=data, auth=bb) as response:
            logHttpResponse(response)


def requestRestart(usr: str, pwd: str, host: str) -> None:
    bb = requests.auth.HTTPBasicAuth(usr, pwd)
    u = "%s/ota?restart" % host
    log.debug("POST %s ...", u)
    with requests.post(url=u, auth=bb) as response:
        logHttpResponse(response)


def upgradeRemote(dist: str, usr: str, pwd: str, host: str, lst: list[str]) -> None:
    for k in lst:
        filename = "%s/%s" % (dist, k)
        urlPath = "%s/ota/%s" % (host, k)
        uploadFile(filename, usr, pwd, urlPath)


def printReleaseData(dist: str, host: str, includeBootstrap: bool, indxLocal: dict[str, str], indxRemote: dict[str, str]) -> list[str]:
    ret = []
    table = Table(show_header=True, header_style="bold magenta",
                  title="Sw release")
    table.add_column("File")
    table.add_column("Local repo\n%s" % dist)
    table.add_column("Remote host\n%s" % host)
    for k, v in indxLocal.items():
        if not includeBootstrap and os.path.splitext(k)[0] == "bootstrap-sw":
            continue
        elif v == indxRemote.get(k):
            table.add_row(k, v, indxRemote[k])
        else:
            table.add_row("[bold red]%s[/bold red]" % k,
                          "[bold]%s[/bold]" % v,
                          "[bold]%s[/bold]" % indxRemote.get(k))
            ret.append(k)
    for k, v in indxRemote.items():
        if not indxLocal.get(k):
            table.add_row(k, "None", v)
    console.print(table)
    return ret


def upgradeSpiffsFs(opts: Opts, dist: str, host: str) -> None:
    fRelName = "%s/release" % dist
    indxLocal = readSwReleaseFile(fRelName)
    indxLocal["release"] = getFileMd5hash(fRelName)
    updateSwTo(opts, dist, host, indxLocal)


def upgradeFile(opts: Opts, fileLoc: io.TextIOWrapper, host: str) -> None:
    dirName = os.path.dirname(fileLoc.name)
    fName = os.path.basename(fileLoc.name)
    indxLocal = {fName: getFileMd5hash(fileLoc.name)}
    updateSwTo(opts, dirName, host, indxLocal)


def updateSwTo(opts: Opts, dist: str, host: str, indxLocal: dict[str, str]) -> None:
    log.info("%s version : %s", host, readRemoteSwVersion(
        opts["usr"], opts["pwd"], "%s/ota?version" % host))
    indxRemote = readSwReleaseUrl(
        opts["ignoreOtaReleaseErrs"], opts["usr"], opts["pwd"], "%s/ota?release" % host)
    toupd = printReleaseData(
        dist, host, opts["includeBootstrap"], indxLocal, indxRemote)
    if not opts["listOnly"]:
        upgradeRemote(dist, opts["usr"], opts["pwd"], host, toupd)
        if len(toupd) > 0 and not opts["noRestart"]:
            requestRestart(opts["usr"], opts["pwd"], host)


def dir_path(path: str) -> str:
    if os.path.isdir(path):
        return path
    else:
        raise argparse.ArgumentTypeError(
            f"readable_dir:{path} is not a valid path")


def newArgsParser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description='OTA sw uploader for NodeMCU device')
    parser.add_argument(
        '-usr', type=str, help="OTA service user to use to access NodeMCU device", required=True)
    parser.add_argument(
        '-pwd', type=str, help="OTA service user password", required=True)
    parser.add_argument('-host', type=str,
                        help="NodeMCU host name i.e. <host.domain>[:port]", required=True)
    parser.add_argument('-include-bootstrap-sw', type=bool, default=False,  action=argparse.BooleanOptionalAction,
                        help="Upgrade also boostrap-sw.lua/lc file, by default it is excluded")
    parser.add_argument('-list-only', type=bool, default=False,  action=argparse.BooleanOptionalAction,
                        help="List OTA versions, do not update it")
    parser.add_argument('-ignore-ota-release-errs', type=bool, default=False,  action=argparse.BooleanOptionalAction,
                        help="Ignore errors from OTA release reading and continue with update")
    parser.add_argument('-no-restart', type=bool, default=False,  action=argparse.BooleanOptionalAction,
                        help="Do not restart device after upgrade")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "-spiffsdir", help="Upgrade sw from SPIFFS dir i.e. vendor/nodemcu-firmware/local/fs", type=dir_path)
    group.add_argument(
        "-file", help="Upgrade single file from SPIFFS", type=argparse.FileType("r"))
    group.add_argument(
        "-restart", help="Restart NodeMCU device", type=bool, default=False, action=argparse.BooleanOptionalAction,)
    return parser


def main():
    parser = newArgsParser()
    try:
        args = parser.parse_args()
        opts = Opts({"usr": args.usr, "pwd": args.pwd,
                    "includeBootstrap": args.include_bootstrap_sw, "listOnly": args.list_only,
                     "ignoreOtaReleaseErrs": args.ignore_ota_release_errs,
                     "noRestart": args.no_restart})
        u = "http://%s" % args.host
        if args.spiffsdir:
            upgradeSpiffsFs(opts, args.spiffsdir, u)
        elif args.file:
            upgradeFile(opts, args.file, u)
        elif args.restart:
            requestRestart(opts["usr"], opts["pwd"], u)
        else:
            raise Exception("missing cmdline option")
    except Exception as e:
        log.exception(e)
        exit(1)


if __name__ == "__main__":
    main()
