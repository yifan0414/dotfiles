-- place this in one of your configuration file(s)

return {
  "phaazon/hop.nvim",
  event = "VeryLazy",
  enabled = false,
  config = function()
    require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
    local hop = require("hop")
    local directions = require("hop.hint").HintDirection

    vim.keymap.set("n", "s", function()
      hop.hint_char1()
    end, { remap = true })

    vim.keymap.set("n", "f", function()
      hop.hint_char1({ current_line_only = true })
    end, { remap = true })

    vim.keymap.set("n", "F", function()
      hop.hint_char1({ direction = directions.AFTER_CURSOR })
    end, { remap = true })

    vim.keymap.set("n", "t", function()
      hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
    end, { remap = true })

    vim.keymap.set("n", "T", function()
      hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
    end, { remap = true })
  end,
}
