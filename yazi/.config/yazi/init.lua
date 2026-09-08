require("full-border"):setup {
	type = ui.Border.ROUNDED,
}

require("git"):setup {
	order = 1500,
}

require("mactag"):setup {
	keys = {
		r = "Red",
		o = "Orange",
		y = "Yellow",
		g = "Green",
		b = "Blue",
		p = "Purple",
	},
	colors = {
		Red = "#f38ba8",
		Orange = "#fab387",
		Yellow = "#f9e2af",
		Green = "#a6e3a1",
		Blue = "#89b4fa",
		Purple = "#cba6f7",
	},
	order = 500,
}

-- searchjump: fuzzy jump with Chinese pinyin initial matching through sjch.
require("searchjump"):setup {
	mapdata = require("sjch").data,
}

-- augment-command: selectively enhance Yazi's default commands.
local home = os.getenv("HOME") or ""
require("augment-command"):setup {
	prompt = false,
	smart_enter = true,
	smart_paste = true,
	smart_tab_create = true,
	smart_tab_switch = true,
	confirm_on_quit = true,
	open_file_after_creation = false,
	enter_directory_after_creation = true,
	enter_archives = true,
	recursively_extract_archives = true,
	preserve_file_permissions = false,
	smooth_scrolling = false,
	wraparound_file_navigation = true,
	protected_directories = {
		home,
		home .. "/Desktop",
		home .. "/Documents",
		home .. "/Downloads",
		home .. "/Workspace",
	},
}
