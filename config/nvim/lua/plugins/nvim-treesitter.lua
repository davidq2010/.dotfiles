-- Let Treesitter handle folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "p00f/nvim-ts-rainbow", -- rainbow parentheses
      "windwp/nvim-ts-autotag", -- auto-pair tags
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = "all",

        highlight = {
          enable = true, -- false will disable whole extension
          -- disable = { 'json' }, -- list of language that will be disabled
        },
        indent = {
          enable = true,
          disable = { "python" },
        }, -- experimental (indentation based on treesitter for = operator)

        -- plugins
        autotag = { enable = true },
        rainbow = { enable = true },
      })
    end,
  },
}
