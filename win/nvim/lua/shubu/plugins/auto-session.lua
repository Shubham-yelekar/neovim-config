return {
	"rmagatti/auto-session",
	config = function()
		local auto_session = require("auto-session")

		auto_session.setup({
			auto_restore_enabled = false,
			-- ~ is C:\Users\<you> here; E:\shubham-git and E:\main-repos are the repo roots the
			-- PowerShell profile's rv/sv pickers scan, so sessions there are wanted.
			auto_session_suppress_dirs = { "~/", "~/Downloads", "~/Documents", "~/Desktop/", "E:/" },
		})

		local keymap = vim.keymap

		keymap.set("n", "<leader>wr", "<cmd>AutoSession restore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
		keymap.set("n", "<leader>ws", "<cmd>AutoSession save<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory
	end,
}
