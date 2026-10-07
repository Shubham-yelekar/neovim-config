-- floaterm paints its UI with NvChad/base46 highlight groups (exdarkbg,
-- exblack2bg, exdarkborder, exred, ...). volt generates them in
-- volt/highlights.lua, and without NvChad's base46 cache it derives the whole
-- palette from Normal's background:
--
--   local normal_bg = api.nvim_get_hl(0, { name = "Normal" }).bg
--   normal_bg = hexadecimal_to_hex(normal_bg)   -- nil becomes "#000000"
--   local darker_bg = lighten(normal_bg, -3)
--
-- Our colorscheme runs transparent_background, so Normal HAS no bg, that nil
-- turns into #000000, and every panel collapses to pure black instead of the
-- solid two-tone panels in the upstream screenshots.
--
-- So map the groups onto the catppuccin palette by hand: sidebar on the
-- darker crust, terminal and top bar on mantle.
local function set_floaterm_hl()
  local ok, palettes = pcall(require, "catppuccin.palettes")
  if not ok then
    return
  end

  local p = palettes.get_palette("mocha")

  local groups = {
    exblack2bg = { bg = p.crust }, -- sidebar panel
    exblack2border = { fg = p.crust, bg = p.crust },
    exdarkbg = { bg = p.mantle }, -- terminal + top bar panel
    xdarkbg = { bg = p.mantle }, -- floaterm typos this one in ui.lua
    exdarkborder = { fg = p.mantle, bg = p.mantle },
    exred = { fg = p.red }, -- the accent rule under the bar
    exgreen = { fg = p.green }, -- active terminal, size readout
    exblue = { fg = p.blue },
  }

  for name, val in pairs(groups) do
    vim.api.nvim_set_hl(0, name, val)
  end
end

return {
  "nvzone/floaterm",
  dependencies = "nvzone/volt",
  cmd = "FloatermToggle",
  -- Same chord toggleterm used, in normal and terminal mode, so the muscle
  -- memory carries over. Mapping terminal mode shadows the built-in
  -- <C-\><C-n> escape -- toggleterm did that too (terminal_mappings
  -- defaults on), so this is not a regression.
  keys = {
    {
      [[<C-\>]],
      "<cmd>FloatermToggle<cr>",
      mode = { "n", "t" },
      desc = "Toggle floating terminal",
    },
  },
  config = function(_, opts)
    -- Order matters. volt/highlights.lua is a side-effecting module: it sets
    -- its groups when it is first required, which otherwise happens during
    -- the first open -- i.e. AFTER this function, clobbering our colours.
    -- Pull it in now so it generates its blacks once, then paint over them.
    -- Lua caches the module, so it never runs again and ours stay put.
    pcall(require, "volt.highlights")
    set_floaterm_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("FloatermHl", { clear = true }),
      callback = set_floaterm_hl,
    })
    require("floaterm").setup(opts)
  end,
  opts = {
    -- false is what gives the flat panel look from the upstream screenshots:
    -- `true` swaps it for plain single-line borders.
    border = false,
    -- Percentages of the editor, not lines/columns. Bigger than the 60x70
    -- default because this is where test output and dev servers live.
    size = { h = 80, w = 85 },
    -- The sidebar switches between these: <C-h> from the terminal opens it,
    -- number keys jump straight to one, `a` adds another, `e` renames.
    -- <C-j>/<C-k> cycle without opening the sidebar at all.
    terminals = {
      { name = "Terminal" },
      { name = "Server" },
      { name = "Tests" },
    },
  },
}
