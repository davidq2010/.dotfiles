return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "RRethy/vim-illuminate",
    "b0o/schemastore.nvim",
  },
  build = ":MasonUpdate",
  config = function()
    local u = require("utils")
    local lsp = vim.lsp
    local lspconfig = require("lspconfig")

    local default_on_attach = function(client, bufnr)
      -- Mappings
      -- See `:help vim.lsp.*` for documentation on any of the below functions
      -- https://github.com/neovim/nvim-lspconfig#suggested-configuration
      u.buf_map("n", "<space>K", vim.lsp.buf.hover, { desc = "Hover" }, bufnr)
      u.buf_map("n", "<space>k", vim.lsp.buf.signature_help, { desc = "Signature Help" }, bufnr)
      u.buf_map("n", "<space>gD", vim.lsp.buf.declaration, { desc = "Declaration" }, bufnr)
      u.buf_map("n", "<space>gd", vim.lsp.buf.definition, { desc = "Definition" }, bufnr)
      u.buf_map("n", "<space>gT", vim.lsp.buf.type_definition, { desc = "Type Definition" }, bufnr)
      u.buf_map("n", "<space>gr", vim.lsp.buf.references, { desc = "References" }, bufnr)
      u.buf_map("n", "<space>gi", vim.lsp.buf.implementation, { desc = "Implementation" }, bufnr)
      u.buf_map("n", "<space>wa", vim.lsp.buf.add_workspace_folder, { desc = "Add Workspace Folder" }, bufnr)
      u.buf_map("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove Workspace Folder" }, bufnr)
      u.buf_map("n", "<space>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, { desc = "List dir" }, bufnr)
      u.buf_map("n", "<space>rn", vim.lsp.buf.rename, { desc = "Rename" }, bufnr)
      u.buf_map("n", "<space>ca", vim.lsp.buf.code_action, { desc = "Code Action" }, bufnr)
      u.buf_map("n", "<space>f", function()
        vim.lsp.buf.format({ async = true })
      end, { desc = "Format" }, bufnr)

      require("illuminate").on_attach(client)
    end

    local opts = {
      on_attach = default_on_attach,
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
    }

    local servers = {
      "bashls",
      "clangd",
      "cssls",
      "jsonls",
      "omnisharp",
      "pyright",
      --'eslint',
      "lua_ls",
      "tsserver",
    }

    --local mason_status_ok, mason_lspconfig = pcall(require, "mason_lspconfig")
    require("mason").setup()
    local mason_lspconfig = require("mason-lspconfig")
    mason_lspconfig.setup({ ensure_installed = servers, automatic_installation = true })

    -- Use mason-lspconfig to auto setup LSP servers that were installed via mason without needing to manually
    -- configure each server's setup (via a nifty default handler).
    mason_lspconfig.setup_handlers({
      -- The first entry (without a key) will be the default handler
      -- and will be called for each installed server that doesn't have
      -- a dedicated handler.
      function(server_name) -- Default handler (optional)
        lspconfig[server_name].setup({
          on_attach = opts.on_attach,
          capabilities = opts.capabilities,
        })
      end,
      ["clangd"] = function()
        local updated_capabilities = opts.capabilities
        updated_capabilities.offsetEncoding = { "utf-16" }
        lspconfig["clangd"].setup({
          on_attach = opts.on_attach,
          capabilities = updated_capabilities,
        })
      end,
      ["lua_ls"] = function()
        lspconfig["lua_ls"].setup({
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
        lspconfig["pyright"].setup({
          on_attach = opts.on_attach,
          capabilities = opts.capabilities,

          settings = {
            python = {
              analysis = {
                -- Disable strict type checking
                typeCheckingMode = "off",
              },
            },
          },
        })
      end,
      ["jsonls"] = function()
        -- Find more schemas here: https://www.schemastore.org/json/
        lspconfig["jsonls"].setup({
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
  end,
}
