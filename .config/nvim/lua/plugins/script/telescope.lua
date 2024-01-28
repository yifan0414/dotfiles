local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local my_commands = {
  { "Show File Path", "echo expand('%:p')" },
  -- 在这里添加更多命令
  -- {"命令名称", "执行的命令"},
}

function My_custom_picker()
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
end

vim.api.nvim_set_keymap("n", "<Leader>mc", "<cmd>lua My_custom_picker()<CR>", { noremap = true, silent = true })

return My_custom_picker
