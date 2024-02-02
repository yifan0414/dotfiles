local M = {}

M.start_row = 0 -- 存放visual的开始位置
M.end_row = 0 -- 存放visual的结束位置

-- 在 Neovim 配置文件中定义本地函数
function M.myLocalFunction()
  -- 这里是函数的实现
  vim.api.nvim_out_write(M.start_row .. " " .. M.end_row .. "\n")
end

function M.yanWithLine()
  -- 使用 row1 和 row2 定义 Vim 命令
  vim.api.nvim_out_write(M.start_row .. " " .. M.end_row .. "\n")
  local vim_command = M.start_row .. "," .. M.end_row .. "number"

  -- 执行 Vim 命令并获取输出
  local command_output = vim.api.nvim_exec(vim_command, true)

  -- 移除每一行的前导空格
  -- command_output = command_output:gsub("^%s+", ""):gsub("\n%s+", "\n")
  command_output = command_output:gsub("^  ", ""):gsub("\n  ", "\n")

  -- 将输出存入 'n' 寄存器
  vim.fn.setreg("n", command_output)

  local filename = vim.fn.expand("%")

  local decoration = string.rep("-", #filename + 1)

  vim.fn.setreg("+", decoration .. "\n" .. filename .. ":" .. "\n" .. decoration .. "\n" .. vim.fn.getreg("n"))
end

function M.replaceArea()
  local command = M.start_row .. "," .. M.end_row
  local old_word = vim.fn.input("Source ")
  local new_word = vim.fn.input("Target ")
  -- Check if the new_word is different from the old_word and is not empty
  if new_word ~= old_word and new_word ~= "" then
    command = command .. "s/" .. old_word .. "/" .. new_word .. "/g | nohlsearch"
    vim.api.nvim_out_write(command .. "\n")
    -- vim.cmd(":%s/\\<" .. old_word .. "\\>/" .. new_word .. "/g")
    -- vim.api.nvim_exec(command)
    vim.cmd(command)
  end
end

function M.replaceBuf()
  local old_word = vim.fn.input("Source: ")
  local new_word = vim.fn.input("Target: ")
  -- Check if the new_word is different from the old_word and is not empty
  if new_word ~= old_word and new_word ~= "" then
    local command = "%s/" .. old_word .. "/" .. new_word .. "/g | nohlsearch"
    vim.api.nvim_out_write(command .. "\n")
    -- vim.cmd(":%s/\\<" .. old_word .. "\\>/" .. new_word .. "/g")
    -- vim.api.nvim_exec(command)
    vim.cmd(command)
  end
end

function M.join()
  local lines = vim.api.nvim_buf_get_lines(0, M.start_row - 1, M.end_row, false)

  local joined_lines = vim.fn.join(lines, " ")

  vim.api.nvim_buf_set_lines(0, M.start_row - 1, M.end_row, false, { joined_lines })
end

function M.selectLine()
  local buffer = 0 -- 当前缓冲区
  local pattern = vim.fn.input("Target: ") -- 要筛选的字符串

  -- 获取当前缓冲区的所有行
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

  -- 筛选包含特定字符串的行
  local filtered_lines = {}
  for _, line in ipairs(lines) do
    if line:find(pattern) then
      table.insert(filtered_lines, line)
    end
  end

  -- 将缓冲区内容设置为筛选后的行
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, filtered_lines)
end

function M.deleteSelectLine()
  local word = vim.fn.input("Source: ")
  local command = "g/" .. word .. "/d"
  vim.cmd(command)
end

M.function_command = {
  -- { name = "test", func = M.myLocalFunction },
  { name = "YankWithLineNumber", func = M.yanWithLine },
  { name = "ReplaceArea", func = M.replaceArea },
  { name = "ReplaceBuf", func = M.replaceBuf },
  { name = "JoinLines", func = M.join },
  { name = "SelectLine", func = M.selectLine },
  { name = "Table_format", func = require("plugins.util.tableformat") },
  { name = "deleteSelectLine", func = M.deleteSelectLine },
}

return M
