return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    triggers_nowait = {
      -- marks
      -- "`",
      -- "'",
      "g`",
      "g'",
      -- registers
      '"',
      "<c-r>",
      -- spelling
      "z=",
    },
  },
}
