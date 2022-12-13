local lspconfig_plugin = require("plugins.configs.lspconfig")
local default_on_attach = lspconfig_plugin.on_attach
local capabilities = lspconfig_plugin.capabilities

---@diagnostic disable-next-line: different-requires
local lspconfig = require("lspconfig")
local servers = { "tsserver", "marksman", "elmls" }
local on_attach = function(client, buf)
	local is_client_null_ls = client.name == "null-ls"
	client.server_capabilities.documentFormattingProvider = is_client_null_ls
	return default_on_attach(client, buf)
end

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end
