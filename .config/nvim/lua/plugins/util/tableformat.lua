local function getStringWidth(str)
  local len = 0
  for uchar in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
    if #uchar == 1 then
      len = len + 1 -- 对于单字节字符（如英文），加1
    else
      len = len + 2 -- 对于多字节字符（如中文），加2
    end
  end
  return len
end

local function countChineseChars(str)
  local count = 0
  for uchar in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
    if #uchar > 1 then
      count = count + 1
    end
  end
  return count
end

local function formatTextTable(rows)
  -- 拆分每行到单元格并计算中文字符数量
  local tableData = {}
  local chineseCharCounts = {}
  for i, row in ipairs(rows) do
    local cells = {}
    local charCounts = {}
    for cell in row:gmatch("|%s*([^|]+)") do
      cell = cell:match("^%s*(.-)%s*$") -- 去除单元格两边的空格
      table.insert(cells, cell)
      table.insert(charCounts, countChineseChars(cell))
    end
    tableData[i] = cells
    chineseCharCounts[i] = charCounts
  end

  -- 计算每列的最大宽度，跳过第二行
  local colWidths = {}
  for i, row in ipairs(tableData) do
    if i ~= 2 then -- 跳过第二行
      for j, cell in ipairs(row) do
        colWidths[j] = math.max(colWidths[j] or 0, getStringWidth(cell))
      end
    end
  end

  -- 格式化并构建新的文本表
  local formattedText = {}
  for i, row in ipairs(tableData) do
    local formattedRow = {}
    for j, cell in ipairs(row) do
      local spaceCount = colWidths[j] - #cell + chineseCharCounts[i][j]
      local format = i == 2 and string.rep("-", colWidths[j]) or cell .. string.rep(" ", spaceCount)
      table.insert(formattedRow, format)
    end
    table.insert(formattedText, "| " .. table.concat(formattedRow, " | ") .. " |")
  end
  return formattedText
end

local function formatTable()
  local start_row = require("plugins.util.func").start_row
  local end_row = require("plugins.util.func").end_row
  local buffer = 0
  local lines = vim.api.nvim_buf_get_lines(buffer, start_row - 1, end_row, false)
  local formattedTable = formatTextTable(lines)
  vim.api.nvim_buf_set_lines(buffer, start_row - 1, end_row, false, formattedTable)
end

-- 你提供的表格数据
-- local textTable = [[
-- | Column1sssssssssssdf | Column2 | Column3不错的选择呢                   | Column4 | Column5 |
-- | -------------------- | ------- | ------------------------- | ------- | ------- |
-- | Item1.1              | Item2.1 | Item3.1                   | Item4.1 | Item5.1 |
-- | Item1.2              | Item2.2 | Item3.2ssssssssssssssssss | Item4.2 | Item5.2 |
-- | Item1.3好的选择  | Item2.3 | Item3.3                   | Item4.3 | Item5.3 |
-- | Item1.4              | Item2.4 | Item3.4                   | Item4.4 | Item5.4 |
-- ]]

return formatTable
