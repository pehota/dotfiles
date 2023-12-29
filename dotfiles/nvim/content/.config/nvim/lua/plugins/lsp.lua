return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = { eslint = {} },
      setup = {
        eslint = function()
          require("lazyvim.util").lsp.on_attach(function(client)
            if client.name == "eslint" then
              client.server_capabilities.documentFormattingProvider = true
            elseif client.name == "tsserver" then
              client.server_capabilities.documentFormattingProvider = false
            end
          end)
        end,
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- "actionlint",
        "bash-language-server",
        "dockerfile-language-server",
        "docker-compose-language-service",
        -- "elm-language-server",
        "eslint_d",
        -- "flake8", -- Python linter/formatter
        "lua-language-server",
        -- "rust-analyzer",
        -- "shellcheck",
        "shfmt",
        "sqlls",
        "sqlfluff",
        "stylua",
        "terraform-ls",
        "typescript-language-server",
        "yaml-language-server",
      },
      automatic_installation = true,
    },
  },
}
