local modname = ...

---resolves reason to its text
---@param reason integer
---@return string
local function main(reason)
  package.loaded[modname] = nil

  local wifi = require("wifi")
  local t = {
    [wifi.eventmon.reason.UNSPECIFIED] = "UNSPECIFIED",
    [wifi.eventmon.reason.AUTH_EXPIRE] = "AUTH_EXPIRE",
    [wifi.eventmon.reason.AUTH_LEAVE] = "AUTH_LEAVE",
    [wifi.eventmon.reason.ASSOC_EXPIRE] = "ASSOC_EXPIRE",
    [wifi.eventmon.reason.ASSOC_TOOMANY] = "ASSOC_TOOMANY",
    [wifi.eventmon.reason.NOT_AUTHED] = "NOT_AUTHED",
    [wifi.eventmon.reason.NOT_ASSOCED] = "NOT_ASSOCED",
    [wifi.eventmon.reason.ASSOC_LEAVE] = "ASSOC_LEAVE",
    [wifi.eventmon.reason.ASSOC_NOT_AUTHED] = "ASSOC_NOT_AUTHED",
    [wifi.eventmon.reason.DISASSOC_PWRCAP_BAD] = "DISASSOC_PWRCAP_BAD",
    [wifi.eventmon.reason.DISASSOC_SUPCHAN_BAD] = "DISASSOC_SUPCHAN_BAD",
    [wifi.eventmon.reason.IE_INVALID] = "IE_INVALID",
    [wifi.eventmon.reason.MIC_FAILURE] = "MIC_FAILURE",
    [wifi.eventmon.reason["4WAY_HANDSHAKE_TIMEOUT"]] = "4WAY_HANDSHAKE_TIMEOUT",
    [wifi.eventmon.reason.GROUP_KEY_UPDATE_TIMEOUT] = "GROUP_KEY_UPDATE_TIMEOUT",
    [wifi.eventmon.reason.IE_IN_4WAY_DIFFERS] = "IE_IN_4WAY_DIFFERS",
    [wifi.eventmon.reason.GROUP_CIPHER_INVALID] = "GROUP_CIPHER_INVALID",
    [wifi.eventmon.reason.PAIRWISE_CIPHER_INVALID] = "PAIRWISE_CIPHER_INVALID",
    [wifi.eventmon.reason.AKMP_INVALID] = "AKMP_INVALID",
    [wifi.eventmon.reason.UNSUPP_RSN_IE_VERSION] = "UNSUPP_RSN_IE_VERSION",
    [wifi.eventmon.reason.INVALID_RSN_IE_CAP] = "INVALID_RSN_IE_CAP",
    [wifi.eventmon.reason["802_1X_AUTH_FAILED"]] = "802_1X_AUTH_FAILED",
    [wifi.eventmon.reason.CIPHER_SUITE_REJECTED] = "CIPHER_SUITE_REJECTED",
    [wifi.eventmon.reason.BEACON_TIMEOUT] = "BEACON_TIMEOUT",
    [wifi.eventmon.reason.NO_AP_FOUND] = "NO_AP_FOUND",
    [wifi.eventmon.reason.AUTH_FAIL] = "AUTH_FAIL",
    [wifi.eventmon.reason.ASSOC_FAIL] = "ASSOC_FAIL",
    [wifi.eventmon.reason.HANDSHAKE_TIMEOUT] = "HANDSHAKE_TIMEOUT"
  }
  return t[reason] or tostring(reason)
end

return main
