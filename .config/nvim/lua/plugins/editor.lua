return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {}, -- this is equalent to setup({}) function
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "LazyFile",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = {
        enabled = true,
        show_start = false,
        show_end = false,
        injected_languages = false,
        highlight = { "Function", "Label" },
        priority = 500,
      },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    },
    main = "ibl",
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
    "lukas-reineke/headlines.nvim",
    enabled = false,
    opts = function()
      local opts = {}
      for _, ft in ipairs({ "markdown", "norg", "rmd", "org" }) do
        opts[ft] = {
          headline_highlights = { "Headline" },
          fat_headline_lower_string = "▀",
        }
        for i = 1, 6 do
          local hl = "Headline" .. i
          vim.api.nvim_set_hl(0, hl, { link = "Headline", default = true })
          table.insert(opts[ft].headline_highlights, hl)
        end
      end
      return opts
    end,
    ft = { "markdown", "norg", "rmd", "org" },
    config = function(_, opts)
      -- PERF: schedule to prevent headlines slowing down opening a file
      vim.schedule(function()
        require("headlines").setup(opts)
        require("headlines").refresh()
      end)
    end,
  },
  {
    "hotoo/pangu.vim",
    -- config = function()
    --   vim.api.nvim_create_autocmd("BufWritePre", {
    --     pattern = { "*.markdown", "*.md", "*.text", "*.txt", "*.wiki", "*.cnx" },
    --     callback = function()
    --       vim.call("PanGuSpacing", "ALL")
    --     end,
    --   })
    -- end,
    ft = { "markdown", "norg", "rmd", "org" },
  },
  {
    "kawre/neotab.nvim",
    event = "InsertEnter",
    opts = {
      -- configuration goes here
    },
  },
  {
    "RRethy/vim-illuminate",
    event = "LazyFile",
    opts = {
      delay = 100,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { "lsp" },
      },
      under_cursor = false,
      providers = { "regex" },
      filetypes_denylist = {
        "dirvish",
        "fugitive",
        "noice",
        "outline",
      },
    },
    config = function(_, opts)
      vim.cmd([[hi illuminatedWord gui=none guibg=#2c313c]])
      vim.cmd([[hi illuminatedWordRead gui=none guibg=#2c313c]])
      vim.cmd([[hi illuminatedWordText gui=none guibg=#2c313c]])
      vim.cmd([[hi illuminatedWordWrite gui=none guibg=#2c313c]])
      require("illuminate").configure(opts)

      local function map(key, dir, buffer)
        vim.keymap.set("n", key, function()
          require("illuminate")["goto_" .. dir .. "_reference"](true)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
      end

      map("]]", "next")
      map("[[", "prev")

      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map("]]", "next", buffer)
          map("[[", "prev", buffer)
        end,
      })
    end,
    keys = {
      { "]]", desc = "Next Reference" },
      { "[[", desc = "Prev Reference" },
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
  },
  -- lazy.nvim
  -- minimal config for lazy-loading with lazy.nvim
  {
    "chrisgrieser/nvim-recorder",
    dependencies = "rcarriga/nvim-notify",
    keys = {
      -- these must match the keys in the mapping config below
      { "q", desc = " Start Recording" },
      { "Q", desc = " Play Recording" },
    },
    config = function()
      require("recorder").setup({
        clear = true,
        mapping = {
          startStopRecording = "q",
          playMacro = "Q",
          addBreakPoint = "**",
        },
      })

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
  -- {
  --   "chrisgrieser/nvim-scissors",
  --   dependencies = "nvim-telescope/telescope.nvim", -- optional
  --   opts = {
  --     snippetDir = "~/.config/nvim/snippets",
  --   },
  -- },
}
