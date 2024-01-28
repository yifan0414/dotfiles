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
      "<Leader>t",
      function()
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values

        local my_commands = {
          { "Show File Path", "call setqflist([{'text': execute('echomsg expand(\"%:p\")')}]) | copen" },
          {
            "Open Man In Floaterm",
            "FloatermNew --width=0.8 --height=0.8 man -k . | fzf | awk '{print $1}' | xargs man | less",
          },
          {
            "输出一个msg到quickfix",
            "execute 'call setqflist([{\"text\": \"' . input('Enter message: ') . '\"}], \"a\") | copen'",
          },
          { "sent current line to tmux 2 pane", "silent .w !awk '{$1=$1;print}' | xargs -0ri tmux send -t2 {}" },
          {
            "sent current line to popup",
            "silent .w !awk '{$1=$1;print}' | xargs -0ri tmux send -t popup:1 {}; tmux display-popup -d '\\#{pane_current_path}' -xC -yC -w 90\\% -h 85\\% -E 'tmux attach-session -t popup || tmux new-session -s popup'",
          },

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
                -- vim.api.nvim_out_write(selection.display .. "\n")
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
