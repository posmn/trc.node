local SENTINEL_URL = "https://github.com/terracoin/sentinel/archive/refs/heads/master.zip"
local SENTINEL_DIRECTORY = "bin/sentinel"

log_info("Installing " .. am.app.get("id") .. " sentinel...")

local _ok, _apt = am.plugin.safe_get("apt")
if not _ok then
        log_warn("Failed to load apt plugin!")
end
local _ok, _code, _, _error, _dep = _apt.install("python2.7 virtualenv python2-pip-whl python2-setuptools-whl")
if not _ok then
    log_warn("Failed to install " .. (_dep or '-').. "! - " .. _error)
end

local _tmpFile = os.tmpname()
local _ok, _error = net.safe_download_file(SENTINEL_URL, _tmpFile, {followRedirects = true})
if not _ok then
    os.remove(_tmpFile)
    ami_error("Failed to download sentinel - " .. _error .. "!")
end

fs.mkdirp(SENTINEL_DIRECTORY)
local _ok, _error = zip.safe_extract(_tmpFile, SENTINEL_DIRECTORY, { flattenRootDir = true })
os.remove(_tmpFile)
ami_assert(_ok, "Failed to extract sentinel - " .. (_error or "") .. "!")

os.chdir(SENTINEL_DIRECTORY)
local cmd = "virtualenv -p /usr/bin/python2.7 ./venv && ./venv/bin/pip install -r requirements.txt"
local ok = os.execute(cmd)

if not ok then
    ami_error("Failed to set up virtual environment and install requirements.")
end

-- patch sentinel lib/terracoin_config.py to collect host from rpcbind
local numReplacements = 0
local sentinelTerracoinConfigPy = fs.read_file("lib/terracoin_config.py")
if not sentinelTerracoinConfigPy:find("# POSMN injected") then
    sentinelTerracoinConfigPy, numReplacements = sentinelTerracoinConfigPy:gsub(
        "rpc%(user|password|port%)=%(.-%)%$",
        "rpc(user|password|port|bind)=(.*?)$"
    )

    ami_assert(numReplacements == 1, "Failed to patch sentinel lib/terracoin_config.py!")
    local function injectCodeWithIndent(matchedIndent)
        local injectCode = matchedIndent .. "if 'bind' in creds:" ..
                        matchedIndent .. "    creds['host'] = creds.pop('bind') # POSMN injected \n"
        return injectCode
    end
    sentinelTerracoinConfigPy, numReplacements = sentinelTerracoinConfigPy:gsub(
        "(%s-)(creds%[u'port'%] = int%(creds%[u'port'%]%))",
        function(indent, line)
            return indent .. line .. injectCodeWithIndent(indent)
        end
    )
    ami_assert(numReplacements == 1, "Failed to patch sentinel lib/terracoin_config.py!")
    ami_assert(sentinelTerracoinConfigPy:find("# POSMN injected"), "Failed to patch sentinel lib/terracoin_config.py!")
    ami_assert(sentinelTerracoinConfigPy:find("rpc%(user|password|port|bind%)"), "Failed to patch sentinel lib/terracoin_config.py!")

    fs.write_file("lib/terracoin_config.py", sentinelTerracoinConfigPy)
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