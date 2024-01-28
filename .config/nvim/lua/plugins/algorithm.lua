local leet_arg = "leetcode.nvim"
return {
  {
    "kawre/leetcode.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim", -- required by telescope
      "MunifTanjim/nui.nvim",

      -- optional
      "nvim-treesitter/nvim-treesitter",
      "rcarriga/nvim-notify",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = leet_arg ~= vim.fn.argv()[1],
    opts = {
      -- configuration goes here
      cn = { -- leetcode.cn
        enabled = true,
        translator = true,
        translate_problems = true,
      },
      arg = leet_arg,
      injector = {
        ["cpp"] = {
          before = { "#include <bits/stdc++.h>", "using namespace std;" },
          -- after = "int main() {}",
        },
        ["java"] = {
          before = "import java.util.*;",
        },
      },
      keys = {
        toggle = { "q" }, ---@type string|string[]
        confirm = { "<CR>" }, ---@type string|string[]

        reset_testcases = "r", ---@type string
        use_testcase = "U", ---@type string
        focus_testcases = "H", ---@type string
        focus_result = "L", ---@type string
      },
    },
    -- keys = {
    --   { "<leader>lr", "<cmd>Leet run<cr>", desc = "Leet run" },
    --   { "<leader>ls", "<cmd>Leet submit<cr>", desc = "Leet submit" },
    --   { "<leader>lt", "<cmd>Leet tabs<cr>", desc = "Leet tabs" },
    --   { "<leader>li", "<cmd>Leet info<cr>", desc = "Leet info" },
    --   { "<leader>lb", "<cmd>Leet list<cr>", desc = "Leet list" },
    --   { "<leader>lc", "<cmd>Leet console<cr>", desc = "Leet console" },
    -- },
  },

  {
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
  },
}
