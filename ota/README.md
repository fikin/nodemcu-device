# OTA python client

It can upload `spiffs` directory to NodeMCU device with `web-ota` module set on.

```shell
python3 ota.py -usr <usr> -pwd <pwd> -host <host.domain> -spiffsdir ../vendor/nodemcu-firmware/local/fs 
```

It supports listing and comparing release info between device and local folder.

It supports upload of single file.

See help for complete set of options:

```shell
python3 ota.py -help
```
