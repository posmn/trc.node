local SENTINEL_URL = "https://github.com/terracoin/sentinel/archive/refs/heads/master.zip"

log_info("Installing " .. am.app.get("id") .. " sentinel...")

local _ok, _code, _, _error, _dep = _apt.install("python python-virtualenv")
if not _ok then 
    log_warn("Failed to install " .. (_dep or '-').. "! - " .. _error)
end

local _tmpFile = os.tmpname()
local _ok, _error = net.safe_download_file(SENTINEL_URL, _tmpFile)
if not _ok then
    os.remove(_tmpFile)
    ami_error("Failed to download sentinel - " .. _error .. "!")
end

local _ok, _error = zip.safe_extract(_tmpFile, "bin/sentinel", { flattenRootDir = true })
os.remove(_tmpFile)
ami_assert(_ok, "Failed to extract sentinel - " .. (_error or "") .. "!")

os.chdir("bin/sentinel")
local cmd = "virtualenv ./venv && ./venv/bin/pip install -r requirements.txt"
local ok = os.execute(cmd)

if not ok then
    ami_error("Failed to set up virtual environment and install requirements.")
end
os.chdir("../..")

log_info("Configuring " .. am.app.get("id") .. " sentinel...")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin - " .. tostring(_systemctl))
local _ok, _error = _systemctl.safe_install_service("__trc/assets/sentinel.service", am.app.get("id") .. "-sentinel")
ami_assert(_ok, "Failed to install " .. am.app.get("id") .. "-sentinel.service " .. (_error or ""))

ami_assert(_ok, "Failed to load systemctl plugin - " .. tostring(_systemctl))
local _ok, _error = _systemctl.safe_install_service("__trc/assets/sentinel.timer", am.app.get("id") .. "-sentinel", { kind = "timer" })
ami_assert(_ok, "Failed to install " .. am.app.get("id") .. "-sentinel.timer " .. (_error or ""))

log_success(am.app.get("id") .. " sentinel configured")