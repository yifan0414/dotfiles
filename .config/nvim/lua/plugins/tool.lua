return {
  {
    "xiyaowong/virtcolumn.nvim",
    enabled = false,
    event = "BufReadPost",
  },
  {
    "blob42/vimux",
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
}
