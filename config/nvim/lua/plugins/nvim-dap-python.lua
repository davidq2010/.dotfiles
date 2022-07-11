local dp = require('dap-python')
local u = require("utils")

dp.setup('~/.virtualenvs/debugpy/bin/python')
dp.test_runner = 'pytest'

u.nmap("<leader>dn", ":lua require'dap-python'.test_method()<CR>")
u.nmap("<leader>df", ":lua require'dap-python'.test_class()<CR>")
u.vmap("<leader>ds", "<ESC>:lua require'dap-python'.debug_selection()<CR>")
