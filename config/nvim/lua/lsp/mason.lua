return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "RRethy/vim-illuminate",
    "b0o/schemastore.nvim",
  },
  build = ":MasonUpdate",
  opts = {
    PATH = "append",
  },
  config = function()
    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
      callback = function(event)
        local u = require("utils")
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
        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
            end,
          })
        end
      end,
    })

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local servers = {
      clangd = {
        capabilities = {
          offsetEncoding = { "utf-16" },
        },
      },
      jsonls = {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
          },
        },
      },
      pyright = {
        settings = {
          python = {
            analysis = {
              -- Disable strict type checking
              typeCheckingMode = "off",
            },
          },
        },
      },
      lua_ls = {
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
      },
      ruff = {
        cmd_env = { RUFF_TRACE = "messages" },
        init_options = {
          settings = {
            logLevel = "error",
          },
        },
      },
      ruff_lsp = {
        on_attach = function(client)
          if client.name == "ruff_lsp" then
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end
        end,
      },
    }

    --local mason_status_ok, mason_lspconfig = pcall(require, "mason_lspconfig")
    local ensure_installed = vim.tbl_keys(servers or {})
    -- Add other tools for Mason to install
    vim.list_extend(ensure_installed, {
      "bashls",
      "debugpy",
      "markdownlint",
      "stylua",
      "isort",
      "black",
      "tsserver",
    })

    require("mason").setup()
    require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
    local mason_lspconfig = require("mason-lspconfig")
    mason_lspconfig.setup({
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for tsserver)
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          require("lspconfig")[server_name].setup(server)
        end,
      },
    })
  end,
}
