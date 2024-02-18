-- INFO: Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 检查 tmux 环境的 Lua 脚本

-- if os.getenv("TMUX") then
vim.g.clipboard = {
  name = "TmuxClipboard",
  copy = {
    ["+"] = "tmux load-buffer -w -",
    ["*"] = "tmux load-buffer -w -",
  },
  paste = {
    ["+"] = "tmux save-buffer -",
    ["*"] = "tmux save-buffer -",
  },
  cache_enabled = 1, -- 要设置成1，不然使用x或者d的时候鼠标会闪烁
}
-- else
--   vim.g.clipboard = {
--     name = "WslClipboard",
--     copy = {
--       ["+"] = "clip.exe",
--       ["*"] = "clip.exe",
--     },
--     paste = {
--       ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
--       ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
--     },
--     cache_enabled = 1,
--   }
-- end

vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.list = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.relativenumber = false
vim.opt.autowrite = true
vim.opt.autoread = true
vim.opt.scrolloff = 7 -- Lines of context
-- vim.go.guicursor = "a:block"
vim.g.autoformat = false
vim.g.python3_host_prog = "/usr/bin/python3"
vim.g.node_host_prog = "/usr/local/lib/node_modules/neovim/bin/cli.js"
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0


vim.o.report = 100 -- 为了关闭行数提示

-- floaterm

-- init.lua

-- 启用当前行高亮
vim.wo.cursorline = true
-- 设置当前行高亮的选项为同时显示行号
vim.wo.cursorlineopt = "number"

-- NOTE: asyncrun 的配置
vim.g.asyncrun_open = 12
vim.g.VimuxHeight = "50"
vim.g.VimuxOrientation = "h"

-- 手动fold
vim.opt.foldmethod = "manual"
