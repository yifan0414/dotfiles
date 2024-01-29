local picker = {}

local function init_telescope_modules()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  return actions, action_state, pickers, finders, conf
end

function picker.telescope_func_picker(commands)
  local actions, action_state, pickers, finders, conf = init_telescope_modules()

  -- vim.api.nvim_out_write(vim.fn.getpos("v")[2] .. " " .. vim.fn.getpos(".")[2] .. "\n")
  -- 在这之后就无法得到visual的坐标了
  pickers
    .new({}, {
      prompt_title = "Select a func",
      finder = finders.new_table({
        results = commands,
        entry_maker = function(entry)
          return {
            value = entry.func,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          selection.value() -- 调用选定的函数
        end)
        return true
      end,
    })
    :find()
end

function picker.telescope_command_picker(commands)
  local actions, action_state, pickers, finders, conf = init_telescope_modules()

  pickers
    .new({}, {
      prompt_title = "Select a Command",
      finder = finders.new_table({
        results = commands,
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
end

function picker.asyncfunc()
  local tasks = vim.fn["asynctasks#source"](math.floor(vim.go.columns * 48 / 100))
  local task_entries = {}

  for _, task in ipairs(tasks) do
    table.insert(task_entries, {
      value = task[1],
      display = task[1] .. " " .. task[2] .. ": " .. task[3],
      ordinal = task[1] .. " " .. task[2] .. ": " .. task[3],
    })
  end

  local actions, action_state, pickers, finders, conf = init_telescope_modules()

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
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local task_name = selection.value
          local command = "AsyncTask " .. task_name
          vim.cmd(command)
        end)
        return true
      end,
    })
    :find()
end

return picker
