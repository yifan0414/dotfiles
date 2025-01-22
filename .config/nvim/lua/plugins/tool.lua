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
    enabled = false,
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
    enabled = false,
    config = function(_, opts)
      require("pretty-fold").setup(opts)
    end,
  },
  {
    "tpope/vim-scriptease",
    enabled = false,
  },
  {
    "jake-stewart/multicursor.nvim",
    -- event = "VeryLazy",
    branch = "1.0",
    keys = {
      -- {
      --   "<esc>",
      --   function()
      --     local mc = require("multicursor-nvim")
      --     if not mc.cursorsEnabled() then
      --       mc.enableCursors()
      --     elseif mc.hasCursors() then
      --       mc.clearCursors()
      --     else
      --       vim.cmd("noh")
      --       LazyVim.cmp.actions.snippet_stop()
      --       return "<esc>"
      --     end
      --   end,
      -- },
      {
        "<leader>m",
        function()
          local mc = require("multicursor-nvim")
          if vim.fn.mode() ~= "v" then
            vim.cmd("normal! viw")
          end
          mc.matchAddCursor(1)
        end,
        mode = { "n", "v" },
      },
    },
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      local set = vim.keymap.set

      set("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        elseif mc.hasCursors() then
          mc.clearCursors()
        else
          -- Default <esc> handler.
          vim.cmd("noh")
          LazyVim.cmp.actions.snippet_stop()
          return "<esc>"
        end
      end)
      -- Add or skip adding a new cursor by matching word/selection
      set({ "n", "v" }, "<c-n>", function()
        if vim.fn.mode() ~= "v" then
          vim.cmd("normal! viw")
        end
        mc.matchAddCursor(1)
      end)
      set({ "n", "v" }, "<c-p>", function()
        mc.matchSkipCursor(1)
      end)

      -- Add all matches in the document
      set({ "n", "v" }, "<leader>va", mc.matchAllAddCursors)

      -- Delete the main cursor.
      set({ "n", "v" }, "<leader>vx", mc.deleteCursor)

      -- Add and remove cursors with control + left click.
      set("n", "<c-leftmouse>", mc.handleMouse)

      -- Easy way to add and remove cursors using the main cursor.
      set({ "n", "v" }, "<c-q>", mc.toggleCursor)

      -- Clone every cursor and disable the originals.
      set({ "n", "v" }, "<leader><c-q>", mc.duplicateCursors)

      -- bring back cursors if you accidentally clear them
      set("n", "<leader>vs", mc.restoreCursors)

      -- Align cursor columns.
      set("n", "<leader>va", mc.alignCursors)

      -- Split visual selections by regex.
      set("v", "<leader>vS", mc.splitCursors)

      -- Append/insert for each line of visual selections.
      set("v", "I", mc.insertVisual)
      set("v", "A", mc.appendVisual)

      -- Rotate visual selection contents.
      set("v", "<leader>nt", function()
        mc.transposeCursors(1)
      end)
      set("v", "<leader>NT", function()
        mc.transposeCursors(-1)
      end)

      -- Customize how cursors look.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { link = "Cursor" })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorSign", { link = "SignColumn" })
      hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
      hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end,
  },
}
