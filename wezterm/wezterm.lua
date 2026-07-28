-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- This is where you actually apply your config choices

config.font = wezterm.font("JetBrains Mono")
config.font_size = 14

-- Match Neovim's catppuccin, since nvim runs with transparent_background
config.color_scheme = "Catppuccin Mocha"

config.enable_tab_bar = false

config.window_decorations = "RESIZE"

config.window_background_opacity = 0.8
config.macos_window_background_blur = 10

if is_windows then
  -- Without this WezTerm falls back to cmd.exe. PowerShell is the shell that
  -- reads Microsoft.PowerShell_profile.ps1, which is where the zsh-parity setup
  -- lives (oh-my-posh, fastfetch, zoxide, eza, the fzf pickers). Git Bash would
  -- ignore all of it and give you a bare MINGW64 prompt.
  config.default_prog = { "powershell.exe", "-NoLogo" }

  -- macos_window_background_blur does nothing here - it is macOS-only, which is
  -- why the window was see-through but not blurred. Windows 11's equivalent is
  -- an acrylic system backdrop. It only shows through when the window itself is
  -- fully transparent, so opacity drops to 0 and acrylic supplies the tint.
  config.window_background_opacity = 0
  config.win32_system_backdrop = "Mica"
end

-- Open fullscreen. This fires once, for the window WezTerm creates at startup.
-- Swap toggle_fullscreen() for maximize() if you'd rather keep the taskbar and
-- normal alt-tab behaviour; F11 toggles either way.
wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

-- and finally, return the configuration to wezterm
return config
