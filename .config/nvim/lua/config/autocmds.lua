-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  pattern = { "*" },
  command = "silent! wall",
  nested = true,
})

-- 关闭新行注释
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
  end,
})

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})

local group = vim.api.nvim_create_augroup("SetCommentString", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost" }, {
  group = group,
  pattern = { "*.cpp", "*.h" },
  command = "lua vim.api.nvim_buf_set_option(0, 'commentstring', '// %s')",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "query",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
    "fugitive",
    "fugitiveblame",
    "git",
    "floaterm",
    "org",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- 去掉markdown文件的下滑线
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  command = "hi Underlined gui=none",
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ timeout = 100 })
  end,
})

-- local augroup = vim.api.nvim_create_augroup("user_diagnostic", { clear = true })
-- local autocmd = vim.api.nvim_create_autocmd
--
-- autocmd("ModeChanged", {
--   group = augroup,
--   pattern = { "n:i", "n:v", "i:v" },
--   command = "lua vim.diagnostic.disable(0)",
-- })
--
-- autocmd("ModeChanged", {
--   group = augroup,
--   pattern = "i:n",
--   command = "lua vim.diagnostic.enable(0)",
-- })

-- You can add this in your init.lua
-- or a plugin script

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = { "n:i", "v:s" },
  desc = "Disable diagnostics in insert and select mode",
  callback = function(e)
    vim.diagnostic.disable(e.buf)
  end,
})

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "i:n",
  desc = "Enable diagnostics when leaving insert mode",
  callback = function(e)
    vim.diagnostic.enable(e.buf)
  end,
})

-- inlay_hint autocmd

-- vim.api.nvim_create_autocmd({ "InsertLeave" }, {
--   callback = function()
--     vim.lsp.inlay_hint.enable(0, true)
--   end,
-- })
--
-- vim.api.nvim_create_autocmd({ "InsertEnter" }, {
--   callback = function()
--     vim.lsp.inlay_hint.enable(0, false)
--   end,
-- })
