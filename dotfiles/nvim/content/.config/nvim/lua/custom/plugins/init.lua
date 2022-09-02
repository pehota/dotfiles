local M = {}

M.user = {
  ["neovim/nvim-lspconfig"] = {
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.lspconfig"
    end,
  },
  ["jose-elias-alvarez/null-ls.nvim"] = {
    after = "nvim-lspconfig",
    config = function()
      require "custom.plugins.null-ls"
    end,
  },
  ["williamboman/mason.nvim"] = {
    ensure_installed = {
      -- lua stuff
      "lua-language-server",
      "stylua",

      -- web dev
      "css-lsp",
      "html-lsp",
      "typescript-language-server",
      "deno",
      "emmet-ls",
      "json-lsp",

      -- shell
      "shfmt",
      "shellcheck",

      -- Elm
      "elm-language-server",
      "elm-format",
      "elm-test",

      -- bash
      "bash-language-server",

      "eslint_d",

      "prettierd"
    },
  },
  ["unblevable/quick-scope"] = {},
  ["tpope/vim-surround"] = {}
}

return M
