return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/neotest-jest",
			"marilari88/neotest-vitest",
		},
		-- opts = { adapters = { "neotest-jest", "neotest-vitest" } },
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-jest"),
					require("neotest-vitest"),
				},
			})
		end,
	},
}
