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
    "git",
    "floaterm",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- local fzf_lua = require("fzf-lua")
-- vim.keymap.set("n", "<leader>af", function()
--   local rows = vim.fn["asynctasks#source"](math.floor(vim.go.columns * 48 / 100))
--   fzf_lua.fzf_exec(function(cb)
--     for _, e in ipairs(rows) do
--       local color = fzf_lua.utils.ansi_codes
--       local line = color.green(e[1]) .. " " .. color.cyan(e[2]) .. ": " .. color.yellow(e[3])
--       cb(line)
--     end
--     cb()
--   end, {
--     actions = {
--       ["default"] = function(selected)
--         local str = fzf_lua.utils.strsplit(selected[1], " ")
--         local command = "AsyncTask " .. vim.fn.fnameescape(str[1])
--         vim.api.nvim_exec(command, false)
--       end,
--     },
--     fzf_opts = {
--       ["--no-multi"] = "",
--       ["--nth"] = "1",
--     },
--     winopts = {
--       height = 0.6,
--       width = 0.6,
--     },
--   })
-- end, { noremap = true, silent = true })
--
-- vim.keymap.set("n", "<leader>ad", function()
--   local tasks = vim.fn["asynctasks#source"](math.floor(vim.go.columns * 48 / 100))
--   local task_list = {}
--
--   for _, task in ipairs(tasks) do
--     table.insert(task_list, task[1] .. " " .. task[2] .. ": " .. task[3])
--   end
--
--   vim.ui.select(task_list, {
--     prompt = "Select a task:",
--   }, function(choice)
--     if choice then
--       -- vim.api.nvim_out_write("choice: " .. choice .. "\n")
--       local task_name = choice:match("^%S+")
--       -- vim.api.nvim_out_write("task: " .. task_name .. "\n")
--       local command = "AsyncTask " .. vim.fn.fnameescape(task_name)
--       -- vim.api.nvim_out_write("command: " .. command .. "\n")
--       vim.cmd(command)
--     end
--   end)
-- end, { noremap = true, silent = true })
--
-- vim.keymap.set("n", "<leader>at", function()
--   local tasks = vim.fn["asynctasks#source"](math.floor(vim.go.columns * 48 / 100))
--   local task_entries = {}
--
--   for _, task in ipairs(tasks) do
--     table.insert(task_entries, {
--       value = task[1],
--       display = task[1] .. " " .. task[2] .. ": " .. task[3],
--       ordinal = task[1] .. " " .. task[2] .. ": " .. task[3],
--     })
--   end
--
--   -- vim.api.nvim_out_write("task_entries: " .. task_entries[1] .. "\n")
--   local pickers = require("telescope.pickers")
--   local finders = require("telescope.finders")
--   local actions = require("telescope.actions")
--   local action_state = require("telescope.actions.state")
--
--   pickers
--     .new({}, {
--       prompt_title = "Select a task",
--       finder = finders.new_table({
--         results = task_entries,
--         entry_maker = function(entry)
--           return {
--             value = entry.value,
--             display = entry.display,
--             ordinal = entry.ordinal,
--           }
--         end,
--       }),
--       sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
--       attach_mappings = function(prompt_bufnr, map)
--         actions.select_default:replace(function()
--           local selection = action_state.get_selected_entry()
--           actions.close(prompt_bufnr)
--           local task_name = selection.value
--           -- vim.api.nvim_out_write("task: " .. task_name .. "\n")
--           local command = "AsyncTask " .. task_name
--           -- vim.api.nvim_out_write("command: " .. command .. "\n")
--           vim.cmd(command)
--         end)
--         return true
--       end,
--     })
--     :find()
-- end, { noremap = true, silent = true })
--
-- local pickers = require("telescope.pickers")
-- local finders = require("telescope.finders")
-- local conf = require("telescope.config").values
--
-- -- our picker function: colors
-- local colors = function(opts)
--   opts = opts or {}
--   pickers
--     .new(opts, {
--       prompt_title = "colors",
--       finder = finders.new_table({
--         results = { "red", "green", "blue" },
--       }),
--       sorter = conf.generic_sorter(opts),
--     })
--     :find()
-- end
--
