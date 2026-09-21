# dotfiles

Two machines, two stacks. They used to share WezTerm + Neovim. They don't anymore:

- **Mac (personal):** Ghostty (shaders) + tmux + Neovim — this is the setup I'm learning on.
- **Windows (work):** WezTerm + PowerShell. Editor there is VS Code, not this Neovim config.

```
mac/   nvim, ghostty, tmux, fastfetch
win/   wezterm, powershell, fastfetch
docs/  Neovim keymap/plugin reference (Mac nvim)
```

## Mac

| Folder | Configures | Symlink to |
|---|---|---|
| [`mac/nvim/`](mac/nvim/) | Neovim | `~/.config/nvim` |
| [`mac/ghostty/`](mac/ghostty/) | Ghostty + GLSL shaders | `~/.config/ghostty` |
| [`mac/tmux/`](mac/tmux/) | tmux (TPM plugins stay untracked) | `~/.config/tmux` |
| [`mac/fastfetch/`](mac/fastfetch/) | fastfetch | `~/.config/fastfetch` |

zsh (oh-my-zsh + powerlevel10k) is still configured outside this repo.

```sh
brew install neovim ghostty tmux fastfetch eza zoxide fzf fd chafa

git clone https://github.com/Shubham-yelekar/neovim-config.git ~/dotfiles
cd ~/dotfiles

# back up anything already at these paths first
ln -sfn "$PWD/mac/nvim"     ~/.config/nvim
ln -sfn "$PWD/mac/ghostty"  ~/.config/ghostty
ln -sfn "$PWD/mac/tmux"     ~/.config/tmux
ln -sfn "$PWD/mac/fastfetch" ~/.config/fastfetch

# TPM — once, then Prefix+I inside tmux
git clone --depth=1 --single-branch --no-tags \
  https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

Need a Nerd Font. Ghostty is set to `Maple Mono NF`; install that (or change `mac/ghostty/modules/appearance.config`).

Ghostty launches `mac/ghostty/scripts/launch.sh`, which starts a login shell in `~/Developer` and lets tmux own tabs/panes. Bloom + modified-retro shaders are on; others are commented in `mac/ghostty/modules/shaders.config`.

📖 **Neovim reference:** [`docs/index.html`](docs/index.html)

## Windows

Work machine: VS Code for editing. This folder is the old WezTerm + PowerShell environment.

| Folder | Configures | Symlink to |
|---|---|---|
| [`win/wezterm/`](win/wezterm/) | WezTerm | `~\.config\wezterm\` |
| [`win/powershell/`](win/powershell/) | PowerShell profile | `~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |
| [`win/fastfetch/`](win/fastfetch/) | fastfetch | `~\.config\fastfetch\` |

```powershell
winget install wez.wezterm Fastfetch-cli.Fastfetch `
               eza-community.eza ajeetdsouza.zoxide junegunn.fzf `
               sharkdp.fd JanDeDobbeleer.OhMyPosh

git clone https://github.com/Shubham-yelekar/neovim-config.git E:\dotfiles
cd E:\dotfiles
# elevated shell, or Developer Mode
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.config\wezterm"  -Target "$PWD\win\wezterm"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.config\fastfetch" -Target "$PWD\win\fastfetch"
New-Item -ItemType SymbolicLink `
  -Path   "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" `
  -Target "$PWD\win\powershell\Microsoft.PowerShell_profile.ps1"
```

WezTerm loads the bundled JetBrainsMono Nerd Font from `win/wezterm/font/` and starts PowerShell so the profile (oh-my-posh, zoxide, eza, fzf pickers) actually runs.

## Notes

- **Do not share one WezTerm config across both machines anymore.** Mac is Ghostty; Windows is WezTerm.
- **Blur is Windows-only in `win/wezterm`.** `win32_system_backdrop = "Acrylic"` needs `window_background_opacity` low enough for the backdrop to show. `macos_window_background_blur` in that file is leftover and unused on Windows.
- **fastfetch's chafa logo** is flaky on the winget build; same config draws the image on macOS.
- `mac/nvim/lazy-lock.json` pins Neovim plugins. Commit it after `:Lazy update`.
- tmux plugins live in `~/.config/tmux/plugins/` and are gitignored. Reinstall with TPM on a new Mac.
