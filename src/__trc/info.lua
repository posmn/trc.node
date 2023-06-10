local _json = am.options.OUTPUT_FORMAT == 'json'

local _ok, _systemctl = am.plugin.safe_get('systemctl')
ami_assert(_ok, 'Failed to load systemctl plugin', EXIT_APP_START_ERROR)

local _appId = am.app.get('id', 'unknown')
local _serviceName = am.app.get_model('SERVICE_NAME', 'unknown')
local _ok, _status, _started = _systemctl.safe_get_service_status(_appId .. '-' .. _serviceName)
ami_assert(
    _ok,
    'Failed to start ' .. _appId .. '-' .. _serviceName .. '.service ' .. (_status or ''),
    EXIT_PLUGIN_EXEC_ERROR
)

local _info = {
    terracoind = _status,
    started = _started,
    level = 'ok',
    synced = false,
    status = 'Terracoin node down',
    version = am.app.get_version(),
    type = am.app.get_type(),
    currentBlock = 'unknown',
    currentBlockHash = 'unknown'
}

local function _exec_terracoin_cli(...)
    local _arg = {'-datadir=data', ...}
    local _rpcBind = am.app.get_configuration({'DAEMON_CONFIGURATION', 'rpcbind'})
    if type(_rpcBind) == 'string' then
        table.insert(_arg, 1, '-rpcconnect=' .. _rpcBind)
    end
    local _proc = proc.spawn('bin/bin/terracoin-cli', _arg, {stdio = {stdout = 'pipe', stderr = 'pipe'}, wait = true})

    local _exitcode = _proc.exitcode
    local _stdout = _proc.stdoutStream:read('a') or ''
    local _stderr = _proc.stderrStream:read('a') or ''
    return _exitcode, _stdout, _stderr
end

local function _get_terracoin_cli_result(exitcode, stdout, stderr)
    if exitcode ~= 0 then
        local _errorInfo = stderr:match('error: (.*)')
        local _ok, _output = hjson.safe_parse(_errorInfo)
        if _ok then
            return false, _output
        else
            return false, {message = 'unknown (internal error)'}
        end
    end

    local _ok, _output = hjson.safe_parse(stdout)
    if _ok then
        return true, _output
    else
        return false, {message = 'unknown (internal error)'}
    end
end

if _info.terracoind == 'running' then
    if am.app.get_configuration("NODE_PRIVKEY") then
        local _exitcode, _stdout, _stderr = _exec_terracoin_cli("-datadir=data", "masternode", "status")
        local _success, _output = _get_terracoin_cli_result(_exitcode, _stdout, _stderr)

        _info.status = _output.message
        if not _success or (_info.status ~= 'Masternode successfully started') then
            _info.level = "error"
        end
    end

    local _exitcode, _stdout, _stderr = _exec_terracoin_cli('-datadir=data', 'getblockchaininfo')
    local _success, _output = _get_terracoin_cli_result(_exitcode, _stdout, _stderr)

    if _success then
        _info.currentBlock = _output.blocks
        _info.currentBlockHash = _output.bestblockhash
    end

    local _exitcode, _stdout, _stderr = _exec_terracoin_cli('-datadir=data', 'mnsync', 'status')
    local _success, _output = _get_terracoin_cli_result(_exitcode, _stdout, _stderr)

    if _success then
        _info.synced = _output.IsBlockchainSynced
    end

    if not _nodeType then
        if not _success then
            _info.status = 'Unknown sync status!'
            _info.level = 'error'
        else
            _info.status = 'Synced.'
        end
    end
else
    _info.level = 'error'
end

if _json then
    print(hjson.stringify_to_json(_info, {indent = false}))
else
    print(hjson.stringify(_info))
end
