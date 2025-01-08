return {
  {
    "stevearc/conform.nvim",
    -- optional = true,
    opts = {
      formatters_by_ft = {
        ["java"] = { "google-java-format" },
        ["markdown"] = { "pangu" },
        ["zsh"] = { "shfmt" },
      },
    },
  },
  -- {
  --   "danymat/neogen",
  --   -- event = "VeryLazy",
  --   cmd = "Neogen",
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  --   config = true,
  --   -- Uncomment next line if you want to follow only stable versions
  --   -- version = "*"
  --   keys = {
  --     { "gcf", "<cmd>Neogen func<cr>", mode = { "n" } },
  --   },
  -- },
}
