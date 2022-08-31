local fn = vim.fn

-- Automatically install packer.nvim on any machine you clone your configuration to
-- Issue when packer.nvim is opt https://www.reddit.com/r/neovim/comments/ooijlf/packer_prompting_to_delete_packernvim_every_time/
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
    Packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

-- Run PackerCompile whenever plugins/init.lua is updated
-- Register % contains name of current file
-- https://vi.stackexchange.com/questions/104/how-can-i-see-the-full-path-of-the-current-file#:~:text=In%20insert%20mode%2C%20type%20Ctrl%20-%20r%20then,name%20of%20the%20current%20file%20at%20vim%20wikia
vim.cmd([[
  augroup packer_user_config
  autocmd!
  autocmd BufWritePost */plugins/init.lua source %:p | PackerCompile
  augroup end
]])
return require('packer').startup({
    function(use)
        use "wbthomason/packer.nvim"

        local config = function(name)
            return string.format("require('plugins.%s')", name)
        end

        -- lsp
        use({
            "neovim/nvim-lspconfig", -- makes lsp configuration easier
            event = "BufRead",
            requires = {
                "williamboman/nvim-lsp-installer",  -- makes lsp server installation easier
                'b0o/schemastore.nvim',             -- more JSON schemas for jsonls
                {
                    "RRethy/vim-illuminate",            -- intelligently highlight and jump to variable instances/definition
                    config = config("illuminate"),
                },
                {
                    'jose-elias-alvarez/null-ls.nvim',  -- formatter
                    config = config("null-ls"),
                    requires = { "nvim-lua/plenary.nvim" }
                }
            }
        })

        -- completion
        --[[
        (https://github.com/hrsh7th/nvim-cmp#setup)
        hrsh7th/nvim-cmp requires completion source plugins (https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources)
        --]]
        use({
            "hrsh7th/nvim-cmp",
            event = "BufWinEnter",
            config = config("cmp"),
            requires = {
                {"hrsh7th/cmp-nvim-lsp", after = "nvim-cmp"},     -- nvim's built-in language server client w/more client capabilities (more types of completion candidates for language server's completion Requests)
                {"hrsh7th/cmp-buffer",   after = "nvim-cmp"},       -- autocomplete from local buffer
                {"hrsh7th/cmp-path",     after = "nvim-cmp"},         -- filepaths autocomplete
                {"hrsh7th/cmp-cmdline",  after = "nvim-cmp"},      -- vim's cmdline
                {"hrsh7th/cmp-nvim-lua", after = "nvim-cmp"},     -- nvim lua autocomplete
                --"andersevenrud/cmp-tmux",
                "onsails/lspkind-nvim"     -- for completion menu formatting
            },
        })

        use {
            "L3MON4D3/LuaSnip",
            after = "nvim-cmp",
            requires = {
                {"saadparwaiz1/cmp_luasnip", after = "LuaSnip"}, -- for luasnip to be used by cmp
                --"rafamadriz/friendly-snippets" -- VSCode snippets
            }
        }

        -- treesitter (syntax highlighting)
        use({
            'nvim-treesitter/nvim-treesitter',
            run = function() require'nvim-treesitter.install'.update({ with_sync = true }) end, -- When upgrading the plugin, you must make sure that all installed parsers are updated to the latest version via :TSUpdate
            config = config("treesitter"),
            requires = {
                {'p00f/nvim-ts-rainbow', after = "nvim-treesitter"},           -- rainbow parentheses
                {'windwp/nvim-ts-autotag', after = "nvim-treesitter"},         -- auto-pair tags
                {'JoosepAlviste/nvim-ts-context-commentstring', after = "nvim-treesitter"},
            },
        })

        -- finder
        use({
            'nvim-telescope/telescope.nvim',
            config = config('telescope'),
            requires = {
                'nvim-lua/plenary.nvim',
                {
                    'nvim-telescope/telescope-fzf-native.nvim', run = 'make'
                }
            },
        })

        use {
            'ibhagwan/fzf-lua',
            requires = {
                {
                    -- optional for icon support
                    'kyazdani42/nvim-web-devicons', opt = true
                },
                {
                    'junegunn/fzf', run = './install --bin'
                }
            }
        }

        -- status line
        use {
            'nvim-lualine/lualine.nvim', config = config("lualine"),
            requires = { 'kyazdani42/nvim-web-devicons', opt = true }
        }

        -- comment
        use({ "numToStr/Comment.nvim", config = config("comment") })

        -- autopairs
        use {"windwp/nvim-autopairs", config = config("nvim-autopairs"),
            after = "nvim-cmp"
        }

        -- which-key
        use {"folke/which-key.nvim", config = config("which-key")}

        -- tmux
        use {"christoomey/vim-tmux-navigator"}

        -- colorscheme
        use {'Mofiqul/dracula.nvim'}

        -- indent
        use {'lukas-reineke/indent-blankline.nvim'}
        use {'vimjas/vim-python-pep8-indent', ft = "py"}

        -- debugging
        use {
            "mfussenegger/nvim-dap", config = config("nvim-dap"),
            requires = {
                {
                    "rcarriga/nvim-dap-ui", config = config("nvim-dap-ui")
                },
                {
                    "theHamsta/nvim-dap-virtual-text", config = config("nvim-dap-virtual-text")
                },
                {
                    "nvim-telescope/telescope-dap.nvim",
                    requires = { "nvim-telescope/telescope.nvim", "nvim-treesitter/nvim-treesitter" }
                },
                {
                    'mfussenegger/nvim-dap-python', config = config("nvim-dap-python"),
                    requires = { "nvim-treesitter/nvim-treesitter" }
                }
            }
        }

        -- image viewer
        use {"samodostal/image.nvim", config = config("image"),
            requires = {'nvim-lua/plenary.nvim'}}

        -- TODO: Add plugins for git

        -- Automatically set up your configuration after cloning packer.nvim
        -- Put this at the end after all plugins
        if Packer_bootstrap then
            require('packer').sync()
        end
    end,
    config = {
        -- Floating window for Packer command outputs (https://github.com/wbthomason/packer.nvim#using-a-floating-window)
        display =
            {
                open_fn = function() return require('packer.util').float({ border = 'rounded' }) end
            }
    }
})
