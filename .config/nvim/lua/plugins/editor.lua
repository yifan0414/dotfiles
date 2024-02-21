return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {}, -- this is equalent to setup({}) function
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  {
    "folke/which-key.nvim",
    -- event = "VeryLazy",
    lazy = true,
    config = function(_, opts)
      vim.o.timeout = true
      vim.o.timeoutlen = 500
      require("which-key").setup(opts)
    end,
    opts = {
      triggers_nowait = {
        -- marks
        -- "`",
        -- "'",
        "g`",
        "g'",
        -- registers
        '"',
        "<c-r>",
        -- spelling
        "z=",
      },
      -- plugins = {
      --   presets = {
      --     operators = false,
      --   },
      -- },
      window = {
        border = "single",
      },
      -- defaults = {
      --   ["<leader>te"] = { name = "+telescope" },
      -- },
    },
  },
  {
    "kawre/neotab.nvim",
    event = "InsertEnter",
    opts = {
      tabkey = "",
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
      useDefaultKeymaps = true,
      disabledKeymaps = {
        "gc",
      },
    },
    keys = {
      {
        "af",
        '<cmd>lua require("various-textobjs").indentation("outer", "outer")<CR>',
        mode = { "o", "x" },
      },
    },
  },
}
