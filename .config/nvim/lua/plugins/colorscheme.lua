return {
  {
    -- "SnakeHit/kanagawa.nvim",
    "rebelot/kanagawa.nvim",
    opts = {
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      keywordStyle = { italic = false},
      commentStyle = { italic = false },
      terminalColors = false,
      overrides = function(colors)
        local theme = colors.theme
        return {
          -- Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 }, -- add `blend = vim.o.pumblend` to enable transparency
          -- PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
          -- PmenuSbar = { bg = theme.ui.bg_m1 },
          -- PmenuThumb = { bg = theme.ui.bg_p2 },
          ["@string.regexp"] = { link = "@string.regex" },
          ["@variable.parameter"] = { link = "@parameter" },
          ["@exception"] = { link = "@exception" },
          ["@string.special.symbol"] = { link = "@symbol" },
          ["@markup.strong"] = { link = "@text.strong" },
          ["@markup.italic"] = { link = "@text.emphasis" },
          ["@markup.heading"] = { link = "@text.title" },
          ["@markup.raw"] = { link = "@text.literal" },
          ["@markup.quote"] = { link = "@text.quote" },
          ["@markup.math"] = { link = "@text.math" },
          ["@markup.environment"] = { link = "@text.environment" },
          ["@markup.environment.name"] = { link = "@text.environment.name" },
          ["@markup.link.url"] = { link = "Special" },
          ["@markup.link.label"] = { link = "Identifier" },
          ["@comment.note"] = { link = "@text.note" },
          ["@comment.warning"] = { link = "@text.warning" },
          ["@comment.danger"] = { link = "@text.danger" },
          ["@diff.plus"] = { link = "@text.diff.add" },
          ["@diff.minus"] = { link = "@text.diff.delete" },
          ["@lsp.type.comment"] = { link = "Comment" },
          ["@comment.todo"] = { link = "@text.todo" },
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
      colorscheme = "kanagawa-wave",
    },
  },
}
