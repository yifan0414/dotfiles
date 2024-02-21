return {
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "LazyFile",
    enabled = false,
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = {
        enabled = false,
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
    "rcarriga/nvim-notify",
    opts = {
      fps = 60,
      stages = "static",
      max_width = 72,
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
      -- vim.cmd([[hi illuminatedWord gui=none guibg=#45475a]])
      -- vim.cmd([[hi illuminatedWordRead gui=none guibg=#45475a]])
      -- vim.cmd([[hi illuminatedWordText gui=none guibg=#45475a]])
      -- vim.cmd([[hi illuminatedWordWrite gui=none guibg=#45475a]])
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
    "shellRaining/hlchunk.nvim",
    -- enabled = false,
    event = { "VeryLazy" },
    opts = {
      chunk = {
        enable = true,
        notify = true,
        use_treesitter = false,
        -- details about support_filetypes and exclude_filetypes in https://github.com/shellRaining/hlchunk.nvim/blob/main/lua/hlchunk/utils/filetype.lua
        exclude_filetypes = {
          help = true,
          markdown = true,
          floaterm = true,
          ["leetcode.nvim"] = true,
          asm = true,
        },
        chars = {
          -- horizontal_line = "─",
          vertical_line = "│",
          -- left_top = "╭",
          -- left_bottom = "╰",
          -- right_arrow = ">",
        },
        style = {
          { fg = "#806d9c" },
          { fg = "#c21f30" }, -- this fg is used to highlight wrong chunk
        },
        textobject = "q",
        max_file_size = 1024 * 1024,
        error_sign = true,
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
        },
        chars = {
          "│",
        },
        style = {
          { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") },
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
}
