return {
  "rcarriga/nvim-notify",
  enabled = false,
  opts = function(_, opts)
    vim.keymap.set("n", "<leader>fn", function()
      require("telescope").extensions.notify.notify()
    end, { desc = "Find notifications" })
    return {
      fps = 5,
      stages = "static",
      max_width = 72,
      on_open = function(win)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end,
    }
  end,
}
