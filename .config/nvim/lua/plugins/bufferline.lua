return {
  {
    "akinsho/bufferline.nvim",
    lazy = true,
    event = function()
      return "BufAdd"
    end,
    opts = {
      options = {
        mode = { "buffers", "tabs" },
        max_name_length = 7,
        max_prefix_length = 5, -- prefix used when a buffer is de-duplicated
        truncate_names = true, -- whether or not tab names should be truncated
        tab_size = 7,
        show_close_icon = false,
        show_buffer_close_icons = false,
        diagnostics = false,
        -- always_show_bufferline = true,
      },
    },
  },
  {
    "echasnovski/mini.bufremove",
    keys = {
      {
        "<C-w>",
        function()
          local bd = require("mini.bufremove").delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = "Delete Buffer",
      },
    },
  },
  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    keys = { -- Example mapping to toggle outline
      { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    opts = {
      symbol_folding = {
        autofold_depth = false,
      },
      outline_window = {
        width = 20,
      },
    },
  },
}
