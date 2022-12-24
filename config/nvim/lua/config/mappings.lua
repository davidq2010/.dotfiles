local u = require("utils")

u.nmap("Y", "y$")
-- https://vim.fandom.com/wiki/Recover_from_accidental_Ctrl-U
u.imap("<C-U>", "<C-G>u<C-U>")
u.imap("<C-W>", "<C-G>u<C-W>")
-- https://stackoverflow.com/a/662914
u.nmap("<CR>", "<Cmd>nohlsearch<CR><CR>")

-- move visual lines around as a chunk
u.vmap("J", ":m '>+1<CR>gv=gv")
u.vmap("K", ":m '<-2<CR>gv=gv")

-- yank into system clipboard
u.nmap("<leader>y", '"+y')
u.vmap("<leader>y", '"+y')
u.nmap("<leader>Y", '"+Y')

-- delete to void register
u.nmap("<leader>d", '"_d')
u.vmap("<leader>d", '"_d')
