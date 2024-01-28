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

require("lazyvim.util").safe_keymap_set("n", "<leader>bh", function()
  require("lazyvim.util").toggle("laststatus", false, { 0, 2 })
end, { noremap = true, silent = true })

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

vim.api.nvim_set_keymap(
  "n",
  "<leader>th",
  "<cmd>FloatermNew --width=0.8 --height=0.8 man -k . | fzf | awk '{print $1}' | xargs man<cr>",
  { silent = true, noremap = true, desc = "Man" }
)

-- 在 Visual 模式下绑定 <leader>y 到复制到剪贴板(wsl2)命令
vim.api.nvim_set_keymap("x", "<leader>y", [[:w !clip.exe<CR>]], { noremap = true, silent = true })
