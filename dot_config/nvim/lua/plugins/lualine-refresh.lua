return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- lualine polls on a permanent 16 ms timer (~60 wakeups/s idle, CPU temp +5C);
      -- 200 ms is not noticeable and cuts it to a few wakeups/s. 2026-11-17
      opts.options = opts.options or {}
      opts.options.refresh = vim.tbl_extend("force", opts.options.refresh or {}, { refresh_time = 200 })
    end,
  },
}
