#!/usr/bin/env bash

# ------------------------------------------------------
# Cross-platform URL Opener
# ------------------------------------------------------
#
# Opens a URL using the operating system's
# default browser.
#
# Supports:
#
# • macOS
# • WSL2
# • Linux
#
# Used by:
#
#     Ctrl + Click
#
# inside tmux.
#

# First argument is the URL.
url=$1

# Exit immediately if no URL was provided.
[ -z "$url" ] && exit 0


case "$OSTYPE" in

  # ----------------------------------------------------
  # macOS
  # ----------------------------------------------------
  #
  # Open the URL using the default browser.
  #
  darwin*)
    open "$url"
    ;;


  # ----------------------------------------------------
  # Linux
  # ----------------------------------------------------
  linux*)

    # ----------------------------------------------
    # WSL2
    # ----------------------------------------------
    #
    # Prefer:
    #
    #     wslview
    #
    # If unavailable,
    # fall back to Windows PowerShell.
    #
    if grep -qi microsoft /proc/version 2>/dev/null; then

      command -v wslview >/dev/null \
        && wslview "$url" \
        || powershell.exe -NoProfile \
           -Command "Start-Process '$url'" \
           2>/dev/null

    # ----------------------------------------------
    # Native Linux
    # ----------------------------------------------
    #
    # Open using the system's default application.
    #
    else

      xdg-open "$url" >/dev/null 2>&1

    fi
    ;;
esac
