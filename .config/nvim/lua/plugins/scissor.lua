return {
  {
    "chrisgrieser/nvim-scissors",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "L3MON4D3/LuaSnip",
    },

    keys = {
      {
        "<leader>se",
        mode = { "n" },
        function()
          require("scissors").editSnippet()
        end,
        desc = "Snippet: Edit",
      },
      {
        "<leader>sf",
        mode = { "n", "x" },
        function()
          require("scissors").addNewSnippet()
        end,
        desc = "Snippet: Add",
      },
    },
    opts = {
      snippetDir = vim.fn.stdpath("config") .. "/snippets",
    },
  },
}
