vim.g.mapleader = " " -- Set Space as leader key
vim.keymap.set("n", "<leader>cd", vim.cmd.Ex) -- Open netrw file explorer

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- Move selected lines down
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv") -- Move selected lines up
vim.keymap.set("n", "L", "g_", { desc = "Last non-blank character" })
vim.keymap.set("n", "H", "^", { desc = "First non-blank character" })
vim.keymap.set("n", "J", "mzJ`z") -- Join lines and keep cursor position
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- Half-page down and center cursor
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- Half-page up and center cursor
vim.keymap.set("n", "n", "nzzzv") -- Next search result and center screen
vim.keymap.set("n", "N", "Nzzzv") -- Previous search result and center screen

vim.keymap.set("x", "<leader>p", [["_dP]]) -- Paste without overwriting clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]]) -- Delete without yanking

vim.keymap.set("i", "<C-c>", "<Esc>") -- Use Ctrl+C as Escape

vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz") -- Next quickfix item
vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz") -- Previous quickfix item

vim.keymap.set("n", "Q", "<nop>") -- Disable Ex mode

vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz") -- Next location list item
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz") -- Previous location list item

vim.keymap.set("n", "<leader>cc", "<cmd>!php-cs-fixer fix % --using-cache=no<CR>") -- Format PHP file

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]]) -- Replace word under cursor

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true }) -- Make file executable

vim.keymap.set("n", "<leader>y", "<Plug>OSCYankOperator") -- Yank to clipboard over SSH
vim.keymap.set("v", "<leader>y", "<Plug>OSCYankVisual") -- Yank selection over SSH

vim.keymap.set("n", "<leader>rl", "<cmd>source ~/.config/nvim/init.lua<CR>") -- Reload Neovim config

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle) -- Toggle undo tree

vim.keymap.set("n", "<leader>cl", "<cmd>cclose<CR>") -- Close quickfix window
vim.keymap.set("n", "<leader>co", "<cmd>copen<CR>") -- Open quickfix window
vim.keymap.set("n", "<leader>cn", "<cmd>cnext<CR>zz") -- Next quickfix result
vim.keymap.set("n", "<leader>cp", "<cmd>cprev<CR>zz") -- Previous quickfix result

vim.keymap.set("n", "<leader>li", "<cmd>checkhealth vim.lsp<CR>") -- Check LSP health

vim.keymap.set("n", "<leader>mm", "<cmd>make<CR>") -- Run make in current project

vim.keymap.set("n", "<leader><leader>", "<cmd>Telescope find_files<CR>") -- Quick Open (fuzzy file search, matches VS Code)
