return {
  "xeluxee/competitest.nvim",
  dependencies = "MunifTanjim/nui.nvim",
  -- event = "VeryLazy",
  cmd = "CompetiTest",
  keys = {
    { "<leader>rr", "<cmd>CompetiTest run<cr>", desc = "Run TestCase" },
    { "<leader>ra", "<cmd>CompetiTest add_testcase<cr>", desc = "Add TestCase" },
    { "<leader>re", "<cmd>CompetiTest edit_testcase<cr>", desc = "Edit TestCase" },
    { "<leader>rd", "<cmd>CompetiTest delete_testcase<cr>", desc = "Delete TestCase" },
    { "<leader>rs", "<cmd>CompetiTest show_ui<cr>", desc = "Show UI" },
    { "<leader>rc", "<cmd>CompetiTest receive problem<cr>", desc = "Receive Problem" },
  },
  config = function()
    require("competitest").setup()
  end,
}
