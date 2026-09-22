return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    -- format-on-save is OFF by default (matches VS Code); toggle with <leader>tf
    vim.g.format_on_save_enabled = false

    conform.setup({
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        htmlangular = { "prettier" }, -- Angular templates (Neovim 0.12+ filetype)
        json = { "prettier" },
        jsonc = { "prettier" }, -- JSON with comments (e.g. tsconfig, settings.json)
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
      },
      -- return nil to skip formatting unless the toggle is on
      format_on_save = function()
        if not vim.g.format_on_save_enabled then
          return
        end
        return { lsp_fallback = true, async = false, timeout_ms = 1000 }
      end,
    })

    -- format now (one-off), works in normal + visual (range)
    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (in visual mode)" })

    -- toggle format-on-save (Neovim equivalent of your VS Code F3)
    vim.keymap.set("n", "<leader>tf", function()
      vim.g.format_on_save_enabled = not vim.g.format_on_save_enabled
      vim.notify("Format on save: " .. (vim.g.format_on_save_enabled and "ON" or "OFF"))
    end, { desc = "Toggle format on save" })
  end,
}
