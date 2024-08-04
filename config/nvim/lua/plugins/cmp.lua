return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdLineEnter" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp", -- nvim's built-in language server client w/more client capabilities (more types of completion candidates for language server's completion Requests)
    "hrsh7th/cmp-buffer", -- autocomplete from local buffer
    "hrsh7th/cmp-path", -- filepaths autocomplete
    "hrsh7th/cmp-cmdline", -- vim's cmdline
  },
  config = function()
    vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
    local cmp = require("cmp")
    local mapping = {
      ["<C-k>"] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), { "i", "c" }),
      ["<C-j>"] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), { "i", "c" }),
      ["<C-Space>"] = cmp.mapping({
        i = cmp.mapping.complete(),
        c = function()
          if cmp.visible() then
            if not cmp.confirm({ select = true }) then
              return
            end
          else
            cmp.complete()
          end
        end,
      }),
      ["<C-e>"] = cmp.mapping({
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      }),
      ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept mapping.currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }
    local cmd_search_mapping = {
      ["<C-k>"] = {
        c = function()
          if cmp.visible() then
            cmp.select_prev_item()
          end
        end,
      },
      ["<C-j>"] = {
        c = function()
          if cmp.visible() then
            cmp.select_next_item()
          end
        end,
      },
      ["<Tab>"] = {
        c = function()
          if cmp.visible() then
            cmp.select_next_item() -- SelectBehavior.Insert is default
            -- Somehow the following doesn't work, even though docs say they're equivalent...
            --cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select })
          end
        end,
      },
      ["<S-Tab>"] = {
        c = function()
          if cmp.visible() then
            cmp.select_prev_item()
          end
        end,
      },
    }
    local buffer_src_opts = {
      keyword_length = 3, -- num chars a word must have to appear in autocomplete
      get_bufnrs = function()
        -- complete from visible buffers: https://github.com/hrsh7th/cmp-buffer
        -- limit size of buffers read: https://github.com/hrsh7th/cmp-buffer#performance-on-large-text-files
        local bufs = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
          if byte_size <= 10485760 then
            -- Only use buffers that are less than 10MB
            bufs[vim.api.nvim_win_get_buf(win)] = true
          end
        end
        return vim.tbl_keys(bufs)
      end,
    }
    cmp.setup({
      completion = {
        -- show popup menu even when only 1 match
        -- do not insert text until user selects match in menu
        completeopt = "menuone,noinsert",
        autocomplete = false,
      },
      -- couple of diff ways to specify the mapping
      mapping = mapping,
      -- array of source config to use for completion menu's sort order (i.e., ORDER MATTERS)
      -- https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources
      sources = {
        { name = "nvim_lsp" },
        { name = "path" },
        {
          name = "buffer",
          keyword_length = 5, -- num chars typed to trigger autocomplete
          option = buffer_src_opts,
        },
      },
    })

    -- Using noice inistead
    --[[ -- In / cmdline mode, use a horizontal completion menu
    cmp.setup.cmdline("/", {
      view = {
        entries = { name = "wildmenu", separator = "|" },
      },
      mapping = cmd_search_mapping,
      sources = cmp.config.sources({
        { name = "buffer", option = buffer_src_opts },
      }),
    }) ]]

    --[[ -- : cmdline setup
    cmp.setup.cmdline(":", {
      view = {
        entries = { name = "custom" },
      },
      mapping = mapping,
      sources = cmp.config.sources({
        { name = "path" },
        { name = "cmdline", option = { keyword_length = 3 } },
      }),
    }) ]]
  end,
}
