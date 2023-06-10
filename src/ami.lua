return {
    title = "Terracoin Node",
    base = "__btc/ami.lua",
    commands = {
        info = {
            action = "__trc/info.lua"
        },
        bootstrap = {
            description = "ami 'bootstrap' sub command",
            summary = "Bootstraps the Terracoin node",
            action = "__trc/bootstrap.lua",
            contextFailExitCode = EXIT_APP_INTERNAL_ERROR
        }
    }
}
