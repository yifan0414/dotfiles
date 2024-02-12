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
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 500
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
    },
  },
  {
    "kawre/neotab.nvim",
    event = "InsertEnter",
    opts = {
      -- configuration goes here
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
    opts = { useDefaultKeymaps = true },
    keys = {
      {
        "af",
        '<cmd>lua require("various-textobjs").indentation("outer", "outer")<CR>',
        mode = { "o", "x" },
      },
    },
  },
  -- lazy.nvim
  -- minimal config for lazy-loading with lazy.nvim
  {
    "chrisgrieser/nvim-recorder",
    dependencies = "rcarriga/nvim-notify",
    keys = {
      -- these must match the keys in the mapping config below
      { "@", desc = " Start Recording" },
      { "Q", desc = " Play Recording" },
    },
    opts = {
      clear = true,
      mapping = {
        startStopRecording = "@",
        playMacro = "Q",
        addBreakPoint = "**",
      },
    },
    config = function(_, opts)
      require("recorder").setup(opts)
      local lualine = require("lualine").get_config().sections.lualine_x or {}
      table.insert(lualine, { require("recorder").recordingStatus, color = { fg = "#ff5d62" } })
      table.insert(lualine, { require("recorder").displaySlots, color = { fg = "#ff5d62" } })
      require("lualine").setup({
        sections = {
          lualine_x = lualine,
        },
      })
    end,
  },
}
