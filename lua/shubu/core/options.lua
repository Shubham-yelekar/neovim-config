local set = vim.opt
set.number = true -- Show current line number
set.relativenumber = true -- Show relative line numbers

set.tabstop = 4 -- Tab equals 4 spaces
set.shiftwidth = 4 -- Indent by 4 spaces
set.autoindent = true -- Preserve indentation on new lines
set.expandtab = true -- Convert tabs to spaces

set.ignorecase = true -- Case-insensitive search
set.smartcase = true -- Uppercase makes search case-sensitive

set.termguicolors = true -- Enable true colors
set.background = "dark" -- Use dark theme variants
set.signcolumn = "yes" -- Always show sign column

set.cursorline = true -- Highlight current line
set.colorcolumn = "80" -- Show guide at column 80

set.clipboard:append("unnamedplus") -- Use system clipboard

set.backspace = "indent,eol,start" -- Modern backspace behavior

set.splitbelow = true -- Horizontal splits open below
set.splitright = true -- Vertical splits open right

set.iskeyword:append("-") -- Treat hyphenated words as one word

set.scrolloff = 8 -- Keep 8 lines around cursor

set.swapfile = false -- Disable swap files
set.backup = false -- Disable backup files
set.undodir = os.getenv("HOME") .. "/.vim/undodir" -- Undo file location
set.undofile = true -- Enable persistent undo

set.incsearch = true -- Search while typing
set.updatetime = 50 -- Faster plugin/diagnostic updates
set.wrap = true
set.linebreak = true -- Don't split words
set.breakindent = true -- Preserve indentation
vim.keymap.set({ "n", "v" }, "j", "gj")
vim.keymap.set({ "n", "v" }, "k", "gk")
