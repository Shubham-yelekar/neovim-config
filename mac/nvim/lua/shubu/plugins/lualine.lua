return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status") -- to configure lazy pending updates count

    local colors = {
      blue = "#65D1FF",
      green = "#3EFFDC",
      violet = "#FF61EF",
      yellow = "#FFDA7B",
      red = "#FF4A4A",
      fg = "#c3ccdc",
      bg = "#112638",
      inactive_bg = "#2c3043",
    }

    local my_lualine_theme = {
      normal = {
        a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      insert = {
        a = { bg = colors.green, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      visual = {
        a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      command = {
        a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      replace = {
        a = { bg = colors.red, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      inactive = {
        a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
        b = { bg = colors.inactive_bg, fg = colors.semilightgray },
        c = { bg = colors.inactive_bg, fg = colors.semilightgray },
      },
    }

    -- Short mode labels, so the mode block stays one or two characters wide instead of
    -- eating the left end of the statusline. The keys are lualine's own mode names (see
    -- lualine/utils/mode.lua) -- the visual/select/replace families keep a second letter
    -- so you can still tell charwise from linewise from blockwise at a glance.
    local mode_label = {
      ["NORMAL"] = "N",
      ["O-PENDING"] = "O",
      ["VISUAL"] = "V",
      ["V-LINE"] = "VL",
      ["V-BLOCK"] = "VB",
      ["SELECT"] = "S",
      ["S-LINE"] = "SL",
      ["S-BLOCK"] = "SB",
      ["INSERT"] = "I",
      ["REPLACE"] = "R",
      ["V-REPLACE"] = "VR",
      ["COMMAND"] = "C",
      ["EX"] = "EX",
      ["MORE"] = "M",
      ["CONFIRM"] = "?",
      ["SHELL"] = "!",
      ["TERMINAL"] = "TERM",
    }

    -- configure lualine with modified theme
    lualine.setup({
      options = {
        theme = my_lualine_theme,
      },
      sections = {
        lualine_a = {
          {
            "mode",
            -- Fall back to the full name for anything unmapped, so a mode lualine doesn't
            -- recognise shows its raw code rather than vanishing.
            fmt = function(str)
              return mode_label[str] or str
            end,
          },
        },
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = "#ff9e64" },
          },
          { "encoding" },
          { "fileformat" },
          { "filetype" },
        },
      },
    })
  end,
}
