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

    local presets = require("which-key.plugins.presets")
    presets.operators["v"] = nil
    presets.operators["m"] = nil
    vim.o.timeout = true
    vim.o.timeoutlen = 500
    require("which-key").setup(opts)
  end,
  opts = {
    modes = {
      x = false
    },
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
