return {
  -- amongst your other plugins
  {
    "yifan0414/asyncrun.vim",
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
      { "<leader>ar", "<cmd>AsyncTask run-argument<cr>", desc = "AsyncTask project-run", mode = "n" },
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
    dependencies = {
      "voldikss/vim-floaterm",
      "preservim/vimux",
    },
  },
  {
    "yifan0414/harpoon",
    enabled = false,
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup({})
    end,
    keys = {
      {
        "<leader>y",
        function()
          require("harpoon"):list():append()
        end,
        desc = "harpoon file",
      },
      {
        "<leader>Y",
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
    -- lazy = true,
    config = function()
      vim.g.floaterm_width = 0.8
      vim.g.floaterm_height = 0.8
      vim.g.floaterm_opener = "edit"
    end,
    keys = {
      { "<F1>", "<cmd>FloatermToggle<CR>", { silent = true, noremap = true } },
      { "<F1>", "<C-\\><C-n><cmd>FloatermToggle<CR>", { silent = true, noremap = true }, mode = "t" },

      -- { "<F2>", "<cmd>FloatermNext<CR>", { silent = true, noremap = true } },
      -- { "<F2>", "<C-\\><C-n><cmd>FloatermNext<CR>", { silent = true, noremap = true }, mode = "t" },
      --
      -- { "<F3>", "<cmd>FloatermPrev<CR>", { silent = true, noremap = true } },
      -- { "<F3>", "<C-\\><C-n><cmd>FloatermPrev<CR>", { silent = true, noremap = true }, mode = "t" },
      --
      -- { "<F4>", "<cmd>FloatermNew<CR>", { silent = true, noremap = true } },
      -- { "<F4>", "<C-\\><C-n>:FloatermNew<CR>", { silent = true, noremap = true }, mode = "t" },

      {
        "<leader>h",
        "<cmd>FloatermNew --title=yazi($1/$2) --height=0.8 --width=0.8 --wintype=float --name=floaterm1 --autoclose=2 yazi<cr>",
        { silent = true, noremap = true },
      },
      {
        "<leader>gl",
        "<cmd>FloatermNew --title=tig($1/$2) --width=0.85 --height=0.95 tig<cr>",
        { silent = true, noremap = true },
        desc = "tig",
      },
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
    "sindrets/diffview.nvim",
    -- event = "VeryLazy",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      {
        "<leader>gt",
        "<cmd>DiffviewFileHistory %<cr>",
        { silent = true, noremap = true },
        desc = "DiffviewFileHistory %",
      },
      {
        "<leader>gd",
        "<cmd>DiffviewFileHistory<cr>",
        { silent = true, noremap = true },
        desc = "DiffviewFileHistory",
      },
      { "<leader>go", "<cmd>DiffviewOpen<cr>", { silent = true, noremap = true }, desc = "DiffviewOpen" },
    },
    config = function()
      require("diffview").setup({
        icons = {
          folder_closed = "",
          folder_open = "",
        },
        signs = {
          fold_closed = "›",
          fold_open = "▾",
          done = "✔",
        },
        view = {
          default = {
            -- Config for changed files, and staged files in diff views.
            layout = "diff2_horizontal",
            winbar_info = false, -- See |diffview-config-view.x.winbar_info|
          },
          merge_tool = {
            -- Config for conflicted files in diff views during a merge or rebase.
            layout = "diff3_horizontal",
            disable_diagnostics = true, -- Temporarily disable diagnostics for conflict buffers while in the view.
            winbar_info = true, -- See |diffview-config-view.x.winbar_info|
          },
          file_history = {
            -- Config for changed files in file history views.
            layout = "diff2_horizontal",
            winbar_info = false, -- See |diffview-config-view.x.winbar_info|
          },
        },
        file_history_panel = {
          log_options = { -- See |diffview-config-log_options|
            git = {
              single_file = {
                diff_merges = "combined",
              },
              multi_file = {
                diff_merges = "first-parent",
              },
            },
            hg = {
              single_file = {},
              multi_file = {},
            },
          },
          win_config = { -- See |diffview-config-win_config|
            position = "bottom",
            height = 12,
            win_opts = {},
          },
        },
        file_panel = {
          listing_style = "tree", -- One of 'list' or 'tree'
          tree_options = { -- Only applies when listing_style is 'tree'
            flatten_dirs = true, -- Flatten dirs that only contain one single dir
            folder_statuses = "only_folded", -- One of 'never', 'only_folded' or 'always'.
          },
          win_config = { -- See |diffview-config-win_config|
            position = "left",
            width = 30,
            win_opts = {},
          },
        },

        -- keymaps = {
        --   view = {
        --     ["<tab>"] = false,
        --     ["<s-tab>"] = false,
        --   },
        --   file_history_panel = {
        --     ["<tab>"] = false,
        --     ["<s-tab>"] = false,
        --   },
        --   file_panel = {
        --     ["<tab>"] = false,
        --     ["<s-tab>"] = false,
        --   },
        -- },
      })
    end,
  },
}
