local util = {}

util.start_row = 0 -- 存放visual的开始位置
util.end_row = 0 -- 存放visual的结束位置

-- 在 Neovim 配置文件中定义本地函数
function util.myLocalFunction()
  -- 这里是函数的实现
  vim.api.nvim_out_write(util.start_row .. " " .. util.end_row .. "\n")
end

function util.yanWithLine()
  -- 使用 row1 和 row2 定义 Vim 命令
  vim.api.nvim_out_write(util.start_row .. " " .. util.end_row .. "\n")
  local vim_command = util.start_row .. "," .. util.end_row .. "number"

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

function util.replaceArea()
  local command = util.start_row .. "," .. util.end_row
  local old_word = vim.fn.input("Source ")
  local new_word = vim.fn.input("Target ")
  -- Check if the new_word is different from the old_word and is not empty
  if new_word ~= old_word and new_word ~= "" then
    command = command .. "s/" .. old_word .. "/" .. new_word .."/g | nohlsearch"
    vim.api.nvim_out_write(command .. "\n")
    -- vim.cmd(":%s/\\<" .. old_word .. "\\>/" .. new_word .. "/g")
    -- vim.api.nvim_exec(command)
    vim.cmd(command)
  end
end

function util.replaceBuf()
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

function util.join()
  local lines = vim.api.nvim_buf_get_lines(0, util.start_row - 1, util.end_row, false)

  local joined_lines = vim.fn.join(lines, " ")

  vim.api.nvim_buf_set_lines(0, util.start_row - 1, util.end_row, false, { joined_lines })
end

function util.selectLine()
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

-- function util.selectLine()
--   local buffer = 0 -- 当前缓冲区
--   local pattern = vim.fn.input("Target: ") -- 要筛选的字符串（Vim 正则表达式）
--
--   -- 获取当前缓冲区的所有行
--   local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
--
--   -- 筛选包含特定字符串的行
--   local filtered_lines = {}
--   for _, line in ipairs(lines) do
--     if vim.fn.match(line, pattern) ~= -1 then
--       table.insert(filtered_lines, line)
--     end
--   end
--
--   -- 将缓冲区内容设置为筛选后的行
--   vim.api.nvim_buf_set_lines(buffer, 0, -1, false, filtered_lines)
-- end

-- 定义一个表格，记录名字与函数
util.function_command = {
  { name = "test", func = util.myLocalFunction },
  { name = "YankWithLineNumber", func = util.yanWithLine },
  { name = "ReplaceArea", func = util.replaceArea },
  { name = "ReplaceBuf", func = util.replaceBuf },
  { name = "JoinLines", func = util.join },
  { name = "SelectLine", func = util.selectLine },
}

return util
