vim.keymap.set("n", "<leader>;", "<cmd>e #<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>`", "<cmd>wincmd p<cr>", { noremap = true, silent = true })

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
  { desc = "search word in quickfix(root dir)", noremap = true, silent = true }
)

-- So I can move around in insert
vim.keymap.set("i", "<C-k>", "<C-o>gk", { noremap = true, silent = true })
vim.keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-j>", "<C-o>gj", { noremap = true, silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true })

-- 在 Visual 模式下绑定 <leader>y 到复制到剪贴板(wsl2)命令
vim.keymap.set("v", "<leader>y", [["+y <cmd>call system('clip.exe', @+)<cr>]], { noremap = true, silent = true })

vim.keymap.set("n", "<leader>td", function()
  local os_date = os.date
  local diary_path = "~/org/"

  -- 获取当前日期
  local year = os_date("%Y")
  local month = os_date("%m")
  local day = os_date("%Y-%m-%d")

  -- 构建文件路径
  local file_path = diary_path .. year .. "/" .. month .. "/" .. day .. ".org"

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

-- vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true })

vim.keymap.set("n", "<leader><tab>n", "<cmd>tabnext<cr>", { silent = true, noremap = true })
vim.keymap.set("n", "<leader><tab>p", "<cmd>tabprevious<cr>", { silent = true, noremap = true })

vim.keymap.del("n", "<leader>l")
vim.keymap.set("n", "<leader>p", "<cmd>Lazy<cr>", { desc = "Lazy" })
vim.keymap.set("n", "<leader>qw", "<cmd>q<cr>", { silent = true, noremap = true, desc = "quit" })

vim.keymap.set("n", "#", "*", { noremap = true })
vim.keymap.set("n", "*", "#", { noremap = true })

-- delete current line mark
vim.api.nvim_create_user_command("Delmarks", function()
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
end, {})

vim.api.nvim_set_keymap("n", "dm", "<cmd>Delmarks<CR>", { silent = true, noremap = true })
