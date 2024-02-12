return {
  {
    -- "SnakeHit/kanagawa.nvim",
    "rebelot/kanagawa.nvim",
    init = function()
      vim.cmd([[
        autocmd VimEnter * highlight StatusLine  guibg=#1F1F28 guifg=#dcd7ba
        autocmd VimEnter * highlight Noicemini guifg=#54546d guibg=#1F1F28
        " autocmd VimEnter * highlight Search guifg=#223249 guibg=#ff9e3b
        " autocmd VimEnter * highlight CurSearch guifg=#dcd7ba guibg=#c34043

        " autocmd VimEnter * highlight Visual cterm=reverse gui=reverse guibg=NONE
        autocmd VimEnter * highlight Visual cterm=bold gui=bold guibg=#45475a
        " 改变QuickFixLine的颜色
        autocmd VimEnter * highlight QuickFixLine ctermbg=NONE cterm=bold guibg=NONE gui=bold
    ]])
    end,
    opts = {
      compile = true,
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      keywordStyle = { italic = false },
      commentStyle = { italic = false },
      terminalColors = false,
      overrides = function(colors)
        -- local theme = colors.theme
        return {
          -- Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 }, -- add `blend = vim.o.pumblend` to enable transparency
          -- PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
          -- PmenuSbar = { bg = theme.ui.bg_m1 },
          -- PmenuThumb = { bg = theme.ui.bg_p2 },
          NormalFloat = { fg = "#dcd7ba", bg = "#1F1F28" },
          FloatBorder = { fg = "#54546D", bg = "#1F1F28" },
          -- StatusLine = { fg = "#54546D", bg = "#1F1F28" },
          -- ["@string.regexp"] = { link = "@string.regex" },
          -- ["@variable.parameter"] = { link = "@parameter" },
          -- ["@exception"] = { link = "@exception" },
          -- ["@string.special.symbol"] = { link = "@symbol" },
          -- ["@markup.strong"] = { link = "@text.strong" },
          -- ["@markup.italic"] = { link = "@text.emphasis" },
          -- ["@markup.heading"] = { link = "@text.title" },
          -- ["@markup.raw"] = { link = "@text.literal" },
          -- ["@markup.quote"] = { link = "@text.quote" },
          -- ["@markup.math"] = { link = "@text.math" },
          -- ["@markup.environment"] = { link = "@text.environment" },
          -- ["@markup.environment.name"] = { link = "@text.environment.name" },
          -- ["@markup.link.url"] = { link = "Special" },
          -- ["@markup.link.label"] = { link = "Identifier" },
          -- ["@comment.note"] = { link = "@text.note" },
          -- ["@comment.warning"] = { link = "@text.warning" },
          -- ["@comment.danger"] = { link = "@text.danger" },
          -- ["@diff.plus"] = { link = "@text.diff.add" },
          -- ["@diff.minus"] = { link = "@text.diff.delete" },
          -- ["@lsp.type.comment"] = { link = "Comment" },
          -- ["@comment.todo"] = { link = "@text.todo" },
        }
      end,
    },
    -- branch = "dev",
    -- commit = "476eb2289d47d132ebacc1a4d459e3204866599b"
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
    },
  },
}
