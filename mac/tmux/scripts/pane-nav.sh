#!/bin/sh

# ------------------------------------------------------
# Smart Pane Navigation
# ------------------------------------------------------
#
# Unified entry point for:
#
#   Ctrl+Alt+H/J/K/L
#   Ctrl+Alt+Arrow Keys
#
# Decides whether the key should:
#
#   • Be forwarded to the application running inside
#     the pane (Neovim via smart-splits, or a remote
#     session handling its own navigation),
#
#   OR
#
#   • Be handled by tmux itself
#     (move between panes or resize them).
#
# Usage:
#
#     pane-nav.sh <move|resize> <h|j|k|l> <pane_id>
#
# The actual "Is Neovim running?" detection lives in:
#
#     lib/nvim-detect.sh
#
# That file explains why this configuration:
#
# • Does NOT use @pane-is-vim
# • Does NOT scan the entire TTY
#

set -eu


# ------------------------------------------------------
# Load Neovim detection helpers
# ------------------------------------------------------

. "$(dirname "$0")/lib/nvim-detect.sh"


# ------------------------------------------------------
# Arguments
# ------------------------------------------------------

mode=$1      # move | resize
dir=$2       # h j k l
pane=$3      # tmux pane id


# ------------------------------------------------------
# Translate Vim directions into tmux directions
# ------------------------------------------------------

case $dir in

  h)
    tmux_dir=L
    edge=pane_at_left
    move_key=C-M-h
    resize_key=C-M-Left
    ;;

  j)
    tmux_dir=D
    edge=pane_at_bottom
    move_key=C-M-j
    resize_key=C-M-Down
    ;;

  k)
    tmux_dir=U
    edge=pane_at_top
    move_key=C-M-k
    resize_key=C-M-Up
    ;;

  l)
    tmux_dir=R
    edge=pane_at_right
    move_key=C-M-l
    resize_key=C-M-Right
    ;;

  *)
    exit 1
    ;;

esac


# ------------------------------------------------------
# Read pane information in a single tmux call
# ------------------------------------------------------
#
# Collect:
#
# • pane process ID
# • current foreground command
# • whether this pane is already at the edge
#
# Doing everything in one tmux call is faster.
#
read -r pane_pid pane_cmd at_edge <<EOF
$(tmux display-message -p -t "$pane" \
"#{pane_pid} #{pane_current_command} #{$edge}")
EOF


# ------------------------------------------------------
# Should the application receive the navigation key?
# ------------------------------------------------------
#
# Ask the helper:
#
#     pane_wants_nav_keys()
#
# If yes,
#
# forward the key directly into the pane.
#
if pane_wants_nav_keys "$pane_pid" "$pane_cmd"; then

  if [ "$mode" = resize ]; then
    key=$resize_key
  else
    key=$move_key
  fi

  tmux send-keys -t "$pane" "$key"

  exit 0
fi


# ------------------------------------------------------
# tmux handles pane resizing
# ------------------------------------------------------

if [ "$mode" = resize ]; then

  tmux resize-pane -t "$pane" "-$tmux_dir" 3

  exit 0

fi


# ------------------------------------------------------
# Prevent pane wrapping
# ------------------------------------------------------
#
# If we're already at the edge,
# do nothing.
#
# This avoids wrapping around to the
# opposite pane.
#
[ "$at_edge" = 1 ] && exit 0


# ------------------------------------------------------
# Move to adjacent pane
# ------------------------------------------------------

tmux select-pane -t "$pane" "-$tmux_dir"
