return {
  -- {
  --   "EdenEast/nightfox.nvim",
  --   enabled = false,
  --   config = function()
  --     -- Default options
  --     require("nightfox").setup({
  --       options = {
  --         -- Compiled file's destination location
  --         compile_path = vim.fn.stdpath("cache") .. "/nightfox",
  --         compile_file_suffix = "_compiled", -- Compiled file suffix
  --         transparent = false, -- Disable setting background
  --         terminal_colors = false, -- Set terminal colors (vim.g.terminal_color_*) used in `:terminal`
  --         dim_inactive = false, -- Non focused panes set to alternative background
  --         module_default = true, -- Default enable value for modules
  --         colorblind = {
  --           enable = false, -- Enable colorblind support
  --           simulate_only = false, -- Only show simulated colorblind colors and not diff shifted
  --           severity = {
  --             protan = 0, -- Severity [0,1] for protan (red)
  --             deutan = 0, -- Severity [0,1] for deutan (green)
  --             tritan = 0, -- Severity [0,1] for tritan (blue)
  --           },
  --         },
  --         styles = { -- Style to be applied to different syntax groups
  --           comments = "NONE", -- Value is any valid attr-list value `:help attr-list`
  --           conditionals = "NONE",
  --           constants = "NONE",
  --           functions = "bold",
  --           keywords = "NONE",
  --           numbers = "NONE",
  --           operators = "NONE",
  --           strings = "NONE",
  --           types = "NONE",
  --           variables = "NONE",
  --         },
  --         inverse = { -- Inverse highlight for different types
  --           match_paren = false,
  --           visual = false,
  --           search = false,
  --         },
  --         modules = { -- List of various plugins and additional options
  --           -- ...
  --         },
  --       },
  --       palettes = {},
  --       specs = {},
  --       groups = {},
  --     })
  --   end,
  -- }, -- lazy
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
      keywordStyle = { italic = false, bold = false },
      functionStyle = { italic = true, bold = true},
      commentStyle = { italic = true, bold = true },
      terminalColors = false,
      overrides = function(colors)
        local theme = colors.theme
        -- local makeDiagnosticColor = function(color)
        --   local c = require("kanagawa.lib.color")
        --   return { fg = color, bg = c(color):blend(theme.ui.bg, 0.95):to_hex() }
        -- end

        return {
          NormalFloat = { fg = colors.palette.lotusGray, bg = colors.palette.sumiInk3 },
          FloatBorder = { fg = colors.palette.sumiInk6, bg = colors.palette.sumiInk3 },
          TreesitterContextLineNumber = { bg = colors.palette.sumiInk4 },

          Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1, blend = 0 }, -- add `blend = vim.o.pumblend` to enable transparency
          PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
          PmenuSbar = { bg = theme.ui.bg_m1 },
          PmenuThumb = { bg = theme.ui.bg_p2 },
          BlinkCmpDoc = { fg = colors.palette.lotusGray, bg = theme.ui.bg_m1 },
          BlinkCmpDocBorder = { fg = colors.palette.sumiInk6, bg = theme.ui.bg_m1 },
          BlinkCmpDocSeparator = { fg = colors.palette.sumiInk6, bg = theme.ui.bg_m1 },

          CmpItemKindText = { fg = colors.palette.carpYellow },
          CmpItemKindVariable = { fg = colors.palette.carpYellow },

          -- Diagnostic
          -- DiagnosticVirtualTextHint = makeDiagnosticColor(theme.diag.hint),
          -- DiagnosticVirtualTextInfo = makeDiagnosticColor(theme.diag.info),
          -- DiagnosticVirtualTextWarn = makeDiagnosticColor(theme.diag.warning),
          -- DiagnosticVirtualTextError = makeDiagnosticColor(theme.diag.error),

          -- navic
          WinBar = { bg = colors.palette.sumiInk4 },
          WinBarNc = { bg = colors.palette.sumiInk4 },
          lualine_a_inactive = { bg = colors.palette.sumiInk3 },
          lualine_b_inactive = { bg = colors.palette.sumiInk3 },
          lualine_c_inactive = { bg = colors.palette.sumiInk3 },

          -- algorithm
          CompetiTestCorrect = { fg = colors.palette.springGreen },
          -- CompetiTestCorrect = { fg = "#b3f6c0" },
          CompetiTestWrong = { fg = colors.palette.waveRed },
          -- CompetiTestWrong = { fg = "#ff5d62" },

          -- cmp
          CmpItemAbbrMatch = { fg = "#7fb4ca", bold = true },
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
          TelescopePreviewTitle = {
            bg = colors.palette.waveRed,
          },
          TelescopePromptTitle = {
            bg = colors.palette.springGreen,
          },
          TelescopeResultsTitle = {
            bg = "#99aee5",
          },

          -- Snack Notifier
          SnacksNotifierError = { fg = theme.diag.error },
        }
      end,
    },
    -- branch = "dev",
    -- commit = "476eb2289d47d132ebacc1a4d459e3204866599b"
  },
  {
    "navarasu/onedark.nvim",
    opts = {
      style = "light",
      term_colors = false,
      code_style = {
        comments = "italic,bold",
        keywords = "none",
        functions = "none",
        strings = "none",
        variables = "none",
      },
      diagnostics = {
        darker = false,
        undercurl = true,
        background = true,
      },
      highlights = {
        WinBar = { bg = "$bg1" },
        WinBarNc = { bg = "$bg1" },
        TreesitterContextLineNumber = { bg = "$bg1" },
      },
    },
  },
  {
    "catppuccin/nvim",
    optional = true,
    opts = {
      flavour = "auto", -- latte, frappe, macchiato, mocha
      background = { -- :h background
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false, -- disables setting the background color.
      float = {
        transparent = false, -- enable transparent floating windows
        solid = false, -- use solid styling for floating windows, see |winborder|
      },
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
        comments = { "italic"}, -- Change the style of comments
        conditionals = { "italic"},
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
        -- miscs = {}, -- Uncomment to turn off hard-coded styles
      },
      lsp_styles = { -- Handles the style of specific lsp hl groups (see `:h lsp-highlight`).
        virtual_text = {
          errors = { "italic"},
          hints = { "italic"},
          warnings = { "italic"},
          information = { "italic"},
          ok = { "italic"},
        },
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
          ok = { "undercurl" },
        },
        inlay_hints = {
          background = true,
        },
      },
      color_overrides = {},
      custom_highlights = {},
      default_integrations = true,
      auto_integrations = false,
      integrations = {
        cmp = true,
        gitsigns = true,
        lualine = {
          latte = function(C)
            return {
              normal = {
                a = { bg = C.lavender, fg = C.mantle, gui = "bold" },
                b = { bg = C.surface0, fg = C.lavender },
              },
              insert = {
                a = { bg = C.teal, fg = C.base, gui = "bold" },
                b = { bg = C.surface0, fg = C.teal },
              },
              terminal = {
                a = { bg = C.teal, fg = C.base, gui = "bold" },
                b = { bg = C.surface0, fg = C.teal },
              },
              command = {
                a = { bg = C.yellow, fg = C.base, gui = "bold" },
                b = { bg = C.surface0, fg = C.yellow },
              },
              visual = {
                a = { bg = "#8150f3", fg = C.base, gui = "bold" },
                b = { bg = C.surface0, fg = "#8150f3" },
              },
              replace = {
                a = { bg = C.maroon, fg = C.base, gui = "bold" },
                b = { bg = C.surface0, fg = C.maroon },
              },
              inactive = {
                a = { fg = C.lavender },
              },
            }
          end,
        },
        nvimtree = true,
        notify = false,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
      },
    },
  },
  {
    "LazyVim/LazyVim",
    init = function()
      local group = vim.api.nvim_create_augroup("theme_background", { clear = true })
      vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "background",
        callback = function()
          vim.schedule(function()
            require("config.theme").apply()
          end)
        end,
      })
    end,
    opts = {
      colorscheme = function()
        require("config.theme").apply()
      end,
      -- colorscheme = "catppuccin-frappe",
      -- colorscheme = "catppuccin-latte",
      -- colorscheme = "dawnfox",
      -- colorscheme = "vscode",
    },
  },
}
