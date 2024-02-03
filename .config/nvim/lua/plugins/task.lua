return {
  {
    "skywind3000/asyncrun.vim",
    -- event = "VeryLazy",
    cmd = "AsyncRun",
    -- config = function()
    --   -- 定义自动命令
    --   vim.api.nvim_create_autocmd("User", {
    --     pattern = "AsyncRunStart",
    --     group = "asyncrun_augroup",
    --     command = "copen",
    --   })
    -- end,
    -- dependencies = {
    --   "blob42/vimux",
    -- },
  },
  {
    "yifan0414/asynctasks.vim",
    -- event = "VeryLazy",
    cmd = "AsyncTask",
    keys = {
      { "<leader>a1", "<cmd>AsyncTask file-build<cr>", desc = "AsyncTask file-build", mode = "n" },
      { "<leader>a2", "<cmd>AsyncTask file-run<cr>", desc = "AsyncTask file-run", mode = "n" },
      { "<leader>a3", "<cmd>AsyncTask project-build<cr>", desc = "AsyncTask project-build", mode = "n" },
      { "<leader>a4", "<cmd>AsyncTask project-run<cr>", desc = "AsyncTask project-run", mode = "n" },
      {
        "<leader>at",
        function()
          -- picker.dress_async()
          local picker = require("plugins.util.picker")
          picker.asyncfunc()
        end,
        desc = "AsyncTask: select",
        { noremap = true, silent = true },
      },
    },
    -- dependencies = {
    --   "blob42/vimux",
    -- },
  },
  {
    "yifan0414/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup({})
    end,
    keys = {
      {
        "<leader>H",
        function()
          require("harpoon"):list():append()
        end,
        desc = "harpoon file",
      },
      {
        "<leader>h",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "harpoon quick menu",
      },
      {
        "<leader>1",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "harpoon to file 1",
      },
      {
        "<leader>2",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "harpoon to file 2",
      },
      {
        "<leader>3",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "harpoon to file 3",
      },
      {
        "<leader>4",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "harpoon to file 4",
      },
      {
        "<leader>5",
        function()
          require("harpoon"):list():select(5)
        end,
        desc = "harpoon to file 5",
      },
    },
  },
  {
    "voldikss/vim-floaterm",
    cmd = { "FloatermNew", "FloatermToggle" },
    -- event = "VeryLazy",
    -- lazy = true,
    keys = {
      { "<F1>", "<cmd>FloatermToggle<CR>", { silent = true, noremap = true } },
      { "<F1>", "<C-\\><C-n><cmd>FloatermToggle<CR>", { silent = true, noremap = true } },

      { "<F2>", "<cmd>FloatermNext<CR>", { silent = true, noremap = true } },
      { "<F2>", "<C-\\><C-n><cmd>FloatermNext<CR>", { silent = true, noremap = true } },

      { "<F3>", "<cmd>FloatermPrev<CR>", { silent = true, noremap = true } },
      { "<F3>", "<C-\\><C-n><cmd>FloatermPrev<CR>", { silent = true, noremap = true } },

      { "<F4>", "<cmd>FloatermNew<CR>", { silent = true, noremap = true } },
      { "<F4>", "<C-\\><C-n>:FloatermNew<CR>", { silent = true, noremap = true } },
    },
  },
  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        FIX = {
          icon = " ", -- icon used for the sign, and in search results
          color = "error", -- can be a hex color, or a named color (see below)
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = "󰙏 ", color = "hint", alt = { "INFO" } },
        TEST = { icon = " ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
    },
    keys = {
      { "<leader>xt", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
      {
        "<leader>xT",
        "<cmd>TodoTrouble keywords=TODO,FIX,FIXME,HACK,WARN,PERF,NOTE,TEST<cr>",
        desc = "All (Trouble)",
      },
      { "<leader>st", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
      { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME,HACK,WARN,PERF,NOTE,TEST<cr>", desc = "All " },
    },
  },
  {
    "tpope/vim-fugitive",
    cmd = "Git",
    keys = {
      { "<leader>gl", "<cmd>Git log<cr>", { silent = true, noremap = true }, desc = "Git log" },
      { "<leader>gd", "<cmd>Git diff %<cr>", { silent = true, noremap = true }, desc = "Git log" },
      { "<leader>gb", "<cmd>Git blame<cr>", { silent = true, noremap = true }, desc = "Git log" },
      { "<leader>gs", "<cmd>Git<cr>", { silent = true, noremap = true }, desc = "Git log" },
    },
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      fps = 165,
    },
  },
  -- {
  --   "sindrets/diffview.nvim",
  -- }
  -- {
  --   "ahmedkhalf/project.nvim",
  --   opts = {
  --     manual_mode = true,
  --   },
  --   -- event = "VeryLazy",
  --   config = function(_, opts)
  --     require("project_nvim").setup(opts)
  --     require("lazyvim.util").on_load("telescope.nvim", function()
  --       require("telescope").load_extension("projects")
  --     end)
  --   end,
  --   keys = {
  --     { "<leader>fp", "<Cmd>Telescope projects<CR>", desc = "Projects" },
  --   },
  -- },
}
