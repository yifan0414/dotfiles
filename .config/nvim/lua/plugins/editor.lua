return {
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {
      auto_preview = false,
      focus = false,
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {}, -- this is equalent to setup({}) function
  },
  {
    "MunsMan/kitty-navigator.nvim",
    enabled = false,
    build = {
      "cp navigate_kitty.py ~/.config/kitty",
      "cp pass_keys.py ~/.config/kitty",
    },
    keys = {
      {
        "<C-h>",
        function()
          require("kitty-navigator").navigateLeft()
        end,
        desc = "Move left a Split",
        mode = { "n" },
      },
      {
        "<C-j>",
        function()
          require("kitty-navigator").navigateDown()
        end,
        desc = "Move down a Split",
        mode = { "n" },
      },
      {
        "<C-k>",
        function()
          require("kitty-navigator").navigateUp()
        end,
        desc = "Move up a Split",
        mode = { "n" },
      },
      {
        "<C-l>",
        function()
          require("kitty-navigator").navigateRight()
        end,
        desc = "Move right a Split",
        mode = { "n" },
      },
    },
  },
  {
    "christoomey/vim-tmux-navigator",
    enabled = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", silent = true, noremap = true },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", silent = true, noremap = true },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", silent = true, noremap = true },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", silent = true, noremap = true },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", silent = true, noremap = true },
    },
  },
  {
    "kawre/neotab.nvim",
    event = "InsertEnter",
    opts = {
      tabkey = "<tab>", -- for cmp
      act_as_tab = true,
      behavior = "nested", ---@type ntab.behavior
      pairs = { ---@type ntab.pair[]
        { open = "(", close = ")" },
        { open = "[", close = "]" },
        { open = "{", close = "}" },
        { open = "'", close = "'" },
        { open = '"', close = '"' },
        { open = "`", close = "`" },
        { open = "<", close = ">" },
      },
      exclude = {},
      smart_punctuators = {
        enabled = false,
        semicolon = {
          enabled = false,
          ft = { "cs", "c", "cpp", "java" },
        },
        escape = {
          enabled = false,
          triggers = {}, ---@type table<string, ntab.trigger>
        },
      },
    },
  },
  {
    -- 暂时把 o 模式去掉
    "chrisgrieser/nvim-spider",
    lazy = true,
    keys = {
      {
        "w",
        "<cmd>lua require('spider').motion('w')<CR>",
        mode = { "n", "x" },
      },
      { -- example for lazy-loading on keystroke
        "e",
        "<cmd>lua require('spider').motion('e')<CR>",
        mode = { "n", "x" },
      },
      { -- example for lazy-loading on keystroke
        "b",
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { "n", "x" },
      },
      { -- example for lazy-loading on keystroke
        "<C-f>",
        "<Esc>l<cmd>lua require('spider').motion('w')<CR>i",
        mode = { "i" },
      },
      { -- example for lazy-loading on keystroke
        "<C-b>",
        "<Esc><cmd>lua require('spider').motion('b')<CR>i",
        mode = { "i" },
      },
    },
  },
  {
    "chrisgrieser/nvim-various-textobjs",
    -- lazy = true,
    event = "VeryLazy",
    opts = {
      keymaps = {
        useDefaults = true,
      },
      -- useDefaultKeymaps = true,
      -- disabledKeymaps   = {
      --   "gc",
      -- },
    },
    keys = {
      {
        "af",
        '<cmd>lua require("various-textobjs").indentation("outer", "outer")<CR>',
        mode = { "o", "x" },
      },
    },
  },
  {
    "numToStr/Comment.nvim",
    -- event = "VeryLazy",
    keys = {
      { "gcc", mode = { "n" } },
      { "gbc", mode = { "n" } },
      { "gc", mode = { "x", "n" } },
    },
    -- event = { "BufReadPost", "BufNewFile" },
    opts = function()
      local commentstring_avail, commentstring = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
      return commentstring_avail and commentstring and { pre_hook = commentstring.create_pre_hook() } or {}
    end,
  },
  {
    "echasnovski/mini.align",
    version = false,
    keys = {
      { "ga", mode = { "x" } },
      { "gA", mode = { "x" } },
    },
    config = function()
      require("mini.align").setup()
    end,
  },
}
