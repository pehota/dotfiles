local lspconfig_plugin = require("plugins.configs.lspconfig")
local on_attach = lspconfig_plugin.on_attach
local capabilities = lspconfig_plugin.capabilities

---@diagnostic disable-next-line: different-requires
local lspconfig = require "lspconfig"
local servers = { "tsserver" , "marksman" , "elmls" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end


