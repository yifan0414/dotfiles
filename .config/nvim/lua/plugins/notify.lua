return {
  "rcarriga/nvim-notify",
  opts = function(_, opts)
    opts.fps = 5
    opts.stages = "static"
    opts.max_width = 72
    opts.on_open = function(win)
      vim.api.nvim_win_set_config(win, { zindex = 100 })
    end
    vim.keymap.set("n", "<leader>fn", function()
      require("telescope").extensions.notify.notify()
    end, { desc = "Find notifications" })
  end,
}
