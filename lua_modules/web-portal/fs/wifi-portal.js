const cfg = { data: { wifi: { country: {} }, sta: { config: {} } } }

function getDeviceSettingsFor(modName) {
  return window.location.href + 'wifi-portal-ds/' + modName;
}

document.querySelector('#save').addEventListener('click', (event) => {
  [["wifi", cfg.data.wifi],
  ["wifi-sta", cfg.data.sta],
  ["wifi-ap", cfg.data.ap],
  ["web-portal", cfg.data.webPortal]
  ].map(x =>
    fetch(getDeviceSettingsFor(x[0]), {
      method: 'POST', // or 'PUT'
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(x[1]),
    })
      .then((response) => response.json())
      .then((data) => {
        console.log('Success:', data);
      })
      .catch((error) => {
        console.error('Error:', error);
      }));
});

function setInputEvent(selectorId, setFnc) {
  const elem = document.querySelector(selectorId);
  elem.addEventListener('input', (event) => {
    setFnc(elem.value);
  });
}
setInputEvent('#ssid', function (v) { cfg.data.sta.config.ssid = v; })
setInputEvent('#pwd', function (v) { cfg.data.sta.config.pwd = v; })
setInputEvent('#hostname', function (v) {
  cfg.data.sta.hostname = v;
  cfg.data.ap.config.ssid = v + '_ap';
})
setInputEvent('#country', function (v) { cfg.data.wifi.country.country = v; })
setInputEvent('#ap_pwd', function (v) { cfg.data.ap.config.pwd = v; })
setInputEvent('#admin_usr', function (v) { cfg.data.webPortal.usr = v; })
setInputEvent('#admin_pwd', function (v) { cfg.data.webPortal.pwd = v; })

function setData(selectorId, v) {
  document.querySelector(selectorId).value = v;
}
fetch(getDeviceSettingsFor('wifi'), {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
})
  .then((response) => response.json())
  .then((data) => {
    cfg.data.wifi = data;
    setData('#country', cfg.data.wifi.country.country);
  })
  .catch((error) => {
    console.error('Error:', error);
  });
fetch(getDeviceSettingsFor('wifi-sta'), {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
})
  .then((response) => response.json())
  .then((data) => {
    cfg.data.sta = data;
    setData('#ssid', cfg.data.sta.config.ssid);
    setData('#pwd', cfg.data.sta.config.pwd);
    setData('#hostname', cfg.data.sta.hostname);
  })
  .catch((error) => {
    console.error('Error:', error);
  });
fetch(getDeviceSettingsFor('wifi-ap'), {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
})
  .then((response) => response.json())
  .then((data) => {
    cfg.data.ap = data;
    setData('#ap_pwd', cfg.data.ap.config.pwd);
  })
  .catch((error) => {
    console.error('Error:', error);
  });
fetch(getDeviceSettingsFor('web-portal'), {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
})
  .then((response) => response.json())
  .then((data) => {
    cfg.data.webPortal = data;
    setData('#admin_usr', cfg.data.webPortal.usr);
    setData('#admin_pwd', cfg.data.webPortal.pwd);
  })
  .catch((error) => {
    console.error('Error:', error);
  });
