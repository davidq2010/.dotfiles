local fn = vim.fn

-- Bootstrap lazy.nvim: https://github.com/folke/lazy.nvim#-installation
local install_path = fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(install_path) then
  fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    install_path,
  })
end
vim.opt.rtp:prepend(install_path)

-- Register % contains name of current file
require("lazy").setup(
  -- plugins
  {
    {
      import = "plugins",
    },
    {
      import = "lsp",
    },
  },
  -- opts
  {
    install = {
      colorscheme = { "dracula" },
    },
    checker = {
      enabled = true,
      notify = false,
    },
    change_detection = {
      notify = false,
    },
  }
)
