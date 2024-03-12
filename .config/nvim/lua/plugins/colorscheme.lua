return {
  {
    -- "SnakeHit/kanagawa.nvim",
    "rebelot/kanagawa.nvim",
    init = function()
      vim.cmd([[
        autocmd VimEnter * highlight! StatusLine  guibg=#1F1F28 guifg=#dcd7ba
        autocmd VimEnter * highlight! Noicemini guifg=#54546d guibg=#1F1F28
        " autocmd VimEnter * highlight Search guifg=#223249 guibg=#ff9e3b
        autocmd VimEnter * highlight! CurSearch guifg=#dcd7ba guibg=#c34043

        " autocmd VimEnter * highlight Visual cterm=reverse gui=reverse guibg=NONE
        autocmd VimEnter * highlight! Visual cterm=bold gui=bold guibg=#45475a
        " 改变QuickFixLine的颜色
        autocmd VimEnter * highlight! QuickFixLine ctermbg=NONE cterm=bold guibg=NONE gui=bold
        autocmd VimEnter * highlight! LspInlayHint guifg=#686778 guibg=#1F1F28
        autocmd VimEnter * highlight! TermCursor guifg=#1f1f28 guibg=#dcd7ba gui=NONE cterm=NONE
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
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
    },
  },
}
