local row1
local row2

-- {"命令名称", "执行的命令"},
local tmux_command = {
  { "sent current line to tmux 2 pane", "silent .w !awk '{$1=$1;print}' | xargs -0ri tmux send -t2 {}" },
  {
    "sent current line to popup",
    "silent .w !awk '{$1=$1;print}' | xargs -0ri tmux send -t popup:1 {}; tmux display-popup -d '\\#{pane_current_path}' -xC -yC -w 90\\% -h 85\\% -E 'tmux attach-session -t popup || tmux new-session -s popup'",
  },
}

local frequent_command = {
  { "Show File Path", "call setqflist([{'text': execute('echomsg expand(\"%:p\")')}]) | copen" },
  {
    "Open Man In Floaterm",
    "FloatermNew --width=0.8 --height=0.8 man -k . | fzf | awk '{print $1}' | xargs man | less",
  },
  {
    "输出一个msg到quickfix",
    "execute 'call setqflist([{\"text\": \"' . input('Enter message: ') . '\"}], \"a\") | copen'",
  },
}

-- 在 Neovim 配置文件中定义本地函数
function myLocalFunction()
  -- 这里是函数的实现
  print("这是一个本地函数")
end

-- 定义一个Vimscript函数并为其指定名称
vim.cmd([[
function! YankWithLine()
  execute "normal! \<Esc>"
  normal! gv
  redir @n | silent! :'<,'>number | redir END
  let filename=expand("%")
  let decoration=repeat('-', len(filename)+1)
  let @+=decoration . "\n" . filename . ':' . "\n" . decoration . "\n" . @n
  execute "normal! \<Esc>"
endfunction
]])

-- 调用Vimscript函数

function CompleteYank()
  -- 获取选中文本的行号和内容
  -- vim.cmd("call YankWithLine()")
  -- 获取当前缓冲区的句柄
  local bufnr = vim.api.nvim_get_current_buf()

  -- vim.api.nvim_out_write(row1 .. " " .. row2 .. "\n")
  -- 获取缓冲区中的行（例如第 1 行到第 10 行，注意 Lua 中索引是从 1 开始的）
  local lines = vim.api.nvim_buf_get_lines(bufnr, row1, row2, false)

  -- 将这些行合并为一个字符串，每行之间以换行符分隔
  local text_to_copy = table.concat(lines, "\n")

  -- 将获取的文本存入 + 寄存器
  vim.fn.setreg("+", text_to_copy)
end

vim.keymap.set({ "v" }, "<leader>tc", function()
  CompleteYank()
end)

function_command = {
  { name = "test", func = myLocalFunction },
  { name = "统计选中的字符数", func = CompleteYank },
}

function telescope_func_picker(commands)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  pickers
    .new({}, {
      prompt_title = "Select a Command",
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
          -- vim.cmd("lua " .. selection.value .. "()")
          selection.value() -- 调用选定的函数
          -- vim.cmd("call YankWithLine()")
        end)
        return true
      end,
    })
    :find()
end

local function show_telescope_picker(commands)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

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

vim.keymap.set({ "n", "v" }, "<leader>tb", function()
  local task_list = {
    "hello",
    "Nice",
  }

  local function_command = {
    { name = "test", func = myLocalFunction },
    { name = "统计选中的字符数", func = CompleteYank },
  }

  vim.ui.select(task_list, {
    prompt = "Select a task:",
    telescope = require("telescope.themes"),
  }, function(choice)
    if choice then
      -- vim.cmd(command)
      CompleteYank()
    end
  end)
end, { noremap = true, silent = true })

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
      "<Leader>tt",
      function()
        show_telescope_picker(tmux_command)
      end,
      { noremap = true, silent = true },
      desc = "tmux command",
    },
    {
      "<Leader>tr",
      function()
        show_telescope_picker(frequent_command)
      end,
      { noremap = true, silent = true },
      desc = "frequent command",
    },
    {
      "<Leader>tf",
      function()
        row1 = vim.api.nvim_buf_get_mark(0, "<")[1]
        row2 = vim.api.nvim_buf_get_mark(0, ">")[1]
        vim.api.nvim_out_write(row1 .. " " .. row2 .. "\n")
        telescope_func_picker(function_command)
      end,
      { noremap = true, silent = true },
      desc = "function command",
      mode = { "n", "v" },
    },
  },
}
