local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _ok, _error = _systemctl.safe_remove_service(am.app.get("id") .. "-sentinel")
if not _ok then
    ami_error("Failed to remove " .. am.app.get("id") .. "-sentinel.service " .. (_error or ""))
end

local _ok, _error = _systemctl.safe_remove_service(am.app.get("id") .. "-sentinel", { kind = "timer" })
if not _ok then
    ami_error("Failed to remove " .. am.app.get("id") .. "-sentinel.timer " .. (_error or ""))
end

log_success("Node services succesfully removed.")