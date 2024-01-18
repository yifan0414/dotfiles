return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      max_name_length = 7,
      max_prefix_length = 5, -- prefix used when a buffer is de-duplicated
      truncate_names = true, -- whether or not tab names should be truncated
      tab_size = 7,
      show_close_icon = false,
      show_buffer_close_icons =false,
      diagnostics = false,
      -- always_show_bufferline = true,
    },
  },
}
