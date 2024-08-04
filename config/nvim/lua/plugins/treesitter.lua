-- Let Treesitter handle folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "VeryLazy" },
    dependencies = {
      "p00f/nvim-ts-rainbow", -- rainbow parentheses
      "windwp/nvim-ts-autotag", -- auto-pair tags
    },
    opts = {
        ensure_installed = "all",

        highlight = {
          enable = true, -- false will disable whole extension
          -- disable = { 'json' }, -- list of language that will be disabled
        },
        indent = {
          enable = true,
          -- disable = { },
        }, -- experimental (indentation based on treesitter for = operator)

        -- plugins
        autotag = { enable = true },
        rainbow = { enable = true },
    },
    config = function(_, opts)
      -- Prefer git instead of curl in order to improve connectivity in some environments
      require('nvim-treesitter.install').prefer_git = true
      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup(opts)
    end,
  },
}
