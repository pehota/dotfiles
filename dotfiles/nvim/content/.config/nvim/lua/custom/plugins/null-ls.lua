local present, null_ls = pcall(require, "null-ls")
print("getting lua")

if not present then
	return
end

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local builtin_formatters = null_ls.builtins

local sources = {

	-- webdev stuff
	builtin_formatters.code_actions.eslint_d,
	builtin_formatters.formatting.prettier,
	builtin_formatters.formatting.prettier,

	-- Lua
	builtin_formatters.formatting.stylua,

	-- Shell
	builtin_formatters.formatting.shfmt,
	builtin_formatters.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),
}

null_ls.setup({
	debug = true,
	sources = sources,
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
					vim.lsp.buf.formatting_sync()
				end,
			})
		end
	end,
})
