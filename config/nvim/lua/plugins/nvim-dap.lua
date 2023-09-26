local u = require("utils")

local dapui_config = function()
  local dap, dapui = require("dap"), require("dapui")
  dapui.setup()
  -- You can use nvim-dap events to open and close the windows automatically
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end

local dap_python_config = function()
  local dp = require("dap-python")
  -- I'm not sure if we need a step to add this dir and install debugpy if not there.
  -- This plugin will check if a virtualenv/conda_env is active to use those environments
  -- https://github.com/mfussenegger/nvim-dap-python#python-dependencies-and-virtualenv
  dp.setup("~/.virtualenvs/debugpy/bin/python")
  dp.test_runner = "pytest"

  u.nmap("<leader>dt", ":lua require'dap-python'.test_method()<CR>")
  u.nmap("<leader>dc", ":lua require'dap-python'.test_class()<CR>")
  u.vmap("<leader>ds", "<ESC>:lua require'dap-python'.debug_selection()<CR>")
end

local dap_virtual_text_config = function()
  require("nvim-dap-virtual-text").setup()
end

local dap_config = function()
  u.nmap("<F5>", ":lua require'dap'.continue()<CR>")
  u.nmap("<F10>", ":lua require'dap'.step_over()<CR>")
  u.nmap("<F11>", ":lua require'dap'.step_into()<CR>")
  u.nmap("<F12>", ":lua require'dap'.step_out()<CR>")
  u.nmap("<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>")
  u.nmap("<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
  u.nmap("<leader>lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
  u.nmap("<leader>dr", ":lua require'dap'.repl.open()<CR>")
end

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      config = dapui_config,
    },
    {
      "theHamsta/nvim-dap-virtual-text",
      config = dap_virtual_text_config,
    },
    {
      "nvim-telescope/telescope-dap.nvim",
      dependencies = { "nvim-telescope/telescope.nvim", "nvim-treesitter/nvim-treesitter" },
    },
    {
      "mfussenegger/nvim-dap-python",
      config = dap_python_config,
      dependencies = { "nvim-treesitter/nvim-treesitter" },
    },
  },
  config = dap_config,
}
