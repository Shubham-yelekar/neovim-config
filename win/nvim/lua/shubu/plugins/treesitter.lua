return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
 dependencies = {
    "windwp/nvim-ts-autotag",
  },
    config = function()
        require("nvim-treesitter").install({
            "lua",
            "vim",
            "vimdoc",
            "javascript",
            "typescript",
            "tsx",
            "html",
            "css",
            "json",
            "markdown",
            "bash",
        })
        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                pcall(vim.treesitter.start)
            end,
        })
    end,
}
