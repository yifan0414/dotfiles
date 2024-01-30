local func = require("plugins.util.func")
local picker = require("plugins.util.picker")

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

local yadm_command = {
  {
    "Yadm log",
    -- "call asyncrun#run('', {'scroll':'0', 'post':'copen'}, 'cd ~ && yadm log')" ,
    "AsyncRun -cwd=~ -mode=term -pos=floaterm -width=0.8 -height=0.8 yadm log",
  },
  {
    "Yadm nvim",
    "call asyncrun#run('', {'cwd':'~'},'cd ~ && yadm add .config/nvim && yadm commit -m \"'.input('Enter commit message: ').'\" && yadm push')",
  },
  {
    "Yadm diff",
    "AsyncRun -cwd=~ -mode=term -pos=floaterm -width=0.8 -height=0.8 yadm diff",
  },
  {
    "Yadm status",
    "AsyncRun -cwd=~ -mode=term -pos=floaterm -width=0.8 -height=0.8 yadm status",
  },
  {
    "Yadm diff this file",
    "AsyncRun -cwd=~ -mode=term -pos=floaterm -width=0.8 -height=0.8 yadm diff $(VIM_FILEPATH)",
  },
}

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
      "<Leader>fs",
      "<cmd>Telescope resume<cr>",
      { noremap = true, silent = true },
      desc = "resume",
    },
    {
      "<Leader>tt",
      function()
        picker.telescope_command_picker(tmux_command)
      end,
      { noremap = true, silent = true },
      desc = "tmux command",
    },
    {
      "<Leader>tr",
      function()
        -- picker.telescope_command_picker(frequent_command)
        picker.dress_select(frequent_command)
      end,
      { noremap = true, silent = true },
      desc = "frequent command",
    },
    {
      "<Leader>ty",
      function()
        -- picker.dress_select(yadm_command)
        picker.telescope_command_picker(yadm_command)
      end,
      { noremap = true, silent = true },
      desc = "yadm command",
    },
    {
      "<Leader>tf",
      function()
        func.start_row = vim.fn.getpos("v")[2]
        func.end_row = vim.fn.getpos(".")[2]
        picker.telescope_func_picker(func.function_command)
      end,
      { noremap = true, silent = true },
      desc = "function command",
      mode = { "n", "v" },
    },
  },
  dependencies = {
    "skywind3000/asyncrun.vim",
    "yifan0414/asynctasks.vim",
  },
}
