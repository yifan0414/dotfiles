return {
  "mfussenegger/nvim-dap",
  optional = true,
  dependencies = {
    -- Ensure C/C++ debugger is installed
    "williamboman/mason.nvim",
    optional = true,
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "codelldb" })
      end
    end,
  },
  opts = function()
    local dap = require("dap")
    if not dap.adapters["codelldb"] then
      require("dap").adapters["codelldb"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "codelldb",
          args = {
            "--port",
            "${port}",
          },
        },
      }
    end
    for _, lang in ipairs({ "c", "cpp" }) do
      dap.configurations[lang] = {
        {
          type = "codelldb",
          request = "launch",
          name = "Launch file",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.expand("%:p:r"), "file")
          end,
          cwd = "${workspaceFolder}",
        },
        {
          type = "codelldb",
          request = "attach",
          name = "Attach to process",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
        },
      }
    end
  end,
  keys = {
    {
      "<F7>",
      function()
        require("dap").step_into()
      end,
      desc = "Step Into",
    },
    {
      "<F8>",
      function()
        -- local file_path = vim.fn.expand("%:p")
        -- -- -- 获取不带后缀的文件路径
        -- local file_path_without_extension = vim.fn.expand("%:p:r")
        -- --
        -- -- -- 构造编译命令
        -- local compile_command = string.format("g++ -g %s --std=c++20 -o %s", file_path, file_path_without_extension)
        -- --
        -- -- -- 执行编译命令
        -- vim.cmd("silent ! " .. compile_command)

        vim.cmd([[AsyncRun -silent=1 -post=lua\ require("dap").restart() g++ -g "$(VIM_FILEPATH)" --std=c++20 -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)"]])
        -- vim.cmd([[silent! g++ -g "$(VIM_FILEPATH)" --std=c++20 -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)"]])

        -- 启动DAP调试会话
        -- require("dap").restart()

      end,
      desc = "restart",
    },
    {
      "<F9>",
      function()
        require("dap").step_over()
      end,
      desc = "Step Over",
    },
  },
}
