return {
    title = "Terracoin Node",
    base = "__btc/ami.lua",
    commands = {
        setup = {
			action = function(_options, _, _, _)
				local _noOptions = #table.keys(_options) == 0
				if _noOptions or _options.environment then
					am.app.prepare()
				end

				if _noOptions or not _options["no-validate"] then
					am.execute("validate", { "--platform" })
				end

				if _noOptions or _options.app then
					am.execute_extension("__btc/download-binaries.lua", { contextFailExitCode = EXIT_SETUP_ERROR })
				end

				if _noOptions and not _options["no-validate"] then
					am.execute("validate", { "--configuration" })
				end

				if _noOptions or _options.configure then
					am.app.render()

					am.execute_extension("__btc/configure.lua", { contextFailExitCode = EXIT_APP_CONFIGURE_ERROR })
					am.execute_extension("__trc/configure.lua", { contextFailExitCode = EXIT_APP_CONFIGURE_ERROR })
				end
				log_success("trc node setup complete.")
			end
		},
        start = {
            action = '__trc/start.lua',
        },
        stop = {
            action = '__trc/stop.lua',
        },
        info = {
            action = "__trc/info.lua"
        },
        bootstrap = {
            description = "ami 'bootstrap' sub command",
            summary = "Bootstraps the Terracoin node",
            action = "__trc/bootstrap.lua",
            contextFailExitCode = EXIT_APP_INTERNAL_ERROR
        },
        remove = {
            action = function(_options, _, _, _)
                if _options.all then
                    am.execute_extension('__btc/remove-all.lua', {contextFailExitCode = EXIT_RM_ERROR})
                    am.execute_extension('__trc/remove-all.lua', {contextFailExitCode = EXIT_RM_ERROR})
                    am.app.remove()
                    log_success('Application removed.')
                else
                    am.app.remove_data()
                    log_success('Application data removed.')
                end
            end
        }
    }
}
