vim.keymap.set("n", "<leader>;", "<cmd>e #<cr>", { noremap = true, silent = true })

vim.keymap.set("n", ";", ":", { noremap = true })

vim.keymap.set({ "n", "v" }, "0", "^", { noremap = true, silent = true })

-- vim.keymap.set(
--   "n",
--   "<leader>fa",
--   "<cmd>lua vim.lsp.buf.format()<CR>",
--   { noremap = true, silent = true, desc = "Format" }
-- )

-- 将滚轮向下映射为Ctrl-e
-- vim.keymap.set("n", "<ScrollWheelDown>", "<C-e>", { noremap = true, silent = true })

-- 将滚轮向上映射为Ctrl-y
-- vim.keymap.set("n", "<ScrollWheelUp>", "<C-y>", { noremap = true, silent = true })

-- TODO: notify 插件如何将指针切换到弹出的messages

-- 配置bufferline
vim.keymap.set("n", "t", "<cmd>BufferLinePick<CR>", { noremap = true, silent = true })

-- AsyncRun
vim.keymap.set(
  "n",
  "<leader>xw",
  "<cmd>AsyncRun rg -ni <cword> <root><CR>",
  { desc = "search word in quickfix(root dir)", noremap = true, silent = true }
)

vim.keymap.set(
  "n",
  "<leader>xW",
  "<cmd>AsyncRun rg -ni <cword> <cwd><CR>",
  { desc = "search word in quickfix(cwd)", noremap = true, silent = true }
)

vim.keymap.set(
  "v",
  "<leader>xw",
  "y:AsyncRun rg -ni <C-R>0 <root><CR>",
  { desc = "search word in quickfix(root dir)", noremap = true, silent = true }
)

vim.keymap.set(
  "v",
  "<leader>xW",
  "y:AsyncRun rg -ni <C-R>0 <cwd><CR>",
  { desc = "search word in quickfix(root dir)", noremap = true, silent = true }
)

-- So I can move around in insert

vim.keymap.set("i", "<C-k>", "<C-o>gk", { noremap = true, silent = true })
vim.keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-j>", "<C-o>gj", { noremap = true, silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true })

-- config for leetcode
vim.keymap.del("n", "<leader>l")
vim.keymap.set("n", "<leader>p", "<cmd>Lazy<cr>", { desc = "Lazy" })
vim.keymap.set("n", "<leader>lr", "<cmd>Leet run<cr>", { desc = "Leet run" })
vim.keymap.set("n", "<leader>ls", "<cmd>Leet submit<cr>", { desc = "Leet submit" })
vim.keymap.set("n", "<leader>lt", "<cmd>Leet tabs<cr>", { desc = "Leet tabs" })
vim.keymap.set("n", "<leader>li", "<cmd>Leet info<cr>", { desc = "Leet info" })
vim.keymap.set("n", "<leader>lb", "<cmd>Leet list<cr>", { desc = "Leet list" })
vim.keymap.set("n", "<leader>lc", "<cmd>Leet console<cr>", { desc = "Leet console" })

-- function ToggleStatusline()
--   if vim.o.laststatus == 0 then
--     vim.o.laststatus = 2
--   else
--     vim.o.laststatus = 0
--   end
-- end
--
-- vim.api.nvim_set_keymap("n", "<leader>bh", "<cmd>lua ToggleStatusline()<cr>", { noremap = true, silent = true })

-- require("lazyvim.util").safe_keymap_set("n", "<leader>bh", function()
--   require("lazyvim.util").toggle("laststatus", false, { 0, 2 })
-- end, { noremap = true, silent = true })

-- FloatermNew
vim.api.nvim_set_keymap("n", "<F4>", "<cmd>FloatermNew<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("t", "<F4>", "<C-\\><C-n>:FloatermNew<CR>", { silent = true, noremap = true })

-- FloatermPrev
vim.api.nvim_set_keymap("n", "<F2>", "<cmd>FloatermPrev<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("t", "<F2>", "<C-\\><C-n><cmd>FloatermPrev<CR>", { silent = true, noremap = true })

-- FloatermNext
vim.api.nvim_set_keymap("n", "<F3>", "<cmd>FloatermNext<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("t", "<F3>", "<C-\\><C-n><cmd>FloatermNext<CR>", { silent = true, noremap = true })

-- FloatermToggle
vim.api.nvim_set_keymap("n", "<F1>", "<cmd>FloatermToggle<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("t", "<F1>", "<C-\\><C-n><cmd>FloatermToggle<CR>", { silent = true, noremap = true })

-- vim.api.nvim_set_keymap(
--   "n",
--   "<leader>th",
--   "<cmd>FloatermNew --width=0.8 --height=0.8 man -k . | fzf | awk '{print $1}' | xargs man<cr>",
--   { silent = true, noremap = true, desc = "Man" }
-- )

-- 在 Visual 模式下绑定 <leader>y 到复制到剪贴板(wsl2)命令
vim.api.nvim_set_keymap("x", "<leader>y", [[:w !clip.exe<CR>]], { noremap = true, silent = true })

-- vim.cmd([[
--   function! YankWithLine()
--     :'<,'>y
--   endfunction
-- ]])
--
-- -- 调用Vimscript函数
--
-- function CompleteYank()
--   -- 获取选中文本的行号和内容
--   vim.cmd("call YankWithLine()")
-- end

-- vim.keymap.set({ "n", "v" }, "<leader>tz", function()
--   local actions = require("telescope.actions")
--   local action_state = require("telescope.actions.state")
--   local pickers = require("telescope.pickers")
--   local finders = require("telescope.finders")
--   local conf = require("telescope.config").values
--
--   local function_command = {
--     { name = "test", func = myLocalFunction },
--     { name = "统计选中的字符数", func = CompleteYank },
--   }
--   pickers
--     .new({}, {
--       prompt_title = "Select a Command",
--       finder = finders.new_table({
--         results = function_command,
--         entry_maker = function(entry)
--           return {
--             value = entry.func,
--             display = entry.name,
--             ordinal = entry.name,
--           }
--         end,
--       }),
--       sorter = conf.generic_sorter({}),
--       attach_mappings = function(prompt_bufnr)
--         actions.select_default:replace(function()
--           local selection = action_state.get_selected_entry()
--           actions.close(prompt_bufnr)
--           -- vim.cmd("lua " .. selection.value .. "()")
--           -- selection.value() -- 调用选定的函数
--           vim.cmd("call YankWithLine()")
--         end)
--         return true
--       end,
--     })
--     :find()
-- end, { desc = "hello" })

vim.keymap.set({ "n", "v" }, "<leader>tx", function()
  local lines = vim.api.nvim_buf_get_lines(0, 1, 5, false)
  for i, line in ipairs(lines) do
    vim.api.nvim_out_write(i .. " " .. line .. "\n")
  end
end)

vim.keymap.set({ "n", "v" }, "<leader>t1", function()
  -- 获取当前光标位置（可能是选区的开始或结束）
  local cursor_pos = vim.fn.getpos(".")
  local v_pos = vim.fn.getpos("v")

  -- 检查 cursor_pos 和 v_pos 是否为有效的列表
  if not (cursor_pos and #cursor_pos >= 2) or not (v_pos and #v_pos >= 2) then
    -- print("Error: Invalid position data")
    return
  end

  local start_line, end_line

  -- 比较两个位置，确定选区的实际开始和结束
  if cursor_pos[2] < v_pos[2] then
    start_line = cursor_pos[2]
    end_line = v_pos[2]
  else
    start_line = v_pos[2]
    end_line = cursor_pos[2]
  end

  -- 打印或返回开始和结束行号
  print("Start line: " .. start_line .. ", End line: " .. end_line)
end)

vim.keymap.set({ "n", "v" }, "<leader>t2", function()
  local start_pos = vim.fn.getpos(".") --end
  local end_pos = vim.fn.getpos("v") --start [2,3]
  -- vim.api.nvim_out_write(start_pos[2] .. " " .. end_pos[2] .. "\n")

  for i, line in ipairs(start_pos) do
    vim.api.nvim_out_write(i .. " " .. start_pos[i] .. "\n")
  end

  for i, line in ipairs(end_pos) do
    vim.api.nvim_out_write(i .. " " .. end_pos[i] .. "\n")
  end
end)
