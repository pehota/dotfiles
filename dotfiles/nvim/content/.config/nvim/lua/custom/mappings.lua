local M = {}

M.global = {
  n = {
    ["<leader>bd"] = { "<cmd>bufdo bd<CR>", "delete all buffers"}
  }

}

M.telescope = {
  n = {
    ["<C-p>"] = { "<cmd> Telescope find_files <CR>", "find files" },
    ["<leader>f"] = { "<cmd> Telescope live_grep <C-R><C-W><CR>", "grep text under cursor" },
  }
}

M.nvimtree = {
  n = {
    ["<leader>d"] = { "<cmd> NvimTreeToggle <CR>", "toggle file tree" },
    -- ["<leader>l"] = { "<cmd> NvimTreeFindFile <CR>", "locate file in file tree" }
  }
}

M.lspconfig = {
  n = {
    ["gy"] = {
      function()
        vim.lsp.buf.type_definition()
      end,
      "lsp definition type",
    },
    ["[w"] = {
      function()
        vim.lsp.diagnostic.goto_prev()
      end,
      "lsp go to previous diagnostic issue"
    },
    ["]w"] = {
      function()
        vim.lsp.diagnostic.goto_next()
      end,
      "lsp go to next diagnostic issue"
    },
    ["<leader>rn"] = {
      function()
        require("nvchad_ui.renamer").open()
      end,
      'lsp rename symbol'
    },
    ["<localleader>a"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "lsp code action",
    },
  }
}

M.disabled = {
  n = {
    ["<leader>D"] = "",
    ["<S-b>"] = "",
    ["<C-n>"] = "",
    ["<C-c>"] = "",
    ["<C-r>"] = "",
    ["K"] = "",
    ["<leader>ff"] = "",
    ["<leader>ra"] = "",
    ["<leader>rn"] = ""
  }
}

return M
