const cfg = {}

function getDeviceSettingsFor(modName) {
  return window.location.origin + '/wifi-portal-ds/' + modName;
}

function camelCaseToDashed(cc) {
  return cc.replace(/[A-Z]/g, '-$&').toLowerCase()
}

function dashToUnderscore(str) {
  return str.replaceAll("#", "_")
}

class MissingDSFile extends Error { }
class MissingDSField extends Error { }

function getCfgValue(cfgTbl, keysArr, indx) {
  const key = dashToUnderscore(keysArr[indx]);
  const val = cfgTbl[key];
  if (typeof val === "undefined") {
    throw (indx == 0) ?
      new MissingDSFile('missing device settings file "' + getDeviceSettingsFor(camelCaseToDashed(key)) + '"') :
      new MissingDSField('missing device settings key "' + key + '"')
  }
  indx++;
  if (keysArr.length > indx) { return getCfgValue(val, keysArr, indx); }
  else { return val; }
}

function updateElemValueType(elem, val) {
  if (typeof val === "boolean") {
    elem.value = val;
  } else if (Array.isArray(val)) {
    val.forEach(e => {
      Array.from(elem.options).filter(opt => opt.value == e).map(opt => opt.selected = true)
    })
  } else {
    elem.value = val;
  }
}

function updateElemValue(elem) {
  try {
    const val = getCfgValue(cfg, elem.id.split("_"), 0);
    updateElemValueType(elem, val)
  } catch (e) {
    if (e instanceof MissingDSFile);
    else if (e instanceof MissingDSField) console.warn(e)
    else console.error(e)
  }
}

function getCfgValueElem(cfgVal, elem) {
  if (typeof cfgVal === "number") {
    return parseInt(elem.value)
  } else if (Array.isArray(cfgVal)) {
    return Array.from(elem.options)
      .filter(opt => opt.selected)
      .filter(opt => opt.value !== String.fromCharCode(160))
      .map(opt => opt.value)
  } else if (typeof cfgVal === "boolean") {
    return elem.value === "true"
  } else {
    return elem.value
  };
}

function setCfgValue(cfgTbl, keysArr, elem) {
  const key = dashToUnderscore(keysArr[0]);
  const val = cfgTbl[key];
  if (typeof val === "undefined") {
    console.warn("missing key " + key);
    cfgTbl[key] = {};
    setCfgValue(cfgTbl, keysArr, elem) // repeat
  } else if (keysArr.length > 1) {
    setCfgValue(val, keysArr.slice(1), elem)
  } else {
    cfgTbl[key] = getCfgValueElem(val, elem)
  }
}

function updateCfgValue(elem) {
  setCfgValue(cfg, elem.id.split("_"), elem);
}

function configureInputEvents() {
  var coll = document.getElementsByClassName("cfgValue");
  for (var i = 0; i < coll.length; i++) {
    coll[i].addEventListener('input', (event) => {
      updateCfgValue(event.target);
    });
  }
}

function configureInputEventsForHostname() {
  document.querySelector("#wifiSta_hostname").addEventListener('input', (event) => {
    setCfgValue(cfg, "wifiAp_config_ssid".split("_"), event.target.value + "_ap");
  });
}

function updateElementValues(cfgModule) {
  var elems = document.getElementsByClassName("cfgValue");
  for (var i = 0; i < elems.length; i++) {
    const e = elems[i];
    if (e.id.startsWith(cfgModule + "_"))
      updateElemValue(elems[i]);
  }
}

function postDeviceSettings(cfgName) {
  document.body.style.cursor = 'wait'
  return fetch(getDeviceSettingsFor(camelCaseToDashed(cfgName)), {
    method: 'POST', // or 'PUT'
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(cfg[cfgName]),
  })
    .then((response) => {
      if (response.ok) {
        return response.text();
      }
      return Promise.reject(response);
    })
    .then((data) => {
      console.log('Success:', data)
    })
    .catch((error) => {
      console.error('Error:', error, cfgName);
      alert(`Error: ${error.url} responded with ${error.statusText} while saving ${cfgName}`)
      throw error;
    }).then(() => document.body.style.cursor = 'default');
}

function askDeviceRestart() {
  return fetch(getDeviceSettingsFor(".restart"), {
    method: 'POST', // or 'PUT'
    headers: {
      'Content-Type': 'application/json',
    },
  })
    .then((response) => {
      if (response.ok) {
        return response.text();
      }
      return Promise.reject(response);
    })
    .then((data) => {
      console.log('Success:', data);
    })
    .catch((error) => {
      console.error('Error:', error);
      alert(`Error: ${error.url} responded with ${error.statusText} while requesting device restart`)
      throw error;
    });
}

function configureSaveData() {
  document.querySelector('#save').addEventListener('click', (event) => {
    Object.entries(cfg)
      .map(entry => () => postDeviceSettings(entry[0]))
      .concat(() => askDeviceRestart())
      .reduce(
        (before, after) => before.then(_ => after()),
        Promise.resolve()
      )
  });
}

function fetchDeviceSettings(cfgName, cb) {
  document.body.style.cursor = 'wait'
  fetch(getDeviceSettingsFor(camelCaseToDashed(cfgName)), {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  })
    .then((response) => {
      if (response.ok) {
        return response.json();
      }
      return Promise.reject(response);
    })
    .then(cb)
    .catch((error) => {
      console.error('Error:', error, cfgName);
      alert(`Error: ${error.url} responded with ${error.statusText} while fetching ${cfgName}`)
      throw error;
    }).then(() => document.body.style.cursor = 'default');
}

function loadCfgData(cfgName, data) {
  cfg[cfgName] = data;
  updateElementValues(cfgName);
}

function getListOfCfgModuleNamesFor(parentElem) {
  const lst = new Set()
  const elems = parentElem.getElementsByClassName("cfgValue");
  for (var i = 0; i < elems.length; i++) {
    const cfgName = elems[i].id.split("_")[0];
    lst.add(cfgName)
  }
  return lst;
}

function loadDeviceSettingsDataFor(gridElem) {
  for (const cfgName of getListOfCfgModuleNamesFor(gridElem)) {
    if (typeof cfg[cfgName] === "undefined")
      fetchDeviceSettings(cfgName, (data) => loadCfgData(cfgName, data));
  }
}

function setupCollapsibleContentControl(item) {
  item.addEventListener("click", function () {
    this.classList.toggle("active");
    var contentElem = this.nextElementSibling;
    if (contentElem.style.display === "grid") {
      contentElem.style.display = "none";
    } else {
      contentElem.style.display = "grid";
      loadDeviceSettingsDataFor(contentElem)
    }
  });
}

function configureCollapsibleContent() {
  var coll = document.getElementsByClassName("collapsible");
  for (var i = 0; i < coll.length; i++) {
    setupCollapsibleContentControl(coll[i]);
  }
}

function configureWindow() {
  window.onerror = function (message, url, line) {
    alert(message + ', ' + url + ', ' + line);
  };
}

configureInputEvents();
configureInputEventsForHostname()
configureSaveData();
configureCollapsibleContent();
configureWindow();
