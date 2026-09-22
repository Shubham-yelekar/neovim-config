return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      -- vim.o.shell is cmd.exe on Windows. PowerShell is what the profile
      -- (oh-my-posh, eza, zoxide) is written for, so open that instead.
      shell = "powershell.exe -NoLogo",
      size = 15,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = false,
      direction = "horizontal",
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      close_on_exit = true,
    })

    -- Terminal insert mode eats Ctrl+hjkl.
    -- Map them to window moves so you can leave the toggleterm
    -- without clicking back into the editor.
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*",
      callback = function()
        local opts = { buffer = 0, silent = true }
        local map = function(lhs, dir)
          vim.keymap.set("t", lhs, [[<C-\><C-n><C-w>]] .. dir, opts)
        end

        map("<C-h>", "h")
        map("<C-j>", "j")
        map("<C-k>", "k")
        map("<C-l>", "l")
      end,
    })
  end,
}
