
oh-my-posh init pwsh --config 'powerlevel10k_rainbow'  | Invoke-Expression

# Tell WezTerm the current dir via OSC 7 so split panes / new tabs inherit it.
# (WezTerm ignores oh-my-posh's default OSC 9;9 that Windows Terminal used.)
# We wrap oh-my-posh's prompt so it looks identical, just with OSC 7 appended.
$global:__ompPrompt = (Get-Item Function:\prompt).ScriptBlock
function prompt {
    $p = (Get-Location).ProviderPath -replace '\\', '/' -replace ' ', '%20'
    $osc7 = "$([char]27)]7;file://$env:COMPUTERNAME/$p$([char]27)\"
    (& $global:__ompPrompt) + $osc7
}

try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

Clear-Host

# Fastfetch no longer runs on every shell start. `ff` runs it on demand, with
# the explicit -c so it always picks up YOUR config rather than a default.
function ff { fastfetch -c "$env:USERPROFILE/.config/fastfetch/config.jsonc" @args }

# --- zoxide: tracks dirs you visit by frecency (recent + frequent) ---
# `--cmd cd` makes zoxide take over `cd` entirely, matching `alias cd="z"`
# in zsh/.zshrc. Plain `cd <path>` still works; `cdi` is the interactive picker.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# ============================================================================
# zsh parity - mirrors zsh/.zshrc so Windows feels like the mac shell.
# ============================================================================

# --- zsh-autosuggestions equivalent -----------------------------------------
# PSReadLine predicts from history and shows it greyed-out inline, exactly like
# zsh-autosuggestions. Accept the suggestion with the Right arrow (or End).
# Throws when the host has no virtual-terminal support (e.g. output redirected,
# or a plain conhost window), so it's guarded to avoid a red error on startup.
try {
    Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
    Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction Stop
} catch {}

# --- history setup ----------------------------------------------------------
# zsh: setopt hist_ignore_dups / share_history, HISTSIZE=999, SAVEHIST=1000
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
Set-PSReadLineOption -MaximumHistoryCount 4000

# zsh: bindkey '^[[A' history-search-backward / '^[[B' history-search-forward
# Type a prefix, then Up/Down cycles only through history entries starting with it.
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# --- zsh-syntax-highlighting equivalent -------------------------------------
# PSReadLine colours the command line as you type; these are catppuccin mocha
# values so the shell matches nvim and wezterm.
Set-PSReadLineOption -Colors @{
    Command          = '#89b4fa'  # blue
    Parameter        = '#94e2d5'  # teal
    String           = '#a6e3a1'  # green
    Operator         = '#f5c2e7'  # pink
    Variable         = '#cdd6f4'  # text
    Number           = '#fab387'  # peach
    Type             = '#f9e2af'  # yellow
    Comment          = '#6c7086'  # overlay0
    Error            = '#f38ba8'  # red
    InlinePrediction = '#585b70'  # surface2 - the greyed-out suggestion
}

# --- eza (better ls) --------------------------------------------------------
# zsh: alias ls="eza --icons=always". PowerShell aliases can't carry arguments,
# so these are functions; `ls` must be unaliased from Get-ChildItem first.
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --icons=always @args }
    function ll { eza --icons=always --long --git @args }
    function la { eza --icons=always --long --git --all @args }
    function lt { eza --icons=always --tree --level=2 @args }
}

# --- node version manager ---------------------------------------------------
# zsh uses nvm. The Windows equivalent is fnm (`winget install Schniz.fnm`);
# uncomment once installed.
# if (Get-Command fnm -ErrorAction SilentlyContinue) {
#     fnm env --use-on-cd | Out-String | Invoke-Expression
# }

# ============================================================================

# Our function names collide with built-in aliases (r=Invoke-History,
# rv=Remove-Variable, sv=Set-Variable). Remove them so OUR functions win.
Remove-Item Alias:r, Alias:rv, Alias:sv -Force -ErrorAction SilentlyContinue

# Repo/dir picker over your visited-directory history.
#   s            -> fuzzy-pick from history, cd into it
#   s <words>    -> pre-filter the picker by those words
# (built-in `zi` does the same; `s` is just a shorter alias with a nicer prompt)
function s {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { Write-Host 'fzf not found'; return }
    $query = $args -join ' '
    $pick = zoxide query -l |
        fzf --height 40% --reverse --prompt 'repo> ' --query $query --select-1 --exit-0
    if ($pick) { Set-Location $pick }
}

# v            -> open nvim in the current directory (file tree at cwd)
# v <path>     -> open that file/folder in nvim
function v { if ($args) { nvim @args } else { nvim . } }

# sv           -> pick a recent dir AND open nvim there in one step
# sv <words>   -> same, pre-filtered
function sv {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { Write-Host 'fzf not found'; return }
    $pick = zoxide query -l |
        fzf --height 40% --reverse --prompt 'repo> ' --query ($args -join ' ') --select-1 --exit-0
    if ($pick) { Set-Location $pick; nvim . }
}

# --- Repo picker: always lists your two repo roots + every git repo inside ---
# (scans live with fd, so repos show up instantly even on a fresh terminal)
$RepoRoots = @('E:\shubham-git', 'E:\main-repos')

function Get-Repos {
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($root in $RepoRoots) {
        if (-not (Test-Path $root)) { continue }
        $out.Add($root)                                   # the root itself
        # each repo = the folder containing a .git dir (searched a few levels deep)
        fd --hidden --type d --max-depth 5 --glob '.git' $root 2>$null |
            ForEach-Object { $out.Add((Split-Path $_ -Parent)) }
    }
    $out | Sort-Object -Unique
}

# r          -> fuzzy-pick a repo, cd into it
# r <words>  -> same, pre-filtered
function r {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { Write-Host 'fzf not found'; return }
    $pick = Get-Repos |
        fzf --height 50% --reverse --prompt 'repo> ' --query ($args -join ' ') --select-1 --exit-0
    if ($pick) { Set-Location $pick; zoxide add $pick 2>$null }
}

# rv         -> pick a repo AND open nvim there in one step
function rv {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { Write-Host 'fzf not found'; return }
    $pick = Get-Repos |
        fzf --height 50% --reverse --prompt 'repo> ' --query ($args -join ' ') --select-1 --exit-0
    if ($pick) { Set-Location $pick; zoxide add $pick 2>$null; nvim . }
}

# Ctrl+g -> run the repo picker. We type `r` and press Enter so fzf runs as a
# normal foreground command (fzf can't take over the screen from inside a key handler).
if (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+g' -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('r')
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}
