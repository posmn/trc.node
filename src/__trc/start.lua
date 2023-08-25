local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _ok, _error = _systemctl.safe_start_service(am.app.get("id") .. "-" .. am.app.get_model("SERVICE_NAME"))
ami_assert(_ok, "Failed to start " .. am.app.get("id") .. "-" .. am.app.get_model("SERVICE_NAME") .. ".service " .. (_error or ""))

local _ok, _error = _systemctl.safe_start_service(am.app.get("id") .. "-sentinel")
ami_assert(_ok, "Failed to start " .. am.app.get("id") .. "-sentinel.service " .. (_error or ""))

log_success("Node services succesfully started.")