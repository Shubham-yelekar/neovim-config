local set = vim.opt
set.number = true -- Show current line number
set.relativenumber = true -- Show relative line numbers

set.tabstop = 2 -- Tab equals 2 spaces (match VS Code / Prettier)
set.shiftwidth = 2 -- Indent by 2 spaces
set.autoindent = true -- Preserve indentation on new lines
set.expandtab = true -- Convert tabs to spaces

set.ignorecase = true -- Case-insensitive search
set.smartcase = true -- Uppercase makes search case-sensitive

set.termguicolors = true -- Enable true colors
set.background = "dark" -- Use dark theme variants
set.signcolumn = "yes" -- Always show sign column

set.cursorline = true -- Highlight current line
-- set.colorcolumn = "80" -- Show guide at column 80

set.clipboard:append("unnamedplus") -- Use system clipboard

set.backspace = "indent,eol,start" -- Modern backspace behavior

set.splitbelow = true -- Horizontal splits open below
set.splitright = true -- Vertical splits open right

set.iskeyword:append("-") -- Treat hyphenated words as one word

set.scrolloff = 5 -- Keep 5 lines around cursor (match VS Code)

set.swapfile = false -- Disable swap files
set.backup = false -- Disable backup files
set.undodir = vim.fn.stdpath("data") .. "/undodir" -- Undo file location (cross-platform)
set.undofile = true -- Enable persistent undo

-- Neovim's default sessionoptions omits localoptions, so a restored session comes
-- back without per-buffer local options -- filetype and syntax highlighting are the
-- visible casualties. auto-session warns about this in :checkhealth auto-session;
-- this is the value it recommends (the default plus winpos and localoptions).
set.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Git Bash as the shell. floaterm spawns `vim.o.shell` directly and offers no
-- per-terminal shell option (toggleterm did), and project commands -- npm test,
-- dev servers -- are written for a POSIX shell.
--
-- Deliberately NOT vim.fn.exepath("bash"): when nvim is launched from wezterm
-- or Explorer the `bash` on PATH is WSL's stub at C:\WINDOWS\system32\bash.exe,
-- which opens a Linux VM instead of Git Bash.
--
-- The 8.3 short names (PROGRA~1) are not cosmetic -- this value has to satisfy
-- two callers that disagree about quoting, and a path containing a space can
-- only ever satisfy one of them:
--
--   * floaterm does jobstart({ vim.o.shell }, { term = true }), a bare argv
--     list, so argv[0] must NOT be quoted -- quotes become part of the
--     filename and it fails E475: not executable.
--   * :! / :make / system() interpolate it into a shell string, where an
--     unquoted space splits the command and the spawn fails with rc=-1.
--
-- A space-free path needs no quoting, so both work. fnamemodify(p, ":8") is
-- no help here: it silently returns the long path unchanged.
--
-- lazygit.nvim forces cmd.exe for its own shelling out and restores this
-- afterwards, so <leader>gg is unaffected.
for _, candidate in ipairs({
  "C:/PROGRA~1/Git/bin/bash.exe", -- C:\Program Files\Git
  "C:/PROGRA~2/Git/bin/bash.exe", -- C:\Program Files (x86)\Git
  -- per-user install, when Git was installed without admin rights
  (vim.env.LOCALAPPDATA or ""):gsub("\\", "/") .. "/Programs/Git/bin/bash.exe",
}) do
  if vim.fn.executable(candidate) == 1 then
    set.shell = candidate
    set.shellcmdflag = "-c" -- bash takes -c, cmd.exe took /c
    set.shellredir = ">%s 2>&1"
    set.shellpipe = "2>&1 | tee %s"
    set.shellquote = ""
    set.shellxquote = "" -- Windows default is a bare quote; bash wants none
    break
  end
end

set.incsearch = true -- Search while typing
set.updatetime = 50 -- Faster plugin/diagnostic updates
set.wrap = true
set.linebreak = true -- Don't split words
set.breakindent = true -- Preserve indentation
vim.keymap.set({ "n", "v" }, "j", "gj")
vim.keymap.set({ "n", "v" }, "k", "gk")
