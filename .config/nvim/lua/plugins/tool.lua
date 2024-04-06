return {
  {
    "xiyaowong/virtcolumn.nvim",
    enabled = false,
    event = "BufReadPost",
  },
  {
    "preservim/vimux",
    keys = {
      {
        "<leader>r",
        function()
          local function vimux_slime()
            -- 调用 VimScript 函数 VimuxRunCommand，传递寄存器 v 的内容和 0 作为参数
            vim.fn.VimuxRunCommand(vim.fn.getreg("v"), 0)
          end
          vim.cmd('normal! "vy')
          vim.fn.setreg("v", vim.fn.getreg("v") .. "\n")
          vimux_slime()
        end,
        mode = "v",
      },
      {
        "<leader>vr",
        function()
          local function vimux_slime()
            -- 调用 VimScript 函数 VimuxRunCommand，传递寄存器 v 的内容和 0 作为参数
            vim.fn.VimuxRunCommand(vim.fn.getreg("v"), 0)
          end
          vim.cmd('normal! "vyip')
          vim.fn.setreg("v", vim.fn.getreg("v") .. "\n")
          vimux_slime()
        end,
        mode = "n",
      },
      {
        "go",
        function()
          -- https://img95.699pic.com/photo/50046/5562.jpg_wh300.jpg
          local url = vim.fn.expand("<cfile>")
          vim.fn.VimuxRunCommand("kitty icat --passthrough tmux " .. url)
        end,
        mode = "n",
      },
    },
  },
  -- lazy.nvim
  -- minimal config for lazy-loading with lazy.nvim
  {
    "chrisgrieser/nvim-recorder",
    dependencies = "rcarriga/nvim-notify",
    keys = {
      -- these must match the keys in the mapping config below
      { "@", desc = " Start Recording" },
      { "Q", desc = " Play Recording" },
    },
    opts = {
      clear = true,
      mapping = {
        startStopRecording = "@",
        playMacro = "Q",
        addBreakPoint = "**",
      },
    },
    config = function(_, opts)
      require("recorder").setup(opts)
      local lualine = require("lualine").get_config().sections.lualine_x or {}
      table.insert(lualine, { require("recorder").recordingStatus, color = { fg = "#ff5d62" } })
      table.insert(lualine, { require("recorder").displaySlots, color = { fg = "#ff5d62" } })
      require("lualine").setup({
        sections = {
          lualine_x = lualine,
        },
      })
    end,
  },
  {
    "otavioschwanck/arrow.nvim",
    keys = {
      { "," },
    },
    opts = {
      show_icons = true,
      leader_key = ",", -- Recommended to be a single key
      global_bookmarks = true,
    },
  },
  {
    "debugloop/telescope-undo.nvim",
    dependencies = { -- note how they're inverted to above example
      {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
      },
    },
    keys = {
      { -- lazy style key map
        "<leader>fu",
        "<cmd>Telescope undo<cr>",
        desc = "undo history",
      },
    },
    opts = {
      -- don't use `defaults = { }` here, do this in the main telescope spec
      extensions = {
        undo = {
          -- telescope-undo.nvim config, see below
        },
        -- no other extensions here, they can have their own spec too
      },
    },
    config = function(_, opts)
      -- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
      -- configs for us. We won't use data, as everything is in it's own namespace (telescope
      -- defaults, as well as each extension).
      require("telescope").setup(opts)
      require("telescope").load_extension("undo")
    end,
  },
  {
    "anuvyklack/pretty-fold.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("pretty-fold").setup(opts)
    end,
  },
  {
    "tpope/vim-scriptease",
    enabled = false,
  },
  {
    "smoka7/multicursors.nvim",
    -- event = "VeryLazy",
    dependencies = {
      "smoka7/hydra.nvim",
    },
    opts = {},
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    config = function()
      require("multicursors").setup({
        hint_config = false,
      })
    end,
    keys = {
      {
        mode = { "v", "n" },
        "<leader>m",
        "<cmd>MCstart<cr>",
        desc = "Create a selection for selected text or word under the cursor",
      },
    },
  },
}
