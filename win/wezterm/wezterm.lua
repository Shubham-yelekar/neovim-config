
-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- This is where you actually apply your config choices

-- Load the bundled TTF from ~/.config/wezterm/font instead of relying on a
-- system install. Relative paths resolve against the config file's directory,
-- and font_dirs is searched before system fonts.
config.font_dirs = { "font" }
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
-- Windows Terminal defaults to 12pt Cascadia Mono. JetBrains Mono has a taller
-- x-height and renders larger at the same point size, so 11 is the closer match.
config.font_size = 11

-- Match Neovim's catppuccin, since nvim runs with transparent_background
config.color_scheme = "Catppuccin Mocha"

config.enable_tab_bar = true

-- Windows Terminal look: tabs, the + button and the min/max/close buttons all
-- share one row where the title bar would normally be.
--   fancy tab bar   = the graphical one with rounded tabs, not the text-mode one
--   INTEGRATED_BUTTONS = pull the window controls into that row
config.use_fancy_tab_bar = true
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_button_style = "Windows"
config.integrated_title_buttons = { "Hide", "Maximize", "Close" }
config.show_new_tab_button_in_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- The tab bar is chrome, not terminal output, so it wants the system UI font
-- rather than JetBrains Mono - that is a lot of what makes it read as native.
config.window_frame = {
  font = wezterm.font({ family = "Segoe UI", weight = "Regular" }),
  font_size = 12,
  active_titlebar_bg = "#1f1f1f",
  inactive_titlebar_bg = "#1f1f1f",
}

-- Windows Terminal's dark greys: the active tab lifts slightly off the bar,
-- inactive text drops to mid-grey.
config.colors = {
  tab_bar = {
    inactive_tab_edge = "#1f1f1f",
    active_tab = { bg_color = "#2d2d2d", fg_color = "#ffffff" },
    inactive_tab = { bg_color = "#1f1f1f", fg_color = "#a0a0a0" },
    inactive_tab_hover = { bg_color = "#2a2a2a", fg_color = "#ffffff" },
    new_tab = { bg_color = "#1f1f1f", fg_color = "#a0a0a0" },
    new_tab_hover = { bg_color = "#2a2a2a", fg_color = "#ffffff" },
  },
}

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
  -- a system backdrop. It only shows through when the window itself is fully
  -- transparent, so opacity drops to 0 and the backdrop supplies the tint.
  --
  -- Acrylic, not Mica: Mica samples the wallpaper once and stays near-opaque,
  -- which is why it read as flat grey. Acrylic is the live blur Windows
  -- Terminal uses, so the desktop actually shows through.
  config.window_background_opacity = 0.5
  config.win32_system_backdrop = "Acrylic"
end

-- Start maximized rather than fullscreen. This matters for the backdrop above:
-- acrylic and mica blur whatever sits behind the window, and a fullscreen window
-- has nothing behind it, so DWM stops drawing the effect and you get flat grey.
-- Maximized keeps the taskbar and the blur. F11 still toggles fullscreen.
wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- and finally, return the configuration to wezterm
return config
