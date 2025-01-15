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
    "rebelot/kanagawa.nvim",
    enabled = false,
    -- init = function()
    --   vim.cmd([[
    --     autocmd VimEnter * highlight! StatusLine  guibg=#1F1F28 guifg=#dcd7ba
    --     autocmd VimEnter * highlight! Noicemini guifg=#54546d guibg=#1F1F28
    --     " autocmd VimEnter * highlight Search guifg=#223249 guibg=#ff9e3b
    --     autocmd VimEnter * highlight! CurSearch guifg=#dcd7ba guibg=#c34043
    --
    --     " autocmd VimEnter * highlight Visual cterm=reverse gui=reverse guibg=NONE
    --     autocmd VimEnter * highlight! Visual cterm=NONE gui=NONE guibg=#45475a
    --     " 改变QuickFixLine的颜色
    --     autocmd VimEnter * highlight! QuickFixLine ctermbg=NONE cterm=bold guibg=NONE gui=bold
    --     autocmd VimEnter * highlight! LspInlayHint guifg=#686778 guibg=#1F1F28
    --     autocmd VimEnter * highlight! TermCursor guifg=#1f1f28 guibg=#dcd7ba gui=NONE cterm=NONE
    --     autocmd VimEnter * highlight! MatchParen cterm=bold gui=bold guibg=#45475a
    -- ]])
    -- end,
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
      functionStyle = { italic = true },
      commentStyle = { italic = false },
      terminalColors = false,
      overrides = function()
        return {
          NormalFloat = { fg = "#dcd7ba", bg = "#1F1F28" },
          FloatBorder = { fg = "#54546D", bg = "#1F1F28" },
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
          functions = { "bold" },
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
              TreesitterContext = { bg = frappe.mantle },
              NormalFloat = { bg = frappe.base },
              FloatBorder = { bg = frappe.base },
              ["@function.builtin"] = { fg = frappe.blue, bold = true },
              -- ["@type.builtin.cpp"] = { fg = frappe.mauve },
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
              TreesitterContext = { bg = latte.mantle },
              NormalFloat = { bg = latte.base },
              FloatBorder = { bg = latte.base },
              ["@function.builtin"] = { fg = latte.blue, bold = true },
              -- ["@type.builtin.cpp"] = { fg = latte.mauve },
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
          mini = {
            enabled = true,
            indentscope_color = "",
          },
          overseer = true,
          navic = {
            enabled = false,
            custom_bg = "lualine", -- "lualine" will set background to mantle
          },
          snacks = true,
          telescope = true,
          treesitter_context = true,
          which_key = true,
          dashboard = true,
          flash = true,
          fzf = true,
          grug_far = true,
          headlines = true,
          illuminate = true,
          leap = true,
          -- lsp_trouble = true,
          mason = true,
          markdown = true,
          neotest = true,
          neotree = true,
          noice = true,
          semantic_tokens = true,
          blink_cmp = true,
          -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
        },
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "kanagawa",
      colorscheme = "catppuccin-frappe",
      -- colorscheme = "catppuccin-latte",
      -- colorscheme = "dawnfox",
      -- colorscheme = "vscode",
    },
  },
}
