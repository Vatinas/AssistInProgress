return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`AssistInProgress` encountered an error loading the Darktide Mod Framework.")

		new_mod("AssistInProgress", {
			mod_script       = "AssistInProgress/scripts/mods/AssistInProgress/AssistInProgress",
			mod_data         = "AssistInProgress/scripts/mods/AssistInProgress/AssistInProgress_data",
			mod_localization = "AssistInProgress/scripts/mods/AssistInProgress/AssistInProgress_localization",
		})
	end,
	packages = {},
}
