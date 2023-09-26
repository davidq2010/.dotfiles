return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local u = require("utils")
    local lsp = vim.lsp

    -- Diagnostic framework displays errors/warnings from external tools (e.g., linters, LSP servers)
    u.map("n", "<space>dp", vim.diagnostic.goto_prev, { desc = "GoTo Prev" })
    u.map("n", "<space>dn", vim.diagnostic.goto_next, { desc = "GoTo Next" })
    u.map("n", "<space>df", vim.diagnostic.open_float, { desc = "Open Float" })
    u.map("n", "<space>dq", vim.diagnostic.setqflist, { desc = "Add diagnostics to QuickFix List" }) -- Add all diagnostics to quickfix list
    u.map("n", "<space>dl", vim.diagnostic.setloclist, { desc = "Add diagnostics to location list" }) -- Add buffer diagnostics to location list

    -- Set non-default global diagnostic visualization config values
    vim.diagnostic.config({ virtual_text = false })

    -- border and focusable are options for lsp.handlers.hover/signature_help (see :nvim_open_win)
    local border_opts = { border = "single", focusable = false }

    -- https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization
    -- Use this to override default LSP settings. Here, we do it for all clients, but can also be done per client (see :help lsp.handlers)
    lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, border_opts)
    lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, border_opts)
  end,
}
