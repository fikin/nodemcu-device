const wifiConfigJson = 'device-settings.json';
const cfg = { data: { wifi: { country: {} }, sta: { config: {} } } }

document.querySelector('#save').addEventListener('click', (event) => {
  fetch(window.location.href + wifiConfigJson, {
    method: 'POST', // or 'PUT'
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(cfg.data),
  })
    .then((response) => response.json())
    .then((data) => {
      console.log('Success:', data);
    })
    .catch((error) => {
      console.error('Error:', error);
    });
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
fetch(window.location.href + wifiConfigJson, {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
})
  .then((response) => response.json())
  .then((data) => {
    cfg.data = data;
    setData('#ssid', cfg.data.sta.config.ssid);
    setData('#pwd', cfg.data.sta.config.pwd);
    setData('#hostname', cfg.data.sta.hostname);
    setData('#country', cfg.data.wifi.country.country);
    setData('#ap_pwd', cfg.data.ap.config.pwd);
    setData('#admin_usr', cfg.data.webPortal.usr);
    setData('#admin_pwd', cfg.data.webPortal.pwd);
  })
  .catch((error) => {
    console.error('Error:', error);
  });
