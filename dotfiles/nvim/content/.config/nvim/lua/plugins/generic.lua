return {
	{
		"numToStr/BufOnly.nvim",
	},
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
					"dockerfile-language-server",
					"docker-compose-language-service",
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
					"sqlls",
					"sqlfluff",
				},
				automatic_installation = true,
			},
		},
		{
			"nvim-treesitter/nvim-treesitter",
			opts = {
				ensure_installed = {
					"bash",
					"c",
					"dockerfile",
					"hcl",
					"html",
					"javascript",
					"json",
					"json5",
					"jsonc",
					"lua",
					"luadoc",
					"luap",
					"markdown",
					"python",
					"query",
					"regex",
					"terraform",
					"tsx",
					"typescript",
					"vim",
					"vimdoc",
					"yaml",
				},
			},
		},
	},
}
