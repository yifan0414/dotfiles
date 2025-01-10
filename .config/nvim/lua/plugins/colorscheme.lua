return {
  {
    "Mofiqul/vscode.nvim",
    enabled = false,
    config = function()
      require("vscode").setup({
        style = "dark",
      })
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    enabled = false,
    init = function()
      vim.cmd([[
        autocmd VimEnter * highlight! StatusLine  guibg=#1F1F28 guifg=#dcd7ba
        autocmd VimEnter * highlight! Noicemini guifg=#54546d guibg=#1F1F28
        " autocmd VimEnter * highlight Search guifg=#223249 guibg=#ff9e3b
        autocmd VimEnter * highlight! CurSearch guifg=#dcd7ba guibg=#c34043

        " autocmd VimEnter * highlight Visual cterm=reverse gui=reverse guibg=NONE
        autocmd VimEnter * highlight! Visual cterm=NONE gui=NONE guibg=#45475a
        " 改变QuickFixLine的颜色
        autocmd VimEnter * highlight! QuickFixLine ctermbg=NONE cterm=bold guibg=NONE gui=bold
        autocmd VimEnter * highlight! LspInlayHint guifg=#686778 guibg=#1F1F28
        autocmd VimEnter * highlight! TermCursor guifg=#1f1f28 guibg=#dcd7ba gui=NONE cterm=NONE
        autocmd VimEnter * highlight! MatchParen cterm=bold gui=bold guibg=#45475a
    ]])
    end,
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
    config = function()
      require("catppuccin").setup({
        flavour = "auto", -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = "latte",
          dark = "mocha",
        },
        transparent_background = false, -- disables setting the background color.
        show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
        term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
        dim_inactive = {
          enabled = false, -- dims the background color of inactive window
          shade = "dark",
          percentage = 0.15, -- percentage of the shade to apply to the inactive window
        },
        no_italic = true, -- Force no italic
        no_bold = false, -- Force no bold
        no_underline = false, -- Force no underline
        styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
          comments = {}, -- Change the style of comments
          conditionals = {},
          loops = {},
          functions = { "bold" },
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
            }
          end,
          mocha = function(mocha)
            return {
              TreesitterContext = { bg = mocha.mantle },
              NormalFloat = { bg = mocha.base },
              FloatBorder = { bg = mocha.base },
            }
          end,
        },
        custom_highlights = function()
          return {
            CompetiTestCorrect = { cterm = bold, gui = bold },
          }
        end,
        default_integrations = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = false,
          mini = {
            enabled = true,
            indentscope_color = "",
          },
          navic = {
            enabled = false,
            custom_bg = "lualine", -- "lualine" will set background to mantle
          },
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
      -- colorscheme = "vscode",
    },
  },
}
