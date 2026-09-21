#!/bin/sh

# ------------------------------------------------------
# Send stdin to another tmux pane
# ------------------------------------------------------
#
# Reads text from stdin and pastes it into the first pane
# in the current tmux window that is NOT running Neovim.
#
# When launched from nvd/Neovide,
# it prefers sending the text back to the tmux window that
# originally launched Neovide.
#
# Detection of whether a pane is running Neovim is handled
# by:
#
#     lib/nvim-detect.sh
#
# This intentionally does NOT rely on smart-splits'
#
#     @pane-is-vim
#
# variable.
#
# That variable can become stale if Neovim crashes or is
# killed, causing every pane to be incorrectly identified
# as a Neovim pane.
#

set -eu

# ------------------------------------------------------
# Load Neovim detection helpers
# ------------------------------------------------------

. "$(dirname "$0")/lib/nvim-detect.sh"


# ------------------------------------------------------
# Determine the current pane
# ------------------------------------------------------
#
# Priority:
#
# 1. Pane provided by Neovide (nvd)
# 2. TMUX_PANE (automatically injected by tmux)
# 3. Active pane reported by tmux
#
# TMUX_PANE is preferred because it always identifies
# the pane running this process.
#
# display-message without -t only returns the currently
# active pane, which may be different.
#

current="${NVD_TMUX_ORIGIN_PANE:-${TMUX_PANE:-$(tmux display-message -p '#{pane_id}')}}"

target_window="${NVD_TMUX_ORIGIN_WINDOW:-}"


# ------------------------------------------------------
# Validate the target window
# ------------------------------------------------------
#
# If Neovide supplied an originating window,
# make sure it still exists.
#
# Otherwise,
# ignore it.
#

if [ -n "$target_window" ]; then
  tmux display-message -p -t "$target_window" '#{window_id}' >/dev/null 2>&1 \
    || target_window=""
fi


# ------------------------------------------------------
# Collect all panes
# ------------------------------------------------------
#
# Gather:
#
# • Pane ID
# • Process ID
# • Current foreground command
#
panes=$(tmux list-panes -t "${target_window:-$current}" \
  -F '#{pane_id}|#{pane_pid}|#{pane_current_command}')


# ------------------------------------------------------
# Find the destination pane
# ------------------------------------------------------
#
# Skip:
#
# • Current pane
# • Any pane running Neovim
#
# Select the first remaining pane.
#
target=""

while IFS='|' read -r id pid cmd; do

  # Skip ourselves.
  [ "$id" = "$current" ] && continue

  # Skip Neovim panes.
  pane_runs_nvim "$pid" "$cmd" && continue

  # First suitable pane.
  target=$id
  break

done <<EOF
$panes
EOF


# Nothing found.
[ -z "$target" ] && exit 1


# ------------------------------------------------------
# Send stdin
# ------------------------------------------------------
#
# Read stdin into tmux's buffer,
# then paste it into the target pane.
#
tmux load-buffer -

tmux paste-buffer -t "$target" -p
