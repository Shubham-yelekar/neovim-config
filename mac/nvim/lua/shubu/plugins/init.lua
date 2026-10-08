return {
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  {
    "christoomey/vim-tmux-navigator", -- tmux & split window navigation
    -- Its default maps include normal-mode <C-\> (jump to previous pane),
    -- which loads after floaterm's mapping and steals the toggle. Inside tmux
    -- it also grabs t-mode Ctrl+hjkl, which floaterm needs for its sidebar
    -- and for cycling terminals. So turn the defaults off, map the four
    -- directions in normal mode only, and move "previous" to <leader>\.
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window/pane left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Window/pane down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Window/pane up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window/pane right" },
      { "<leader>\\", "<cmd>TmuxNavigatePrevious<cr>", desc = "Previous window/pane" },
    },
  },
}
