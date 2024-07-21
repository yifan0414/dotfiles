return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  -- lazy = true,
  config = function(_, opts)
    -- local wk = require("which-key")
    -- wk.register({
    --   ["<leader>"] = {
    --     a = {
    --       name = "+  asynctasks",
    --     },
    --     ["<TAB>"] = {
    --       name = "+TAB",
    --     },
    --   },
    -- })

    require("which-key").setup(opts)
  end,
  opts = {
    delay = 500,
    defer = function(ctx)
      return ctx.mode == "v" or ctx.mode == "V" or ctx.mode == "y"
    end,
    -- modes = {
    --   x = false
    -- },
    -- triggers_nowait = {
    --   -- marks
    --   -- "`",
    --   -- "'",
    --   "g`",
    --   "g'",
    --   -- registers
    --   '"',
    --   "<c-r>",
    --   -- spelling
    --   "z=",
    -- },
    -- plugins = {
    --   presets = {
    --     operators = false,
    --   },
    -- },
    win = {
      border = "single",
    },
  },
}
