vim.keymap.set("n", "<leader>;", "<cmd>e #<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>`", "<cmd>wincmd p<cr>", { noremap = true, silent = true })

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
  { desc = "search word in quickfix(root dir)", noremap = true, silent = true }
)

-- So I can move around in insert

vim.keymap.set("i", "<C-k>", "<C-o>gk", { noremap = true, silent = true })
vim.keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-j>", "<C-o>gj", { noremap = true, silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true })

-- function ToggleStatusline()
--   if vim.o.laststatus == 0 then
--     vim.o.laststatus = 2
--   else
--     vim.o.laststatus = 0
--   end
-- end
--
-- vim.keymap.set("n", "<leader>bh", "<cmd>lua ToggleStatusline()<cr>", { noremap = true, silent = true })

-- require("lazyvim.util").safe_keymap_set("n", "<leader>bh", function()
--   require("lazyvim.util").toggle("laststatus", false, { 0, 2 })
-- end, { noremap = true, silent = true })

-- vim.keymap.set(
--   "n",
--   "<leader>th",
--   "<cmd>FloatermNew --width=0.8 --height=0.8 man -k . | fzf | awk '{print $1}' | xargs man<cr>",
--   { silent = true, noremap = true, desc = "Man" }
-- )

-- 在 Visual 模式下绑定 <leader>y 到复制到剪贴板(wsl2)命令
vim.keymap.set("v", "<leader>y", [["+y <cmd>call system('clip.exe', @+)<cr>]], { noremap = true, silent = true })

-- 打开日记文件
-- vim.keymap.set(
--   "n",
--   "<leader>td",
--   "<cmd>execute 'edit /mnt/d/OneDrive - st.gxu.edu.cn/CSNote/Diary/' . strftime('%Y/%m/%Y-%m-%d') . '.md' | silent w<cr>",
--   { noremap = true, silent = true }
-- )

vim.keymap.set("n", "<leader>td", function()
  local os_date = os.date
  local diary_path = "/mnt/d/OneDrive - st.gxu.edu.cn/CSNote/Diary/"

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
  vim.cmd("edit " .. file_path)
end, { noremap = true, silent = true, desc = "dayliy note" })

vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true })

vim.keymap.set("n", "<Tab>", "<cmd>tabnext<cr>", { silent = true, noremap = true })
vim.keymap.set("n", "<S-Tab>", "<cmd>tabprevious<cr>", { silent = true, noremap = true })

vim.keymap.del("n", "<leader>l")
vim.keymap.set("n", "<leader>p", "<cmd>Lazy<cr>", { desc = "Lazy" })
