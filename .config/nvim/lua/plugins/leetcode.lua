local leet_arg = "leetcode.nvim"
return {
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
  },
}