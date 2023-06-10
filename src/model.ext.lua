am.app.set_model(
    {
        DAEMON_CONFIGURATION = {
            server = (type(am.app.get_configuration("NODE_PRIVKEY") == "string") or am.app.get_configuration("SERVER")) and 1 or nil,
            listen = (type(am.app.get_configuration("NODE_PRIVKEY") == "string") or am.app.get_configuration("SERVER")) and 1 or nil,
            masternodeprivkey = am.app.get_configuration("NODE_PRIVKEY"),
            masternode = am.app.get_configuration("NODE_PRIVKEY") and 1 or nil
        },
        DAEMON_URL = "https://terracoin.io/bin/terracoin-core-0.12.2.5/terracoin-0.12.2-x86_64-linux-gnu.tar.gz",
        DAEMON_ARCHIVE_KIND = "tar.gz",
        DAEMON_NAME = "bin/terracoind",
        CLI_NAME = "bin/terracoin-cli",
        CONF_NAME = "terracoin.conf",
        CONF_SOURCE = "__btc/assets/daemon.conf",
        SERVICE_NAME = "terracoind",
    },
    { merge = true, overwrite = true }
)
