return {
  {
    "hiphish/rainbow-delimiters.nvim",
    enabled = false,
    event = "LazyFile",
  },
  {
    "dstein64/vim-startuptime",
    enabled = false,
  },
  {
    "echasnovski/mini.icons",
    enabled = false,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "LazyFile",
    enabled = false,
    opts = function()
      return {
        indent = {
          char = "│",
          tab_char = "│",
        },
        scope = {
          enabled = false,
          show_start = false,
          show_end = false,
          -- injected_languages = false,
          -- highlight = highlight,
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
      }
    end,
    main = "ibl",
  },
  {
    "echasnovski/mini.indentscope",
    version = false,
    enabled = false,
    opts = {

      draw = {
        -- Delay (in ms) between event and start of drawing scope indicator
        -- delay = 100,

        -- Animation rule for scope's first drawing. A function which, given
        -- next and total step numbers, returns wait time (in ms). See
        -- |MiniIndentscope.gen_animation| for builtin options. To disable
        -- animation, use `require('mini.indentscope').gen_animation.none()`.
        animation = function()
          return 0
        end, --<function: implements constant 20ms between steps>,

        -- Symbol priority. Increase to display on top of more symbols.
        -- #806d9c
      },
    },
    config = function(_, opts)
      require("mini.indentscope").setup(opts)

      -- Disable for certain filetypes
      vim.api.nvim_create_autocmd({ "FileType" }, {
        desc = "Disable indentscope for certain filetypes",
        callback = function()
          local ignore_filetypes = {
            "aerial",
            "dashboard",
            "help",
            "lazy",
            "leetcode.nvim",
            "mason",
            "neo-tree",
            "NvimTree",
            "neogitstatus",
            "notify",
            "startify",
            "toggleterm",
            "Trouble",
            "CompetiTest",
            "Outline",
            "floaterm",
          }
          if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
            vim.b.miniindentscope_disable = true
          end
        end,
      })
    end,
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
    "RRethy/vim-illuminate",
    enabled = false,
    event = "LazyFile",
    opts = {
      -- delay = 100,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { "lsp" },
      },
      under_cursor = true,
      providers = { "regex" },
      filetypes_denylist = {
        "dirvish",
        "fugitive",
        "noice",
        "Outline",
        "help",
        "DiffviewFileHistory",
        "DiffviewFiles",
        "DiffviewViewPanel",
        "neo-tree",
        "CompetiTest",
        "floaterm",
        "dapui_scopes",
        "dapui_breakpoints",
        "dapui_stacks",
        "dapui_watches",
        "dapui_repl",
        "dapui_terminal",
      },
      modes_denylist = { "i", "v", "no", "V" },
      -- mode_allowlist = { "n" },
    },
    config = function(_, opts)
      -- vim.cmd([[hi illuminatedWord gui=none guibg=#2c313c]])
      -- vim.cmd([[hi illuminatedWordRead gui=none guibg=#2c313c]])
      -- vim.cmd([[hi illuminatedWordText gui=none guibg=#2c313c]])
      -- vim.cmd([[hi illuminatedWordWrite gui=none guibg=#2c313c]])
      -- vim.cmd([[hi illuminatedWord gui=none guibg=#45475a]])
      -- vim.cmd([[hi illuminatedWordRead gui=none guibg=#45475a]])
      -- vim.cmd([[hi illuminatedWordText gui=none guibg=#45475a]])
      -- vim.cmd([[hi illuminatedWordWrite gui=none guibg=#45475a]])
      require("illuminate").configure(opts)
    end,
    keys = {
      { "[[", false },
      { "]]", false },
    },
  },
  {
    "shellRaining/hlchunk.nvim",
    enabled = false,
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      chunk = {
        enable = true,
        notify = false,
        use_treesitter = true,
        -- details about support_filetypes and exclude_filetypes in https://github.com/shellRaining/hlchunk.nvim/blob/main/lua/hlchunk/utils/filetype.lua
        exclude_filetypes = {
          help = true,
          markdown = true,
          floaterm = true,
          ["leetcode.nvim"] = true,
          asm = true,
          git = true,
          CompetiTest = true,
        },
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = ">",
        },
        style = {
          { fg = "#806d9c" },
          { fg = "#806d9c" },
          -- { fg = "#c21f30" }, -- this fg is used to highlight wrong chunk
        },
        textobject = "q",
        max_file_size = 1024 * 1024,
        error_sign = false,
        delay = 0,
        duration = 0,
      },

      indent = {
        enable = true,
        use_treesitter = false,
        exclude_filetypes = {
          help = true,
          markdown = true,
          floaterm = true,
          ["leetcode.nvim"] = true,
          asm = true,
          git = true,
          CompetiTest = true,
        },
      },

      line_num = {
        enable = false,
        use_treesitter = false,
        style = "#806d9c",
      },

      blank = {
        enable = false,
        chars = {
          "․",
        },
        style = {
          vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui"),
        },
      },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
        keymaps = {
          insert = "<C-g>s",
          insert_line = "<C-g>S",
          normal = "ys",
          normal_cur = "yss",
          normal_line = "yS",
          normal_cur_line = "ySS",
          visual = "S",
          visual_line = "gS",
          delete = "ds",
          change = "cs",
          change_line = "cS",
        },
      })
    end,
  },
  {
    "folke/flash.nvim",
    enabled = false,
    opts = {
      label = {
        exclude = "able",
      },
      modes = {
        search = {
          enabled = false,
        },
        char = {
          enabled = false,
        },
      },
    },
    keys = {
      { "s", "cc" },
      -- {
      --   "S",
      --   mode = { "n", "x", "o" },
      --   function()
      --     require("flash").jump()
      --   end,
      --   desc = "Flash",
      -- },
    },
  },
  {
    "fladson/vim-kitty",
    ft = "kitty",
  },
}
