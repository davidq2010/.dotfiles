local u = require("utils")

local lsp = vim.lsp

-- Diagnostic framework displays errors/warnings from external tools (e.g., linters, LSP servers)
u.map("n", "<space>dp", "<cmd>lua vim.diagnostic.goto_prev()<CR>", nil)
u.map("n", "<space>dn", "<cmd>lua vim.diagnostic.goto_next()<CR>", nil)
u.map("n", "<space>df", "<cmd>lua vim.diagnostic.open_float()<CR>", nil)
u.map("n", "<space>dq", "<cmd>lua vim.diagnostic.setqflist()<CR>", nil) -- Add all diagnostics to quickfix list
u.map("n", "<space>dl", "<cmd>lua vim.diagnostic.setloclist()<CR>", nil) -- Add buffer diagnostics to location list

-- Set non-default global diagnostic visualization config values
vim.diagnostic.config({ virtual_text = false })

-- border and focusable are options for lsp.handlers.hover/signature_help (see :nvim_open_win)
local border_opts = { border = "single", focusable = false }

-- This is one of the ways we can set lsp handlers (see :help lsp.handlers)
lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, border_opts)
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, border_opts)

local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
        filter = function(client)
            -- apply whatever logic you want (in this example, we'll only use null-ls)
            -- https://github.com/jose-elias-alvarez/null-ls.nvim#how-do-i-stop-neovim-from-asking-me-which-server-i-want-to-use-for-formatting
            -- https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Avoiding-LSP-formatting-conflicts
            return client.name == "null-ls"
        end,
        bufnr = bufnr,
    })
end

-- if you want to set up formatting on save, you can use this as a callback
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local default_on_attach = function(client, bufnr)
	-- Mappings
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	-- https://github.com/neovim/nvim-lspconfig#suggested-configuration
	u.buf_map("n", "<space>K", "<cmd>lua vim.lsp.buf.hover()<CR>", nil, bufnr)
	u.buf_map("n", "<space>k", "<cmd>lua vim.lsp.buf.signature_help()<CR>", nil, bufnr)
	u.buf_map("n", "<space>gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", nil, bufnr)
	u.buf_map("n", "<space>gd", "<cmd>lua vim.lsp.buf.definition()<CR>", nil, bufnr)
	u.buf_map("n", "<space>gT", "<cmd>lua vim.lsp.buf.type_definition()<CR>", nil, bufnr)
	u.buf_map("n", "<space>gr", "<cmd>lua vim.lsp.buf.references()<CR>", nil, bufnr)
	u.buf_map("n", "<space>gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", nil, bufnr)
	u.buf_map("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", nil, bufnr)
	u.buf_map("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", nil, bufnr)
	u.buf_map("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", nil, bufnr)
	u.buf_map("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", nil, bufnr)
	u.buf_map("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", nil, bufnr)
	u.buf_map("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", nil, bufnr)

	require("illuminate").on_attach(client)
    if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
                lsp_formatting(bufnr)
            end,
        })
    end
end

local opts = {
    on_attach = default_on_attach,
    capabilities = vim.lsp.protocol.make_client_capabilities()
}
opts.capabilities = require("cmp_nvim_lsp").update_capabilities(opts.capabilities)

--local mason_status_ok, mason_lspconfig = pcall(require, "mason_lspconfig")
local mason_lspconfig = require("mason-lspconfig")
mason_lspconfig.setup({ ensure_installed = servers, automatic_installation = true })

local servers = {
    "bashls",
    "clangd",
	'cssls',
	"jsonls",
    "omnisharp",
	"pyright",
	--'eslint',
	"sumneko_lua",
	'tsserver'
}

mason_lspconfig.setup_handlers({
    -- The first entry (without a key) will be the default handler
    -- and will be called for each installed server that doesn't have
    -- a dedicated handler.
    function(server_name) -- Default handler (optional)
        require('lspconfig')[server_name].setup {
            on_attach = opts.on_attach,
            capabilities = opts.capabilities,
        }
    end,
    ["sumneko_lua"] = function()
        require('lspconfig')['sumneko_lua'].setup({
            on_attach = opts.on_attach,
            capabilities = opts.capabilities,
            settings = {
                Lua = {
                    -- Tells Lua that a global variable named vim exists to not have warnings when configuring neovim
                    diagnostics = {
                    globals = { "vim" },
                    },
                    workspace = {
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                        },
                    },
                },
            },
        })
    end,
    ["pyright"] = function()
        require('lspconfig')['pyright'].setup({
            on_attach = opts.on_attach,
            capabilities = opts.capabilities,

            settings = {
                python = {
                    analysis = {
                        -- Disable strict type checking
                        typeCheckingMode = "off"
                    }
                }
            },
        })
    end,
    ["jsonls"] = function()
        -- Find more schemas here: https://www.schemastore.org/json/
        require('lspconfig')['jsonls'].setup({
            on_attach = opts.on_attach,
            capabilities = opts.capabilities,

            settings = {
                json = {
                    schemas = require("schemastore").json.schemas(),
                },
            },
        })
    end,
})
