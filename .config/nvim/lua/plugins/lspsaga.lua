return {
  "nvimdev/lspsaga.nvim",
  -- enabled = false,
  event = "LazyFile",
  config = function()
    require("lspsaga").setup({
      ui = {
        enable = false
      },
      lightbulb = {
        enable = false
      },
      implement = {
        enable = false
      },
      code_action = {
        enable = false
      },
      definition = {
        width = '0.4',
      },
      symbol_in_winbar = {
        respect_root = true,
      },
      vim.keymap.set("n", "gf", '<cmd>Lspsaga peek_definition<cr>')
    })
  end,
  -- dependencies = {
  --   "nvim-treesitter/nvim-treesitter", -- optional
  --   "nvim-tree/nvim-web-devicons", -- optional
  -- },
}

