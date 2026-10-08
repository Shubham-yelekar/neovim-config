return {
  "stevearc/dressing.nvim",
  event = "VeryLazy",
  opts = {
    input = {
      -- dressing never sets a zindex on the vim.ui.input window, so it lands
      -- on nvim's default of 50 -- which is BEHIND floaterm's windows (they
      -- all use 100). That made the rename/add prompt (`e` and `a` in the
      -- floaterm sidebar) render under the terminal: you were typing into a
      -- window you could not see.
      --
      -- dressing's own vim.ui.select already sits at 150, which is why only
      -- input was affected. 200 clears both.
      override = function(conf)
        conf.zindex = 200
        return conf
      end,
    },
  },
}
