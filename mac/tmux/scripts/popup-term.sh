#!/bin/sh

# ------------------------------------------------------
# Persistent Popup Terminal
# ------------------------------------------------------
#
# Opens a persistent "scratch" terminal inside
# a tmux popup.
#
# Intended as a replacement for Neovim's built-in
# terminal or ToggleTerm.
#
# Usage:
#
#     popup-term.sh <directory> [instance-id]
#
#
# ------------------------------------------------------
# Why not simply use:
#
#     display-popup -E $SHELL
#
# ?
#
# Because every popup would launch a completely
# new shell.
#
# Closing the popup would lose:
#
# • Shell history
# • Running processes
# • REPL state
# • Watchers
# • Build jobs
#
# That is actually worse than ToggleTerm.
#
# Instead,
# this popup attaches to a dedicated, persistent
# tmux session.
#
# Closing the popup only DETACHES from the session.
#
# Everything inside continues running.
#
# Next time the popup opens,
# it reconnects to the same session.
#
#
# ------------------------------------------------------
# Two important tmux quirks
# ------------------------------------------------------
#
# 1.
#
# Inside a popup,
# the environment variable:
#
#     $TMUX
#
# is already set.
#
# Running:
#
#     tmux attach
#
# would fail with:
#
#     "sessions should be nested with care,
#      unset $TMUX to force"
#
# Therefore,
# the popup attaches using:
#
#     TMUX= tmux attach
#
# which temporarily clears $TMUX.
#
#
# 2.
#
# The session target:
#
#     =session-name
#
# performs an exact match in tmux.
#
# However,
# in zsh,
#
#     =command
#
# has special meaning and expands to a command path.
#
# Therefore,
# the session name must always be quoted.
#

set -eu


# ------------------------------------------------------
# Working Directory
# ------------------------------------------------------

# First argument:
#
# Working directory for the popup.
#
# Default:
#
# Current directory.
#
dir="${1:-$PWD}"

# If the directory doesn't exist,
# fall back to HOME.
[ -d "$dir" ] || dir="$HOME"


# ------------------------------------------------------
# Popup Session Name
# ------------------------------------------------------
#
# Neovim passes an instance ID.
#
# This allows each Neovim instance
# to own its own popup terminal.
#
# Normal tmux panes simply reuse
# one popup per directory.
#

base="${2:-$(basename "$dir")}"


# tmux session names treat:
#
#     .
#     :
#
# as special separators.
#
# Replace every unsafe character
# with '-'.
#
base=$(printf '%s' "$base" | sed 's/[^[:alnum:]_-]/-/g')

# Never allow an empty name.
[ -n "$base" ] || base="root"

# Final popup session name.
name="popup-$base"


# ------------------------------------------------------
# Create the popup session
# ------------------------------------------------------
#
# If it doesn't already exist,
# create it.
#
if ! tmux has-session -t "=$name" 2>/dev/null; then

    tmux new-session \
        -d \
        -s "$name" \
        -c "$dir"

    #
    # The popup already has limited height.
    #
    # Since this popup session only contains
    # a single window,
    # disable its status bar to save space.
    #
    # Note:
    #
    # set-option does NOT support
    # the "=session" exact-match syntax.
    #
    tmux set-option -t "$name" status off

fi


# ------------------------------------------------------
# Open Popup
# ------------------------------------------------------
#
# The popup simply attaches to
# the existing persistent session.
#
# Since $name has already been sanitized,
# it is safe to interpolate directly.
#
# The directory is passed through -d,
# avoiding shell quoting issues.
#
tmux display-popup \
    -E \
    -w 90% \
    -h 90% \
    -d "$dir" \
    -T " $name " \
    "TMUX= tmux attach -t '=$name'"
