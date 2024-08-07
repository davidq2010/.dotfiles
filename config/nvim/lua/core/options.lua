-- ":help vim_diff" to see nvim defaults that differ from vim defaults

-- Global options
vim.g.tex_flavor = "latex"

-- Misc Display options
vim.opt.mouse = "a" -- enable mouse in all modes
vim.opt.number = true -- show line number
vim.opt.relativenumber = true -- relative line numbers
vim.opt.showcmd = false -- don't show partial command in last line
vim.opt.showmode = false -- don't show mode since it's already in status line
vim.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.updatetime = 250 -- faster completion
vim.opt.timeoutlen = 300 -- time in ms to wait for a mapped sequence to complete
vim.opt.wrap = false -- don't wrap if line is too long
vim.opt.scrolloff = 4 -- min num lines to keep above/below cursor; some visible context around cursor line

vim.opt.sidescrolloff = 2 -- min num screen cols to keep left/right of cursor if 'nowrap' is set
vim.opt.signcolumn = "yes" -- always show the sign column otherwise it would shift the text each time

-- Cursorline options
-- TODO: After updating to nightly: https://github.com/tjdevries/config_manager/blob/8d56cc3e4eeaeb8087b3b56d0178741a7e2d924c/xdg_config/nvim/plugin/options.lua#:~:text=%2D%2D%20%20Only%20have%20it%20on%20in%20the%20active%20buffer
-- This is to only highlight in the current buffer
vim.opt.cursorline = true -- highlight the current line
-- https://stackoverflow.com/questions/8640276/how-do-i-change-my-vim-highlight-line-to-not-be-an-underline
vim.cmd([[
  highlight CursorLine cterm=bold guibg=DarkGray
]])

-- Popup options
vim.opt.pumblend = 10
vim.opt.pumheight = 10 -- 10 items max in popup menu

-- Indent options
vim.opt.smartindent = true -- make indenting smarter again
vim.opt.expandtab = true -- expand tab characters to spaces
vim.opt.tabstop = 2 -- 2 spaces for tab
vim.opt.softtabstop = 2 -- insert 2 spaces to simulate tab stops at this width
vim.opt.shiftwidth = 2 -- use 2 spaces for >> and <<
vim.opt.smarttab = true -- in insert mode, tab key inserts spaces to go to next tabstop
vim.opt.breakindent = true -- wrapped lines continue visually indented

-- Undo options
vim.opt.swapfile = false -- no .swp files
vim.opt.backup = false
vim.opt.undofile = true -- persist undo actions to file
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"

-- Search options
vim.opt.ignorecase = true -- ignore case in search patterns
vim.opt.smartcase = true -- override 'ignorecase' if search pattern contains uppercase

-- Backup options
vim.opt.writebackup = false -- no concurrent file editing

-- Screen Split options
vim.opt.splitbelow = true -- force all horizontal splits to go below current window
vim.opt.splitright = true -- force all vertical splits to go to the right of current window

-- Format options
-- Per https://vi.stackexchange.com/questions/13864/bufwinleave-mkview-with-unnamed-file-error-32
-- Also, per https://stackoverflow.com/questions/26917336/vim-specific-mkview-and-loadview-in-order-to-avoid-issues
-- not setting viewoptions' "options" ensures that saved views do not call local mappings
vim.opt.viewoptions = "folds,cursor"
vim.opt.sessionoptions = "folds"
-- https://github.com/nanotee/nvim-lua-guide#using-meta-accessors
-- However, this doesn't work b/c some default plugins are loaded later than init.lua which override these
-- Can check via :verbose set formatoptions
vim.opt.formatoptions = "jcroqlnt"

vim.opt.grepformat = "%f:%l:%c:%m"

-- https://stackoverflow.com/questions/30691466/what-is-difference-between-vims-clipboard-unnamed-and-unnamedplus-settings
vim.opt.clipboard:prepend({ "unnamed", "unnamedplus" })

-- Spellcheck options
vim.cmd([[
  augroup spellcheck
    autocmd!
    autocmd FileType tex setlocal spell
    autocmd FileType html setlocal spell
  augroup end
]])

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split' -- Preview substitutions live, as you type

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true

vim.g.markdown_recommended_style = 0
