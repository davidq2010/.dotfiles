-- From https://github.com/jose-elias-alvarez/dotfiles

-- For all docs, can do :help <keyword>

-- nvim lua docs: https://neovim.io/doc/user/lua.html
-- nvim API: https://neovim.io/doc/user/api.html

local get_map_options = function(custom_options)
  local options = { noremap = true, silent = true }
  if custom_options then
    options = vim.tbl_extend("force", options, custom_options)
  end
  return options
end

-- TODO: Define my own autocmd interface

-- https://github.com/nanotee/nvim-lua-guide#modules
local M = {}

-- Although we call it "map", they're really noremap b/c of get_map_options()
M.map = function(mode, target, source, opts)
  vim.keymap.set(mode, target, source, get_map_options(opts))
end

-- Add some common map modes to M
for _, mode in ipairs({ "n", "v", "o", "i", "x", "t" }) do
  M[mode .. "map"] = function(...)
    M.map(mode, ...)
  end
end

-- Buffer-local mapping
M.buf_map = function(mode, target, source, opts, bufnr)
  local buf_opts = { buffer = bufnr or 0 }
  if opts then
    buf_opts = vim.tbl_extend("force", buf_opts, opts)
  end
  vim.keymap.set(mode, target, source, get_map_options(buf_opts))
end

-- Defines a ':' command; the bang means redefine the command if it already exists
-- 'command' assigns a name to a ':' command while <cmd>...<CR> avoids mode-changes and doesn't trigger CmdlineEnter/Leave events (helps perf)
M.command = function(name, fn)
  vim.cmd(string.format("command! %s %s", name, fn))
end

M.lua_command = function(name, fn)
  M.command(name, "lua " .. fn)
end

M.t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

M.input = function(keys, mode)
  vim.api.nvim_feedkeys(M.t(keys), mode or "i", true)
end

M.warn = function(msg)
  vim.api.nvim_echo({ { msg, "WarningMsg" } }, true, {})
end

--- Gets a path to a package in the Mason registry.
--- Prefer this to `get_package`, since the package might not always be
--- available yet and trigger errors.
---@param pkg string
---@param path? string
---@param opts? { warn?: boolean }
function M.get_pkg_path(pkg, path, opts)
  pcall(require, "mason") -- make sure Mason is loaded. Will fail when generating docs
  local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
  opts = opts or {}
  opts.warn = opts.warn == nil and true or opts.warn
  path = path or ""
  local ret = root .. "/packages/" .. pkg .. "/" .. path
  if opts.warn and not vim.loop.fs_stat(ret) and not require("lazy.core.config").headless() then
    M.warn(
      ("Mason package path not found for **%s**:\n- `%s`\nYou may need to force update the package."):format(pkg, path)
    )
  end
  return ret
end

return M
