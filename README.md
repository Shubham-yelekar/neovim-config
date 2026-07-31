# dotfiles

Neovim, WezTerm, fastfetch and shell config — shared between a MacBook (M4, zsh)
and a Windows 11 machine (PowerShell). One repo, both machines.

📖 **Neovim reference:** [`docs/index.html`](docs/index.html) — a searchable page
documenting every plugin, keymap and option. Open it in a browser, or serve it
with GitHub Pages from the `docs/` folder.

## What's in here

| Folder | Configures | macOS path | Windows path |
|---|---|---|---|
| [`config/`](config/) | Neovim | `~/.config/nvim` | `~\AppData\Local\nvim` |
| [`wezterm/`](wezterm/) | WezTerm terminal | `~/.config/wezterm/` | `~\.config\wezterm\` |
| [`fastfetch/`](fastfetch/) | fastfetch system info | `~/.config/fastfetch/` | `~\.config\fastfetch\` |
| [`powershell/`](powershell/) | Shell — **Windows only** | — | `~\Documents\WindowsPowerShell\` |

Neovim, WezTerm and fastfetch are shared by both machines. The shell is not: the
Mac runs zsh (oh-my-zsh + powerlevel10k, configured outside this repo) and
Windows runs PowerShell. The profile in `powershell/` is a deliberate port of
that zsh setup — the table under [Shell parity](#shell-parity) records which
piece maps to which, so the two stay in step.

## Install

### macOS

```sh
brew install neovim wezterm fastfetch eza zoxide fzf fd chafa

git clone https://github.com/Shubham-yelekar/neovim-config.git ~/dotfiles
cd ~/dotfiles
ln -s "$PWD/config"    ~/.config/nvim
ln -s "$PWD/wezterm"   ~/.config/wezterm
ln -s "$PWD/fastfetch" ~/.config/fastfetch
```

The zsh side (oh-my-zsh, powerlevel10k, zsh-autosuggestions,
zsh-syntax-highlighting) isn't tracked here — set it up separately and use
[Shell parity](#shell-parity) to keep it aligned with the PowerShell profile.

### Windows

```powershell
winget install Neovim.Neovim wez.wezterm Fastfetch-cli.Fastfetch `
               eza-community.eza ajeetdsouza.zoxide junegunn.fzf `
               sharkdp.fd JanDeDobbeleer.OhMyPosh

git clone https://github.com/Shubham-yelekar/neovim-config.git E:\dotfiles
cd E:\dotfiles
# needs an elevated shell, or Developer Mode enabled
New-Item -ItemType SymbolicLink -Path "$env:LOCALAPPDATA\nvim"            -Target "$PWD\config"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.config\wezterm"  -Target "$PWD\wezterm"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.config\fastfetch" -Target "$PWD\fastfetch"
New-Item -ItemType SymbolicLink `
  -Path   "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" `
  -Target "$PWD\powershell\Microsoft.PowerShell_profile.ps1"
```

Both platforms need a **Nerd Font** — powerlevel10k, fastfetch, lualine and
nvim-tree all draw glyphs that plain fonts don't have.

WezTerm doesn't need one installed: `wezterm/font/` ships the TTF and
`config.font_dirs = { "font" }` loads it from beside the config, so the terminal
renders glyphs correctly on a fresh machine with nothing set up. That only covers
WezTerm's own window — install `JetBrainsMono Nerd Font` system-wide anyway if
you want other terminals or editors to show the same glyphs.

## Shell parity

The Mac's `.zshrc` and `powershell/Microsoft.PowerShell_profile.ps1` aim at the
same experience through different machinery:

| Behaviour | macOS (zsh) | Windows (PowerShell) |
|---|---|---|
| Prompt | oh-my-zsh + powerlevel10k (rainbow) | oh-my-posh, `powerlevel10k_rainbow` theme |
| Autosuggestions | `zsh-autosuggestions` | PSReadLine `-PredictionSource History` |
| Syntax highlighting | `zsh-syntax-highlighting` | PSReadLine `-Colors` (catppuccin mocha) |
| Better `ls` | `alias ls="eza --icons=always"` | `ls`/`ll`/`la`/`lt` functions wrapping eza |
| Better `cd` | `alias cd="z"` (zoxide) | `zoxide init powershell --cmd cd` |
| History search on ↑/↓ | `bindkey '^[[A' history-search-backward` | `Set-PSReadLineKeyHandler UpArrow HistorySearchBackward` |
| No duplicate history | `setopt hist_ignore_dups` | `-HistoryNoDuplicates` |
| Node version manager | nvm | fnm *(not installed — commented out)* |

PowerShell aliases can't carry arguments, which is why the eza entries are
functions rather than `Set-Alias`.

Extra on Windows (no zsh equivalent — they grew out of this machine's workflow):

| | |
|---|---|
| `r` / `rv` | fuzzy-pick a git repo under the repo roots, `cd` there / and open nvim |
| `s` / `sv` | fuzzy-pick from zoxide history, `cd` there / and open nvim |
| `v` | open nvim at the current dir, or at a given path |
| `ff` | run fastfetch on demand |
| `Ctrl+g` | run the repo picker from any prompt |

## Notes

- **Terminal ≠ shell.** WezTerm and Windows Terminal are terminal emulators —
  they own the font, colors and transparency. PowerShell/zsh are the shells
  running inside them, and they're what read the profiles above. WezTerm is set
  to launch PowerShell on Windows precisely so the profile loads.
- **Blur is per-platform.** `macos_window_background_blur` is macOS-only, so on
  Windows it silently does nothing. The equivalent is `win32_system_backdrop`,
  currently `"Mica"` (the other useful value is `"Acrylic"` — Mica tints from the
  desktop wallpaper, Acrylic blurs whatever window is actually behind). Either
  needs `window_background_opacity = 0`: the backdrop is painted behind the
  window, so the window itself has to be transparent for it to show through.
- **Catppuccin's scheme name isn't the repo name.** It registers
  `catppuccin-mocha`/`-latte`/`-frappe`/`-macchiato`. `catppuccin-nvim` doesn't
  exist and raises `E185`.
- **fastfetch's chafa logo doesn't render on Windows.** The winget build accepts
  the config but falls back to the built-in logo; the same config draws the
  image fine on macOS.
- `config/lazy-lock.json` pins every Neovim plugin to a commit. Commit it after
  running `:Lazy update` so both machines stay on the same versions.
