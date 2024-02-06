return {
  "nvimdev/lspsaga.nvim",
  -- enabled = false,
  event = "LazyFile",
  -- config = function()
  --   require("lspsaga").setup({
  --     vim.keymap.set("n", "gf", '<cmd>Lspsaga peek_definition<cr>')
  --   })
  -- end,
  opts = {
    ui = {
      enable = false,
    },
    lightbulb = {
      enable = false,
    },
    implement = {
      enable = false,
    },
    code_action = {
      enable = false,
    },
    definition = {
      width = "0.4",
    },
    symbol_in_winbar = {
      -- respect_root = true,
      -- show_file = false,
      folder_level = 0,
    },
    outline = {
      enable = false,
      -- auto_close = true,
      -- detail = false,
      -- layout = 'float'
    },
    diagnostic = {
      show_code_action = true,
      jump_num_shortcut = true,
      extend_relatedInformation = true,
    },
  },
  keys = {
    { "gf", "<cmd>Lspsaga peek_definition<cr>", desc = "lspsaga peek_definition" },
    -- { "<leader>cs", "<cmd>Lspsaga outline<cr>", desc = "lspsaga outline" },
    { "<leader>cb", "<cmd>Lspsaga show_buf_diagnostics<cr>", desc = "lspsaga show_buf_diagnostics" },
  },
  -- dependencies = {
  --   "nvim-treesitter/nvim-treesitter", -- optional
  --   "nvim-tree/nvim-web-devicons", -- optional
  -- },
}
