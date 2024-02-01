-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  pattern = { "*" },
  command = "silent! wall",
  nested = true,
})

-- vim.api.nvim_create_autocmd("User", {
--   pattern = "AsyncRunStart",
--   group = "asyncrun_augroup",
--   command = "copen",
-- })

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
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})


vim.api.nvim_create_autocmd("CmdwinEnter", {
  group = augroup("close_with_q"),
  pattern = "*",
  callback = function()
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = 0, silent = true })
  end,
})

