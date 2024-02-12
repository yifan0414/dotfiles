return {
  "yifan0414/vim-dadbod-ui",
  dependencies = {
    { "yifan0414/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  init = function()
    -- Your DBUI configuration
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_execute_on_save = 0
    vim.g.db_ui_use_nvim_notify = 0
    vim.g.db_ui_force_echo_notifications = 0
  end,
  config = function()
    vim.keymap.del("n", "<leader>e")
    vim.keymap.set("n", "<leader>e", "<cmd>DBUIToggle<cr>", { desc = "open sql" })
  end,
  -- keys = {
  --   { "<leader>e", "<cmd>DBUIToggle<cr>", desc = "open sql" },
  -- },
}
