-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
--
--
vim.g.clipboard = {
  name = 'TmuxClipboard',
  copy = {
     ["+"] = 'tmux load-buffer -w -',
     ["*"] = 'tmux load-buffer -w -',
   },
  paste = {
     ["+"] = 'tmux save-buffer -',
     ["*"] = 'tmux save-buffer -',
  },
  cache_enabled = 1,
}
vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.list = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.autowrite = true
vim.opt.autoread = true
vim.opt.scrolloff = 7 -- Lines of context
vim.go.guicursor = "a:block"
vim.g.autoformat = false
vim.g.python3_host_prog = "/usr/bin/python3"
-- init.lua

-- 启用当前行高亮
vim.wo.cursorline = true

-- 设置当前行高亮的选项为同时显示行号
vim.wo.cursorlineopt = "number"

-- 改变QuickFixLine的颜色
vim.cmd([[autocmd VimEnter * hi QuickFixLine ctermfg=NONE cterm=bold guifg=NONE gui=bold]])

-- NOTE: 在最后执行设置浮动窗口的颜色
vim.cmd([[
  augroup SetNormalFloatColors
    autocmd!
    autocmd VimEnter * highlight NormalFloat guifg=#dcd7ba guibg=#1F1F28
    autocmd VimEnter * highlight FloatBorder guifg=#54546D guibg=#1F1F28
  augroup END
]])

-- vim.cmd([[
--   augroup SetNormalFloatColors
--     autocmd!
--     autocmd VimEnter * highlight NormalFloat guifg=#89B4FA guibg=#1E1E2E
--     autocmd VimEnter * highlight FloatBorder guifg=#89B4FA guibg=#1E1E2E
--   augroup END
-- ]])


-- NOTE: asyncrun 的配置
vim.g.asyncrun_open=10
vim.g.VimuxHeight="50"
vim.g.VimuxOrientation="h"

-- 手动fold
vim.opt.foldmethod="manual"
