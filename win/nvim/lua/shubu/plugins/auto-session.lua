return {
	"rmagatti/auto-session",
	config = function()
		local auto_session = require("auto-session")

		auto_session.setup({
			-- Sessions are restored on demand (<leader>wr or <leader>wf), never on startup,
			-- so nvim always opens on the alpha dashboard.
			auto_restore = false,

			-- ~ is C:\Users\<you> here; E:\shubham-git and E:\main-repos are the repo roots the
			-- PowerShell profile's rv/sv pickers scan, so sessions there are wanted.
			suppressed_dirs = { "~/", "~/Downloads", "~/Documents", "~/Desktop/", "E:/" },

			-- Critical with alpha-nvim: after restoring a session and closing the buffers you
			-- land back on the dashboard. Quitting there auto-saves an alpha-only session over
			-- the good one, and auto_delete_empty_sessions then deletes it outright. Bypassing
			-- the save when the dashboard is the only buffer left keeps the session intact.
			bypass_save_filetypes = { "alpha" },

			session_lens = {
				picker = "telescope",
				previewer = "summary",
				shorten_paths = true,
			},
		})

		local keymap = vim.keymap

		keymap.set("n", "<leader>wf", "<cmd>AutoSession search<CR>", { desc = "Find session (list all)" }) -- picker over every saved session, <C-d> deletes
		keymap.set("n", "<leader>wr", "<cmd>AutoSession restore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
		keymap.set("n", "<leader>ws", "<cmd>AutoSession save<CR>", { desc = "Save session for cwd" }) -- save workspace session for current working directory
		keymap.set("n", "<leader>wd", "<cmd>AutoSession deletePicker<CR>", { desc = "Delete a session" })
		keymap.set("n", "<leader>wt", "<cmd>AutoSession toggle<CR>", { desc = "Toggle session auto-save" })
	end,
}
