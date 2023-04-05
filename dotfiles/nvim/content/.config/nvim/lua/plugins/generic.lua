return {
	{
		"echasnovski/mini.indentscope",
		opts = {
			draw = {
				delay = 0,
				animate = function()
					return 0
				end,
			},
		},
	},
	{
		-- UI changes such as having floating notifications, a floating command line, etc
		"folke/noice.nvim",
		opts = {
			messages = {
				enabled = false,
			},
		},
		{
			"williamboman/mason.nvim",
			opts = {
				ensure_installed = {
					"actionlint",
					"bash-language-server",
					"elm-language-server",
					"eslint_d",
					"flake8",
					-- "json-lsp",
					"lua-language-server",
					"node-debug2-adapter",
					-- "prettierd",
					"rust-analyzer",
					"shellcheck",
					"shfmt",
					"stylua",
					"terraform-ls",
					-- "typescript-language-server",
				},
			},
		},
		{
			"jose-elias-alvarez/null-ls.nvim",
			opts = function()
				local null_ls = require("null-ls")
				return {
					sources = {
						null_ls.builtins.formatting.prettierd,
						null_ls.builtins.formatting.stylua,
						null_ls.builtins.formatting.shfmt,
						null_ls.builtins.diagnostics.flake8,
					},
				}
			end,
		},
	},
}
