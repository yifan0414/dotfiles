return {
  "nvim-telescope/telescope.nvim",
  opts = {
    -- see :help telescope.setup()
    defaults = {
      -- https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/actions/init.lua
      mappings = {
        i = {
          ["<Esc>"] = require("telescope.actions").close,
          ["<Tab>"] = require("telescope.actions").move_selection_previous,
          ["<S-Tab>"] = require("telescope.actions").move_selection_next,
          ["<C-Q>"] = require("telescope.actions").select_vertical,
        },
      },
      -- The below pattern is lua regex and not wildcard
      -- file_ignore_patterns = { "%.out", "%.pdf", "%.png", "%.ok" },
      -- prompt_prefix = "🔍 ",
      prompt_prefix = "🔭 ",
      path_display = { truncate = 6 },
      -- layout_config = {height = 0.9, width = 0.9, preview_width = 0.5},
    },
  },
  keys = {
    {
      "<Leader>mb",
      function()
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values

        local my_commands = {
          { "Show File Path", "call setqflist([{'text': execute('echomsg expand(''%:p'')')}]) | copen" },
          -- 在这里添加更多命令
          -- {"命令名称", "执行的命令"},
        }
        pickers
          .new({}, {
            prompt_title = "Select a Command",
            finder = finders.new_table({
              results = my_commands,
              entry_maker = function(entry)
                return {
                  value = entry[2],
                  display = entry[1] .. ": " .. entry[2],
                  ordinal = entry[1],
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.cmd(selection.value)
              end)
              return true
            end,
          })
          :find()
      end,
      { noremap = true, silent = true },
      desc = "Select a command",
    },
  },
}
