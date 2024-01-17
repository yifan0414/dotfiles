return {
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = false,
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- char = "▏",
      char = "│",
      filetype_exclude = {
        "help",
        "alpha",
        "dashboard",
        "neo-tree",
        "Trouble",
        "lazy",
        "mason",
        "notify",
        "toggleterm",
        "lazyterm",
      },
      show_trailing_blankline_indent = false,
      show_current_context = false,
    },
  },
  {
    "echasnovski/mini.indentscope",
    version = false, -- wait till new 0.7.0 release to put it back on semver
    enabled = false,
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- symbol = "▏",
      symbol = "│",
      options = { try_as_border = true },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
  {
    "shellRaining/hlchunk.nvim",
    enabled = false,
    ft = { "c", "cpp", "python", "lua", "javascript", "json", "sh" },
    config = function()
      require("hlchunk").setup({
        chunk = {
          enable = true,
          use_treesitter = true,
          notify = false,
          -- style = {
          --   { fg = "#806d9c" },
          -- },
        },
        indent = {
          enable = false,
        },
        line_num = {
          enable = true,
          use_treesitter = true,
          -- style = "#FFD700",
        },
        blank = {
          enable = false,
        },
      })
    end,
  },
}
