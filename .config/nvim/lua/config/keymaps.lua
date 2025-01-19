vim.keymap.set("n", "<leader>;", "<cmd>e #<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>`", "<cmd>wincmd p<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "s", "cc", { noremap = true, silent = true })

vim.keymap.set("n", ";", ":", { noremap = true })

vim.keymap.set({ "n", "v" }, "0", "^", { noremap = true, silent = true })

-- vim.keymap.set("n", "<enter>", "<leader>cf", { noremap = true, silent = true, desc = "Format" })

vim.keymap.set({ "n", "v" }, "<leader>fo", function()
  require("lazyvim.util").format({ force = true })
end, { desc = "Format" })

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
  -- "<cmd>AsyncRun -strip rg -ni <cword> <root><CR>",
  "<cmd>AsyncRun -strip -silent -post=Trouble\\ quickfix rg -ni <cword> <root><cr>",
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
  { desc = "search word in quickfix(cwd)", noremap = true, silent = true }
)

-- So I can move around in insert
-- vim.keymap.set("i", "<C-k>", "<C-o>gk", { noremap = true, silent = true })
-- vim.keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true })
-- vim.keymap.set("i", "<C-j>", "<C-o>gj", { noremap = true, silent = true })
-- vim.keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true })

-- 在 Visual 模式下绑定 <leader>y 到复制到剪贴板(wsl2)命令
vim.keymap.set("v", "<leader>y", [["+y <cmd>call system('clip.exe', @+)<cr>]], { noremap = true, silent = true })

vim.keymap.set("n", "<leader>td", function()
  local os_date = os.date
  local diary_path = "/Users/yifansu/Library/CloudStorage/OneDrive-st.gxu.edu.cn/CSNote/Diary/"

  -- 获取当前日期
  local year = os_date("%Y")
  local month = os_date("%m")
  local day = os_date("%Y-%m-%d")

  -- 构建文件路径
  local file_path = diary_path .. year .. "/" .. month .. "/" .. day .. ".md"

  -- 检查文件是否存在
  -- local file = io.open(file_path, "r")
  -- if file then
  --   file:close()
  --   vim.cmd("edit " .. file_path)
  -- else
  --   vim.cmd("edit " .. file_path)
  -- end
  vim.cmd("10sp " .. file_path)
end, { noremap = true, silent = true, desc = "dayliy note" })

vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true })

vim.keymap.set("n", "<leader><tab>n", "<cmd>tabnext<cr>", { silent = true, noremap = true })
vim.keymap.set("n", "<leader><tab>p", "<cmd>tabprevious<cr>", { silent = true, noremap = true })

vim.keymap.del("n", "<leader>l")
vim.keymap.set("n", "<leader>p", "<cmd>Lazy<cr>", { desc = "Lazy" })
vim.keymap.set("n", "<leader>qw", "<cmd>q<cr>", { silent = true, noremap = true, desc = "quit" })

vim.keymap.set("n", "#", "*", { noremap = true })
vim.keymap.set("n", "*", "#", { noremap = true })

-- delete mark
vim.keymap.set("n", "dm", function()
  local marks = {}
  for ascii_code = 97, 122 do -- 'a' to 'z'
    local mark = vim.fn.getpos("'" .. string.char(ascii_code))
    if mark and mark[2] ~= 0 and vim.fn.line(".") == mark[2] then
      table.insert(marks, string.char(ascii_code))
    end
  end
  if #marks > 0 then
    vim.cmd("delmarks " .. table.concat(marks))
  end
end, { silent = true, noremap = true })

vim.keymap.set("n", "dM", "<cmd>delmarks!<cr>", { silent = true, noremap = true })

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end

vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

vim.keymap.set("n", "[[", "H", { silent = true, noremap = true })
vim.keymap.set("n", "]]", "L", { silent = true, noremap = true })

vim.keymap.set("n", "<leader>\\", "<C-W>v", { desc = "Split window right", remap = true })

vim.keymap.set("n", "<leader>fb", "<cmd>Telescope scope buffers<cr>", { desc = "Buffers" })

-- toggle statusline
vim.keymap.set("n", "<leader>ux", function()
  if vim.opt_local.laststatus:get() == 3 then
    require("lualine").hide({
      place = { "statusline" }, -- The segment this change applies to.
      unhide = false, -- whether to re-enable lualine again/
    })
    vim.o.laststatus = 0
    vim.opt.statusline = "%#Normal# "
  else
    require("lualine").hide({
      place = { "statusline" }, -- The segment this change applies to.
      unhide = true,
    })
    vim.o.laststatus = 3
  end
end, { silent = true, noremap = true, desc = "Toggle Statusline" })

-- toggle nvim cmp
vim.keymap.set("n", "<leader>un", function()
  local cmp = require("cmp")
  local current_setting = cmp.get_config().completion.autocomplete
  if current_setting and #current_setting > 0 then
    cmp.setup({ completion = { autocomplete = false } })
  else
    cmp.setup({ completion = { autocomplete = { cmp.TriggerEvent.TextChanged } } })
  end
end, { silent = true, noremap = true, desc = "Toggle NvimCmp" })

vim.keymap.set("n", "<leader>ap", "<cmd>%d _ | :0put +<cr>", { desc = "replace entire buffer" })
vim.keymap.set("n", "<leader>ay", "<cmd>%yank +<cr>", { desc = "copy entire buffer" })
vim.keymap.set("n", "<leader>ad", "<cmd>%d _ | startinsert<cr>", { desc = "delete entire buffer" })
vim.keymap.set("n", "<D-a>", "GVgg", { noremap = true, silent = true })

vim.keymap.set("n", "<F2>", function()
  Snacks.terminal()
end, { desc = "Terminal" })

vim.keymap.set("t", "<F2>", function()
  Snacks.terminal()
end, { desc = "Terminal" })
