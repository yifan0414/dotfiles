return {
  {
    "skywind3000/asyncrun.vim",
    -- event = "VeryLazy",
    cmd = "AsyncRun",
    dependencies = {
      "blob42/vimux",
    },
  },
  {
    "yifan0414/asynctasks.vim",
    -- event = "VeryLazy",
    cmd = "AsyncTask",
    keys = {
      {
        "<leader>a1",
        "<cmd>AsyncTask file-build<cr>",
        desc = "AsyncTask file-build",
        mode = "n",
      },
      {
        "<leader>a2",
        "<cmd>AsyncTask file-run<cr>",
        desc = "AsyncTask file-run",
        mode = "n",
      },
      {
        "<leader>a3",
        "<cmd>AsyncTask project-build<cr>",
        desc = "AsyncTask project-build",
        mode = "n",
      },
      {
        "<leader>a4",
        "<cmd>AsyncTask project-run<cr>",
        desc = "AsyncTask project-run",
        mode = "n",
      },
      {
        "<leader>at",
        function()
          local tasks = vim.fn["asynctasks#source"](math.floor(vim.go.columns * 48 / 100))
          local task_entries = {}

          for _, task in ipairs(tasks) do
            table.insert(task_entries, {
              value = task[1],
              display = task[1] .. " " .. task[2] .. ": " .. task[3],
              ordinal = task[1] .. " " .. task[2] .. ": " .. task[3],
            })
          end

          -- vim.api.nvim_out_write("task_entries: " .. task_entries[1] .. "\n")
          local pickers = require("telescope.pickers")
          local finders = require("telescope.finders")
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")

          pickers
            .new({}, {
              prompt_title = "Select a task",
              finder = finders.new_table({
                results = task_entries,
                entry_maker = function(entry)
                  return {
                    value = entry.value,
                    display = entry.display,
                    ordinal = entry.ordinal,
                  }
                end,
              }),
              sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
              attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                  local selection = action_state.get_selected_entry()
                  actions.close(prompt_bufnr)
                  local task_name = selection.value
                  -- vim.api.nvim_out_write("task: " .. task_name .. "\n")
                  -- vim.api.nvim_out_write("task display: " .. selection.display .. "\n")
                  -- vim.api.nvim_out_write("task ordinal: " .. selection.ordinal .. "\n")
                  local command = "AsyncTask " .. task_name
                  -- vim.api.nvim_out_write("command: " .. command .. "\n")
                  vim.cmd(command)
                end)
                return true
              end,
            })
            :find()
        end,
        desc = "AsyncTask: select",
        { noremap = true, silent = true ,},
      },
    },
    dependencies = {
      "blob42/vimux",
    },
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
}
