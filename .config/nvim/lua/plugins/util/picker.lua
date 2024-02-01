local M = {}

local function init_telescope_modules()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  return actions, action_state, pickers, finders, conf
end

function M.telescope_func_picker(commands)
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
          vim.schedule(function()
            selection.value() -- 调用选定的函数
          end)
        end)
        return true
      end,
    })
    :find()
end

function M.telescope_command_picker(commands)
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
            flag = entry[2],
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          -- vim.api.nvim_out_write(selection.value .. "\n")
          actions.close(prompt_bufnr)
          vim.schedule(function()
            vim.cmd(selection.value)
          end)
        end)
        return true
      end,
    })
    :find()
end

function M.dress_select(commands)
  vim.ui.select(commands, {
    prompt = "Select a Command:",
    format_item = function(item)
      -- 这将定义用户在 UI 中看到的展示文本
      return item[1]
    end,
    telescope = require("telescope.themes"),
  }, function(choice)
    -- choice 是整个选中的项目表
    if choice then
      -- print("Selected value: " .. choice[2])
      vim.cmd(choice[2])
      -- 你可以在这里执行更多的操作，基于选中的值
    end
  end)
end

function M.dress_async()
  local tasks = vim.fn["asynctasks#source"](math.floor(vim.go.columns * 48 / 100))
  local task_entries = {}

  for _, task in ipairs(tasks) do
    table.insert(task_entries, {
      value = task[1],
      display = task[1] .. " " .. task[2] .. ": " .. task[3],
      ordinal = task[1] .. " " .. task[2] .. ": " .. task[3],
    })
  end

  vim.ui.select(task_entries, {
    prompt = "Select a Task:",
    format_item = function(item)
      -- 这将定义用户在 UI 中看到的展示文本
      return item.display
    end,
    telescope = require("telescope.themes"),
  }, function(choice)
    -- choice 是整个选中的项目表
    local task_name = choice.value
    local command = "AsyncTask " .. task_name
    vim.cmd(command)
    -- if choice then
    -- print("Selected value: " .. choice[2])
    -- 你可以在这里执行更多的操作，基于选中的值
    -- end
  end)
end

function M.asyncfunc()
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
          -- vim.api.nvim_out_write(task_name .. "\n")
          vim.schedule(function()
            vim.cmd(command)
          end)
        end)
        return true
      end,
    })
    :find()
end

return M
