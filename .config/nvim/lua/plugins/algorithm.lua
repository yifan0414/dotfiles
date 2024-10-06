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
        translator = false,
        translate_problems = false,
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
      description = {
        position = "left", ---@type lc.position

        width = "50%", ---@type lc.size

        show_stats = true, ---@type boolean
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
    config = function(_, opts)
      require("leetcode").setup(opts)
      vim.keymap.set("n", "<leader>lr", "<cmd>Leet run<cr>")
      vim.keymap.set("n", "<leader>ls", "<cmd>Leet submit<cr>")
      vim.keymap.set("n", "<leader>lt", "<cmd>Leet tabs<cr>")
      vim.keymap.set("n", "<leader>li", "<cmd>Leet info<cr>")
      vim.keymap.set("n", "<leader>lb", "<cmd>Leet list<cr>")
      vim.keymap.set("n", "<leader>lc", "<cmd>Leet console<cr>")
      vim.keymap.set("n", "<leader>lq", "<cmd>Leet tabs<cr>")
      vim.keymap.set("n", "<leader>lm", "<cmd>Leet menu<cr>")
      vim.keymap.set("n", "<leader>ll", "<cmd>Leet list<cr>")
      vim.keymap.set("n", "<leader>ld", "<cmd>Leet desc<cr>")
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
    -- init = function()
    --   vim.cmd([[
    --     autocmd VimEnter * hi CompetiTestCorrect cterm=bold gui=bold guifg=#b3f6c0
    --   ]])
    -- end,
    keys = {
      { "<leader>1", "<cmd>CompetiTest run<cr><c-w>h", desc = "Run TestCase" },
      { "<leader>2", "<cmd>CompetiTest add_testcase<cr>", desc = "Add TestCase" },
      { "<leader>3", "<cmd>CompetiTest edit_testcase<cr>", desc = "Edit TestCase" },
      { "<leader>rd", "<cmd>CompetiTest delete_testcase<cr>", desc = "Delete TestCase" },
      { "<leader>rs", "<cmd>CompetiTest show_ui<cr>", desc = "Show UI" },
      { "<leader>rc", "<cmd>CompetiTest receive problem<cr>", desc = "Receive Problem" },
    },
    config = function()
      require("competitest").setup({
        compile_command = {
          c = { exec = "gcc", args = { "-Wall", "$(FNAME)", "-o", "$(FNOEXT)" } },
          cpp = { exec = "g++", args = { "-Wall", "-std=c++20", "$(FNAME)", "-o", "$(FNOEXT)" } },
          rust = { exec = "rustc", args = { "$(FNAME)" } },
          java = { exec = "javac", args = { "$(FNAME)" } },
        },
        received_problems_path = "$(CWD)/$(PROBLEM)/$(PROBLEM).$(FEXT)",
        testcases_use_single_file = false,
        runner_ui = {
          interface = "split",
        },
        split_ui = {
          position = "right",
          relative_to_editor = true,
          total_width = 0.4,
          vertical_layout = {
            { 1, "tc" },
            { 1, { { 1, "so" }, { 1, "eo" } } },
            { 1, { { 1, "si" }, { 1, "se" } } },
          },
          total_height = 0.4,
          horizontal_layout = {
            { 2, "tc" },
            { 3, { { 1, "so" }, { 1, "si" } } },
            { 3, { { 1, "eo" }, { 1, "se" } } },
          },
        },
      })
    end,
  },
}
