local M = {}

local function init_telescope_modules()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local entry_display = require("telescope.pickers.entry_display")

  return actions, action_state, pickers, finders, conf, entry_display
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
  local actions, action_state, pickers, finders, conf, entry_display = init_telescope_modules()

  local task_entries = {}

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 25 },
      { remaining = true },
    },
  })

  for _, command in ipairs(commands) do
    -- local display
    if string.find(command[1], "file") then
      command[1] = "📝 " .. command[1]
    elseif string.find(command[1], "project") then
      command[1] = "📚 " .. command[1]
    else
    end

    local make_display = function()
      return displayer({
        { command[1], "Function" },
        { command[2], "String" },
      })
    end

    table.insert(task_entries, {
      value = command[2],
      display = make_display,
      ordinal = command[1],
    })
  end

  pickers
    .new({}, {
      layout_strategy = "horizontal",
      sorting_strategy = "ascending",
      layout_config = {
        width = 0.8, -- picker 的宽度占屏幕宽度的 80%
        height = 0.5, -- picker 的高度占屏幕高度的 50%
        prompt_position = "top", -- 将提示栏放在顶部
      },
      prompt_prefix = "🎯 ",
      prompt_title = "Select a Command",
      finder = finders.new_table({
        results = task_entries,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.ordinal,
            -- flag = entry.value,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        map("i", "<Tab>", actions.move_selection_next)
        map("i", "<S-Tab>", actions.move_selection_previous)
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

  local actions, action_state, pickers, finders, conf, entry_display = init_telescope_modules()

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { remaining = true },
      { remaining = true },
      { remaining = true },
    },
  })

  for _, task in ipairs(tasks) do
    -- local display
    if string.find(task[1], "file") then
      task[1] = "📝 " .. task[1]
    elseif string.find(task[1], "project") then
      task[1] = "📚 " .. task[1]
    else
    end

    local make_display = function()
      return displayer({
        { task[1], "Function" },
        { task[2], "String" },
        { task[3], "Identifier" },
      })
    end

    table.insert(task_entries, {
      value = task[1],
      display = make_display,
      ordinal = task[1] .. " " .. task[2] .. ": " .. task[3],
    })
  end

  pickers
    .new({
      layout_strategy = "horizontal",
      sorting_strategy = "ascending",
      layout_config = {
        width = 0.8, -- picker 的宽度占屏幕宽度的 80%
        height = 0.5, -- picker 的高度占屏幕高度的 50%
        prompt_position = "top", -- 将提示栏放在顶部
      },
      prompt_prefix = "🎯 ",
    }, {
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
      attach_mappings = function(prompt_bufnr, map)
        map("i", "<Tab>", actions.move_selection_next)
        map("i", "<S-Tab>", actions.move_selection_previous)
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
