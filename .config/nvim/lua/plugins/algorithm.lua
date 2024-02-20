local leet_arg = "leetcode"
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
        focus_testcases = "<C-h>", ---@type string
        focus_result = "<C-l>", ---@type string
      },
    },
    keys = {
      { "<leader>lq", mode = { "n" }, "<cmd>Leet tabs<cr>" },
      { "<leader>lm", mode = { "n" }, "<cmd>Leet menu<cr>" },
      { "<leader>lc", mode = { "n" }, "<cmd>Leet console<cr>" },
      { "<leader>li", mode = { "n" }, "<cmd>Leet info<cr>" },
      { "<leader>ll", mode = { "n" }, "<cmd>Leet lang<cr>" },
      { "<leader>ld", mode = { "n" }, "<cmd>Leet desc<cr>" },
      { "<leader>lr", mode = { "n" }, "<cmd>Leet run<cr>" },
      { "<leader>ls", mode = { "n" }, "<cmd>Leet submit<cr>" },
      { "<leader>ly", mode = { "n" }, "<cmd>Leet yank<cr>" },
      { "<leader>lp", mode = { "n" }, "<cmd>Leet list<cr>" },
      { "<leader>lo", mode = { "n" }, "<cmd>Leet open<cr>" },
    },
    config = function(_, opts)
      require("leetcode").setup(opts)
      -- vim.keymap.set("n", "<leader>lr", "<cmd>Leet run<cr>", { desc = "Leet run" })
      -- vim.keymap.set("n", "<leader>ls", "<cmd>Leet submit<cr>", { desc = "Leet submit" })
      -- vim.keymap.set("n", "<leader>lt", "<cmd>Leet tabs<cr>", { desc = "Leet tabs" })
      -- vim.keymap.set("n", "<leader>li", "<cmd>Leet info<cr>", { desc = "Leet info" })
      -- vim.keymap.set("n", "<leader>lb", "<cmd>Leet list<cr>", { desc = "Leet list" })
      -- vim.keymap.set("n", "<leader>lc", "<cmd>Leet console<cr>", { desc = "Leet console" })
      vim.cmd([[
        autocmd VimEnter * hi leetcode_case_focus_ok cterm=bold gui=bold guifg=#1f1f28 guibg=#b3f6c0
        autocmd VimEnter * hi leetcode_case_ok cterm=bold gui=bold guifg=#b3f6c0 guibg=#1f1f28
        autocmd VimEnter * hi leetcode_case_focus_err cterm=bold gui=bold guifg=#1f1f28 guibg=#e82424
        autocmd VimEnter * hi leetcode_ok guifg=#b3f6c0
      ]])
    end,
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
      require("competitest").setup({
        received_problems_path = "$(CWD)/$(PROBLEM)/$(PROBLEM).$(FEXT)",
      })
    end,
  },
}
