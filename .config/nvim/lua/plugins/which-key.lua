require('which-key.plugins.presets').operators['v'] = nil
require('which-key.plugins.presets').operators['d'] = nil
require('which-key.plugins.presets').operators['c'] = nil

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
