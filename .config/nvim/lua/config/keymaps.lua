-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- local function map(mode, lhs, rhs, opts)
--   local keys = require("lazy.core.handler").handlers.keys
--   ---@cast keys LazyKeysHandler
--   -- do not create the keymap if a lazy keys handler exists
--   if not keys.active[keys.parse({ lhs, mode = mode }).id] then
--     opts = opts or {}
--     opts.silent = opts.silent ~= false
--     if opts.remap and not vim.g.vscode then
--       opts.remap = nil
--     end
--     vim.keymap.set(mode, lhs, rhs, opts)
--   end
-- end

vim.keymap.set("n", "<leader>;", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

vim.keymap.set("n", ";", ":", { desc = "CmdLine" })

vim.keymap.set({ "n", "v" }, "0", "^", { noremap = true, silent = true })

vim.keymap.set(
  "n",
  "<leader>fa",
  "<cmd>lua vim.lsp.buf.format()<CR>",
  { noremap = true, silent = true, desc = "Format" }
)

-- 将滚轮向下映射为Ctrl-e
-- vim.keymap.set("n", "<ScrollWheelDown>", "<C-e>", { noremap = true, silent = true })

-- 将滚轮向上映射为Ctrl-y
-- vim.keymap.set("n", "<ScrollWheelUp>", "<C-y>", { noremap = true, silent = true })

-- TODO: notify 插件如何将指针切换到弹出的messages


-- 配置bufferline
vim.keymap.set("n", "t", "<cmd>BufferLinePick<CR>", {noremap = true, silent = true})

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

