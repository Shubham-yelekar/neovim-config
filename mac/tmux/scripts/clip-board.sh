#!/usr/bin/env bash

# ------------------------------------------------------
# Cross-platform Clipboard Reader
# ------------------------------------------------------
#
# Reads text from the system clipboard.
#
# Supports:
#
# • macOS
# • WSL2
# • Linux (Wayland)
# • Linux (X11)
#
# Used by tmux's right-click paste feature.
#

case "$OSTYPE" in

  # ----------------------------------------------------
  # macOS
  # ----------------------------------------------------
  #
  # Read the clipboard using the built-in
  # pbpaste utility.
  #
  darwin*)
    pbpaste
    ;;


  # ----------------------------------------------------
  # Linux
  # ----------------------------------------------------
  linux*)

    # ----------------------------------------------
    # WSL2
    # ----------------------------------------------
    #
    # Read the Windows clipboard using
    # PowerShell interoperability.
    #
    # Remove Windows carriage returns (\r)
    # to produce Unix-style line endings.
    #
    if grep -qi microsoft /proc/version 2>/dev/null; then

      powershell.exe -command 'Get-Clipboard' \
        2>/dev/null \
        | sed 's/\r$//'


    # ----------------------------------------------
    # Wayland
    # ----------------------------------------------
    #
    # Use wl-paste.
    #
    elif [[ -n "$WAYLAND_DISPLAY" ]]; then

      wl-paste --no-newline 2>/dev/null


    # ----------------------------------------------
    # X11
    # ----------------------------------------------
    #
    # Prefer xclip.
    #
    # If unavailable,
    # fall back to xsel.
    #
    else

      xclip -o -selection clipboard 2>/dev/null \
        || xsel --clipboard --output 2>/dev/null

    fi
    ;;
esac
