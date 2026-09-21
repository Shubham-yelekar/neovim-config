# ------------------------------------------------------
# Detect whether a pane is REALLY occupied
# by an interactive Neovim instance
# ------------------------------------------------------
#
# POSIX shell helper shared by:
#
#     pane-nav.sh
#     send-to-pane.sh
#
# This file only performs detection.
# It never performs navigation or actions.
#
#
# ------------------------------------------------------
# Why NOT use @pane-is-vim?
# ------------------------------------------------------
#
# @pane-is-vim is state maintained by the
# smart-splits plugin, not the actual truth.
#
# If Neovim:
#
# • crashes
# • is killed
# • exits unexpectedly
#
# or the plugin accidentally updates the wrong pane
# (for example, calling display-message without -t and
# therefore modifying the currently active pane instead
# of the pane actually running Neovim),
#
# the pane may permanently keep:
#
#     @pane-is-vim=1
#
# tmux will forever believe that pane is running
# Neovim.
#
# Consequences:
#
# • Pane navigation gets stuck.
# • send-to-pane cannot find a destination.
#
#
# ------------------------------------------------------
# Why NOT use:
#
#     ps -t <tty> | grep vim
#
# ?
# ------------------------------------------------------
#
# This is the classic vim-tmux-navigator approach.
#
# It correctly detects editors behind wrappers like:
#
# • sudo
# • shell wrappers
#
# However...
#
# it scans EVERY process attached to the terminal.
#
# Modern AI CLIs such as:
#
# • Claude
# • Codex
#
# launch hidden/headless Neovim instances in the
# background.
#
# Those editors would be mistaken for the foreground
# editor, recreating the same "can't leave the pane"
# problem in a different form.
#
#
# ------------------------------------------------------
# Detection Strategy
# ------------------------------------------------------
#
# 1.
#
# Foreground process IS Neovim
#
#     → YES
#
# (This covers ~99% of cases.)
#
#
# 2.
#
# Foreground process is a known wrapper that may
# launch an editor.
#
# Examples:
#
# • sudo
# • git
# • yazi
# • shell wrappers
#
# Search its descendants.
#
# A child Neovim only counts if:
#
# • it owns the foreground process group
# • it isn't suspended
#
#
# 3.
#
# Everything else
#
# • Claude
# • Codex
# • idle shell
# • arbitrary programs
#
#     → NO
#
# The whitelist in step 2 is the important part.
#
# AI CLIs are intentionally excluded, so their hidden
# background Neovim instances are never considered.
#

# ------------------------------------------------------
# Neovim process names
# ------------------------------------------------------
#
# Returns true if the process belongs to the
# Vim / Neovim family.
#
is_nvim_name() {
  case ${1##*/} in
    nvim|vim|vi|view|vimdiff|nvimdiff|gvim|gview|*nvim*) return 0 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------
# Remote sessions
# ------------------------------------------------------
#
# tmux cannot know what is running on the remote host.
#
# The caller decides how remote sessions
# should be treated.
#
is_remote() {
  case ${1##*/} in
    ssh|sshpass|autossh|mosh|mosh-client|et|kitten) return 0 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------
# Programs that launch $EDITOR as a child
# ------------------------------------------------------
#
# Only these programs are allowed to have their
# descendants searched.
#
# Everything else is ignored.
#
# This is the key to preventing AI CLIs'
# background Neovim processes from being mistaken
# for the interactive editor.
#
opens_editor_as_child() {
  case ${1##*/} in

    # Privilege / environment wrappers.
    sudo|doas|su|env|nice|nohup|stdbuf|time|script)
      return 0
      ;;

    # Programs that invoke $EDITOR.
    #
    # git commit
    # git rebase -i
    # lazygit
    # crontab -e
    #
    git|lazygit|gitui|jj|hg|crontab|fzf)
      return 0
      ;;

    # File managers.
    #
    # Pressing Enter opens the editor.
    #
    yazi|lf|ranger|nnn|vifm)
      return 0
      ;;

    # Wrapper scripts that don't exec.
    #
    # The foreground process remains the shell.
    #
    sh|bash|zsh|dash|ksh|fish)
      return 0
      ;;

    *)
      return 1
      ;;
  esac
}

# ------------------------------------------------------
# Headless Neovim
# ------------------------------------------------------
#
# Detect Neovim started with:
#
#     --headless
#
# or
#
#     --embed
#
# These instances do not own the terminal.
#
# They are backend editors,
# commonly launched by AI tools.
#
is_headless_nvim() {
  case $(ps -o args= -p "$1" 2>/dev/null || true) in
    *--headless*|*--embed*) return 0 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------
# Foreground Process Check
# ------------------------------------------------------
#
# Returns true only if the process:
#
# • owns the terminal's foreground process group
#
# • is not suspended
#
# • is not dead
#
# • is not a zombie
#
# Rejects:
#
#     Ctrl+Z
#
# and
#
#     nvim &
#
is_running_in_foreground() {
  read -r _state _pgid _tpgid <<EOF
$(ps -o state=,pgid=,tpgid= -p "$1" 2>/dev/null || echo 'X 0 -1')
EOF

  [ "$_pgid" = "$_tpgid" ] || return 1

  case $_state in
    *[TXZ]*) return 1 ;;
  esac

  return 0
}

# ------------------------------------------------------
# Recursive Child Search
# ------------------------------------------------------
#
# Recursively search descendants of a process.
#
# Example:
#
# zsh
#   └── git
#         └── nvim
#
# A matching descendant only counts if:
#
# • it owns the foreground terminal
#
# • it isn't headless
#
descendant_match() {

  for _child in $(pgrep -P "$2" 2>/dev/null || true); do

    _name=$(ps -o comm= -p "$_child" 2>/dev/null || true)

    [ -n "$_name" ] || continue

    if "$1" "$_name"; then
      if is_running_in_foreground "$_child" &&
         ! is_headless_nvim "$_child"; then
        return 0
      fi
    fi

    descendant_match "$1" "$_child" && return 0

  done

  return 1
}

# Helper:
# Returns true for either
#
# • Neovim
# • Remote sessions
#
_is_nvim_or_remote() {
  is_nvim_name "$1" || is_remote "$1"
}

# ------------------------------------------------------
# Is this pane running Neovim?
# ------------------------------------------------------
#
# Usage:
#
#     pane_runs_nvim <pid> <command>
#
# Remote sessions do NOT count.
#
# send-to-pane may safely target SSH panes.
#
pane_runs_nvim() {

  is_nvim_name "$2" &&
    ! is_headless_nvim "$1" &&
    return 0

  opens_editor_as_child "$2" &&
    descendant_match is_nvim_name "$1" &&
    return 0

  return 1
}

# ------------------------------------------------------
# Should this pane receive navigation keys?
# ------------------------------------------------------
#
# Usage:
#
#     pane_wants_nav_keys <pid> <command>
#
# Similar to pane_runs_nvim(),
# but also treats remote sessions as valid.
#
# Since tmux cannot inspect the remote machine,
# navigation keys are forwarded and the remote host
# decides how to handle them.
#
pane_wants_nav_keys() {

  is_nvim_name "$2" &&
    ! is_headless_nvim "$1" &&
    return 0

  is_remote "$2" &&
    return 0

  opens_editor_as_child "$2" &&
    descendant_match _is_nvim_or_remote "$1" &&
    return 0

  return 1
}
