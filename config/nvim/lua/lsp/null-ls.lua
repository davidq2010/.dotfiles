-- For ref: https://github.com/josean-dev/dev-environment-files/blob/main/.config/nvim/lua/josean/plugins/lsp/null-ls.lua
return {
	"jose-elias-alvarez/null-ls.nvim", -- configure formatters & linters
	event = { "BufReadPre", "BufNewfile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local null_ls = require("null-ls")
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

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.diagnostics.pylint,
				null_ls.builtins.diagnostics.cppcheck.with({
					extra_args = { "--std=c++20", "--language=c++" },
				}),
				null_ls.builtins.diagnostics.eslint,
				null_ls.builtins.diagnostics.shellcheck,
				-- require("null-ls").builtins.completion.spell,
			},
			on_attach = function(client, bufnr)
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
		})
	end
}
