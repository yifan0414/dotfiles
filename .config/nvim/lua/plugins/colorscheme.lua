return {
  {
    "EdenEast/nightfox.nvim",
    enabled = false,
    config = function()
      -- Default options
      require("nightfox").setup({
        options = {
          -- Compiled file's destination location
          compile_path = vim.fn.stdpath("cache") .. "/nightfox",
          compile_file_suffix = "_compiled", -- Compiled file suffix
          transparent = false, -- Disable setting background
          terminal_colors = false, -- Set terminal colors (vim.g.terminal_color_*) used in `:terminal`
          dim_inactive = false, -- Non focused panes set to alternative background
          module_default = true, -- Default enable value for modules
          colorblind = {
            enable = false, -- Enable colorblind support
            simulate_only = false, -- Only show simulated colorblind colors and not diff shifted
            severity = {
              protan = 0, -- Severity [0,1] for protan (red)
              deutan = 0, -- Severity [0,1] for deutan (green)
              tritan = 0, -- Severity [0,1] for tritan (blue)
            },
          },
          styles = { -- Style to be applied to different syntax groups
            comments = "NONE", -- Value is any valid attr-list value `:help attr-list`
            conditionals = "NONE",
            constants = "NONE",
            functions = "bold",
            keywords = "NONE",
            numbers = "NONE",
            operators = "NONE",
            strings = "NONE",
            types = "NONE",
            variables = "NONE",
          },
          inverse = { -- Inverse highlight for different types
            match_paren = false,
            visual = false,
            search = false,
          },
          modules = { -- List of various plugins and additional options
            -- ...
          },
        },
        palettes = {},
        specs = {},
        groups = {},
      })
    end,
  }, -- lazy
  {
    "yifan0414/kanagawa.nvim",
    enabled = true,
    opts = {
      compile = true, -- 如果修改内容，记得要重新编译
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      keywordStyle = { italic = true },
      functionStyle = { italic = true, bold = true },
      commentStyle = { italic = false },
      terminalColors = false,
      overrides = function(colors)
        local theme = colors.theme
        local makeDiagnosticColor = function(color)
          local c = require("kanagawa.lib.color")
          return { fg = color, bg = c(color):blend(theme.ui.bg, 0.95):to_hex() }
        end

        return {
          NormalFloat = { fg = colors.palette.lotusGray, bg = colors.palette.sumiInk3 },
          FloatBorder = { fg = colors.palette.sumiInk6, bg = colors.palette.sumiInk3 },
          TreesitterContextLineNumber = { bg = colors.palette.sumiInk4 },

          Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1, blend = 0 }, -- add `blend = vim.o.pumblend` to enable transparency
          PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
          PmenuSbar = { bg = theme.ui.bg_m1 },
          PmenuThumb = { bg = theme.ui.bg_p2 },

          CmpItemKindText = { fg = colors.palette.carpYellow },
          CmpItemKindVariable = { fg = colors.palette.carpYellow },

          -- Diagnostic
          DiagnosticVirtualTextHint = makeDiagnosticColor(theme.diag.hint),
          DiagnosticVirtualTextInfo = makeDiagnosticColor(theme.diag.info),
          DiagnosticVirtualTextWarn = makeDiagnosticColor(theme.diag.warning),
          DiagnosticVirtualTextError = makeDiagnosticColor(theme.diag.error),

          -- navic
          WinBar = { bg = colors.palette.sumiInk4 },
          WinBarNc = { bg = colors.palette.sumiInk4 },
          lualine_a_inactive = { bg = colors.palette.sumiInk3 },
          lualine_b_inactive = { bg = colors.palette.sumiInk3 },
          lualine_c_inactive = { bg = colors.palette.sumiInk3 },

          -- algorithm
          CompetiTestCorrect = { fg = colors.palette.springGreen },
          CompetiTestWrong = { fg = colors.palette.waveRed },

          -- cmp
          CmpItemAbbrMatch = { fg = "#7fb4ca" },
          CmpItemAbbrMatchFuzzy = { fg = "#7fb4ca" },

          -- match
          MatchParen = { bg = "#45475a" },

          -- telescope
          -- TelescopeTitle = { fg = theme.ui.special, bold = true },
          TelescopePromptNormal = { bg = theme.ui.bg_p1 },
          TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
          TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
          TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
          TelescopePreviewNormal = { bg = theme.ui.bg_dim },
          TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
          -- TelescopePreviewTitle = {
          --   fg = O.transparent_background and C.green or C.base,
          --   bg = O.transparent_background and C.none or C.green,
          -- },
          -- TelescopePromptTitle = {
          --   fg = O.transparent_background and C.red or C.base,
          --   bg = O.transparent_background and C.none or C.red,
          -- },
          -- TelescopeResultsTitle = {
          --   fg = O.transparent_background and C.lavender or C.mantle,
          --   bg = O.transparent_background and C.none or C.lavender,
          -- },

          -- Snack Notifier
          SnacksNotifierError = { fg = theme.diag.error },
        }
      end,
    },
    -- branch = "dev",
    -- commit = "476eb2289d47d132ebacc1a4d459e3204866599b"
  },
  {
    "ellisonleao/gruvbox.nvim",
    enabled = false,
    lazy = true,
  },
  {
    "catppuccin/nvim",
    lazy = true,
    enabled = false,
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        flavour = "auto", -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = "latte",
          dark = "frappe",
        },
        transparent_background = false, -- disables setting the background color.
        show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
        term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
        dim_inactive = {
          enabled = false, -- dims the background color of inactive window
          shade = "dark",
          percentage = 0.15, -- percentage of the shade to apply to the inactive window
        },
        no_italic = false, -- Force no italic
        no_bold = false, -- Force no bold
        no_underline = false, -- Force no underline
        styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
          comments = {}, -- Change the style of comments
          conditionals = { "italic" },
          loops = { "italic" },
          functions = { "italic", "bold" },
          keywords = { "italic" },
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
          -- miscs = {}, -- Uncomment to turn off hard-coded styles
        },
        color_overrides = {},
        highlight_overrides = {
          -- all = function(colors)
          --   return {
          --     TreesitterContext = { bg = colors.mantle },
          --     NormalFloat = { bg = colors.base },
          --     FloatBorder = { bg = colors.base },
          --   }
          -- end,
          frappe = function(frappe)
            return {
              NavicText = { fg = "#c6d0f6" },
              WinBar = { bg = frappe.mantle },
              TreesitterContext = { bg = frappe.mantle },
              NormalFloat = { bg = frappe.base },
              FloatBorder = { bg = frappe.base },
              ["@function.builtin"] = { fg = frappe.blue, bold = true },
              ["@type.builtin.cpp"] = { fg = frappe.mauve },
              ["@type.cpp"] = { fg = frappe.mauve },
              CompetiTestCorrect = { bold = true, fg = frappe.green },
              CompetiTestWrong = { bold = true, fg = frappe.red },
            }
          end,
          mocha = function(mocha)
            return {
              TreesitterContext = { bg = mocha.mantle },
              NormalFloat = { bg = mocha.base },
              FloatBorder = { bg = mocha.base },
              CompetiTestCorrect = { bold = true, fg = mocha.green },
              CompetiTestWrong = { bold = true, fg = mocha.red },
            }
          end,
          latte = function(latte)
            return {
              NavicText = { fg = "#4c4f6a" },
              WinBar = { bg = latte.mantle },
              TreesitterContext = { bg = latte.mantle },
              NormalFloat = { bg = latte.base },
              FloatBorder = { bg = latte.base },
              ["@function.builtin"] = { fg = latte.blue, bold = true },
              ["@type.builtin.cpp"] = { fg = latte.mauve },
              ["@type.cpp"] = { fg = latte.mauve },
              ["@lsp.type.class.cpp"] = { bold = true },
              CompetiTestCorrect = { bold = true, fg = latte.green },
              CompetiTestWrong = { bold = true, fg = latte.red },
            }
          end,
        },
        custom_highlights = {
          snackchunk = { fg = "#806d9c" },
        },
        default_integrations = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          treesitter_context = true,
          mini = {
            enabled = true,
            indentscope_color = "",
          },
          overseer = true,
          navic = {
            enabled = true,
            custom_bg = "NONE", -- "lualine" will set background to mantle
          },
          snacks = true,
          which_key = false,
          dashboard = true,
          flash = true,
          fzf = true,
          lsp_trouble = false,
          mason = true,
          markdown = false,
          neotest = true,
          neotree = true,
          noice = true,
          semantic_tokens = true,
          blink_cmp = true,
          rainbow_delimiters = true,
          render_markdown = true,
          telescope = {
            enabled = true,
            style = "nvchad",
          },
          -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
        },
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
      -- colorscheme = "catppuccin-frappe",
      -- colorscheme = "catppuccin-latte",
      -- colorscheme = "dawnfox",
      -- colorscheme = "vscode",
    },
  },
}
