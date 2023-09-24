return {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
          vim.o.timeout = true
          vim.o.timeoutlen = 500
        end,
        opts = {
          -- your configuration comes here
          -- or leave it empty to use the default settings
          -- refer to the configuration section below
        },
}

-- Use vim keymaps instead of defining any via which-key
-- https://www.reddit.com/r/neovim/comments/vwud6m/whichkeynvim_whats_the_best_workflow/
--[[ local opts = { ]]
--[[         prefix = "<leader>", ]]
--[[ } ]]
--[[]]
--[[ local mappings = { ]]
--[[]]
--[[ } ]]
--[[]]
--[[ whichkey.register(mappings, opts) ]]
