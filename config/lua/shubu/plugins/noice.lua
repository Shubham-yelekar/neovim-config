-- Centered floating cmdline. Note this is NOT what dressing.nvim does -
-- dressing owns vim.ui.input / vim.ui.select (the LSP rename box, code action
-- lists). The `:` cmdline is a separate UI layer that only noice replaces.
--
-- Scoped deliberately narrow: cmdline and popupmenu only. noice can also take
-- over messages, notifications and LSP progress, but that changes how every
-- error and :message behaves, so those stay on Neovim's defaults.
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    cmdline = {
      enabled = true,
      view = "cmdline_popup",
    },
    -- Everything below is off on purpose - see the note above.
    messages = { enabled = false },
    notify = { enabled = false },
    lsp = {
      progress = { enabled = false },
      hover = { enabled = false },
      signature = { enabled = false },
    },
    presets = {
      -- Puts the cmdline and the completion menu together as one centered
      -- block near the top - the "command palette" look.
      command_palette = true,
      -- Keep / and ? at the bottom where the matches are visible.
      bottom_search = true,
      long_message_to_split = true,
    },
  },
}