local whichkey = require("which-key")

whichkey.setup {
        window = {
                border = "single"
        }
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
