local util = {}

util.start_row = {} -- 存放visual的开始位置
util.end_row = {}  -- 存放visual的结束位置

-- 在 Neovim 配置文件中定义本地函数
function util.myLocalFunction()
  -- 这里是函数的实现
  vim.api.nvim_out_write(util.start_row .. " " .. util.end_row .. "\n")
end

function util.YankWithLine()
  -- 使用 row1 和 row2 定义 Vim 命令
  vim.api.nvim_out_write(util.start_row .. " " .. util.end_row .. "\n")
  local vim_command = util.start_row .. "," .. util.end_row .. "number"

  -- 执行 Vim 命令并获取输出
  local command_output = vim.api.nvim_exec(vim_command, true)

  -- 移除每一行的前导空格
  command_output = command_output:gsub("^%s+", ""):gsub("\n%s+", "\n")

  -- 将输出存入 'n' 寄存器
  vim.fn.setreg("n", command_output)

  local filename = vim.fn.expand("%")

  local decoration = string.rep("-", #filename + 1)

  vim.fn.setreg("+", decoration .. "\n" .. filename .. ":" .. "\n" .. decoration .. "\n" .. vim.fn.getreg("n"))
end

-- 定义一个表格，记录名字与函数
util.function_command = {
  { name = "test", func = util.myLocalFunction },
  { name = "YankWithLineNumber", func = util.YankWithLine },
}

return util
