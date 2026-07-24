return {
  "windwp/nvim-ts-autotag",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    -- auto-close and auto-rename paired tags in JSX/TSX/HTML/Angular
    -- (Neovim equivalent of VS Code's editor.linkedEditing)
    require("nvim-ts-autotag").setup({
      opts = {
        enable_close = true, -- auto close tags
        enable_rename = true, -- auto rename pairs
        enable_close_on_slash = false, -- don't auto close on </
      },
    })
  end,
}
