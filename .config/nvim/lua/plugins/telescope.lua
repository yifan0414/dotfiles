return {
  {
    "nvim-telescope/telescope.nvim",
    -- lazy = true,
    opts = function(_, opts)
      -- see :help telescope.setup()
      local actions = require("telescope.actions")
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        mappings = {
          i = {
            ["<Esc>"] = actions.close,
            ["<Tab>"] = actions.move_selection_previous,
            ["<S-Tab>"] = actions.move_selection_next,
            ["<C-Q>"] = actions.select_vertical,
          },
        },
        -- The below pattern is lua regex and not wildcard
        -- file_ignore_patterns = { "%.out", "%.pdf", "%.png", "%.ok" },
        -- prompt_prefix = "🔍 ",
        prompt_prefix = "🔭 ",
        path_display = { truncate = 6 },
        -- layout_config = { height = 0.85, width = 0.85, preview_width = 0.5 },
      })
    end,
    keys = {
      {
        "<Leader>fs",
        "<cmd>Telescope resume<cr>",
        { noremap = true, silent = true },
        desc = "resume",
        mode = { "n", "v" },
      },
      {
        "<Leader>tt",
        function()
          local tmux_command = {
            { "sent current line to tmux 2 pane", "silent .w !awk '{$1=$1;print}' | xargs -0ri tmux send -t2 {}" },
            {
              "sent current line to popup",
              "silent .w !awk '{$1=$1;print}' | xargs -0ri tmux send -t popup:1 {}; tmux display-popup -d '\\#{pane_current_path}' -xC -yC -w 90\\% -h 85\\% -E 'tmux attach-session -t popup || tmux new-session -s popup'",
            },
          }
          local picker = require("plugins.util.picker") -- lazy load
          picker.telescope_command_picker(tmux_command)
        end,
        { noremap = true, silent = true },
        desc = "tmux command",
      },
      {
        "<Leader>tr",
        function()
          local frequent_command = {
            { "Show File Path", "call setqflist([{'text': execute('echomsg expand(\"%:p\")')}]) | copen" },
            {
              "Open Man In Floaterm",
              "FloatermNew --title=Man($1/$2) --width=0.8 --height=0.8 man -k . | fzf | awk '{print $1}' | xargs man | less",
            },
            {
              "输出一个msg到quickfix",
              "execute 'call setqflist([{\"text\": \"' . input('Enter message: ') . '\"}], \"a\") | copen'",
            },
            {
              "Tokei(count code)",
              "AsyncRun -mode=term -pos=floaterm -width=0.8 -height=0.8 tokei <root>",
            },
          }
          local picker = require("plugins.util.picker") -- lazy load
          picker.telescope_command_picker(frequent_command)
          -- picker.dress_select(frequent_command)
        end,
        { noremap = true, silent = true },
        desc = "frequent command",
      },
      {
        "<Leader>ty",
        function()
          -- picker.dress_select(yadm_command)
          local yadm_command = {
            {
              "Yadm log",
              -- "call asyncrun#run('', {'scroll':'0', 'post':'copen'}, 'cd ~ && yadm log')" ,
              "AsyncRun -cwd=~ -mode=term -pos=floaterm -width=0.8 -height=0.8 yadm log",
            },
            {
              "Yadm nvim",
              "call asyncrun#run('', {'cwd':'~'},'yadm add .config/nvim && yadm commit -m \"'.input('Enter commit message: ').'\" && yadm push')",
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
          local picker = require("plugins.util.picker") -- lazy load
          picker.telescope_command_picker(yadm_command)
        end,
        { noremap = true, silent = true },
        desc = "yadm command",
      },
      {
        "<Leader>tg",
        function()
          local git_command = {
            {
              "查看git仓库代码修改行数",
              "AsyncRun -cwd=<root> -mode=term -pos=floaterm -width=0.8 -height=0.8 git diff --stat HEAD",
            },
            {
              "Git This Repository",
              "call asyncrun#run('', {'cwd':'<root>'},'git add . && git commit -m \"'.input('Enter commit message: ').'\" && git push')",
            },
          }
          local picker = require("plugins.util.picker") -- lazy load
          -- picker.dress_select(yadm_command)
          picker.telescope_command_picker(git_command)
        end,
        { noremap = true, silent = true },
        desc = "git command",
      },

      {
        "<Leader>tf",
        function()
          local func = require("plugins.util.func") -- lazy load
          local picker = require("plugins.util.picker") -- lazy load
          func.start_row = vim.fn.getpos("v")[2]
          func.end_row = vim.fn.getpos(".")[2]
          if func.start_row > func.end_row then
            -- 如果 start_row 大于 end_row，则交换它们的值
            func.start_row, func.end_row = func.end_row, func.start_row
          end
          picker.telescope_func_picker(func.function_command)
        end,
        { noremap = true, silent = true },
        desc = "function command",
        mode = { "n", "v" },
      },
    },
    dependencies = {
      "yifan0414/asyncrun.vim",
      "yifan0414/asynctasks.vim",
    },
  },
  {
    "danielfalk/smart-open.nvim",
    branch = "0.2.x",
    config = function()
      require("telescope").load_extension("smart_open")
    end,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "kkharji/sqlite.lua",
      -- Only required if using match_algorithm fzf
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- Optional.  If installed, native fzy will be used when match_algorithm is fzy
      { "nvim-telescope/telescope-fzy-native.nvim" },
    },
    keys = {
      {
        "<leader><leader>",
        "<cmd>Telescope smart_open<cr>",
        { silent = true, noremap = true },
        desc = "smart_open",
        mode = { "n" },
      },
    },
  },
}
