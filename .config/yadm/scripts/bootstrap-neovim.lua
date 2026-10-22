-- Lazy installs missing plugins during startup. Wait for its asynchronous tools too.
local ok, err = xpcall(function()
  require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter" } })
  local config = require("lazy.core.config")
  for name, plugin in pairs(config.plugins) do
    assert(plugin._.installed and not require("lazy.core.plugin").has_errors(plugin), "Plugin failed: " .. name)
  end

  local registry = require("mason-registry")
  local tools = LazyVim.opts("mason.nvim").ensure_installed or {}
  local parsers = LazyVim.opts("nvim-treesitter").ensure_installed or {}
  local missing = {}
  local done = vim.wait(300000, function()
    missing = {}
    for _, name in ipairs(tools) do
      if not registry.has_package(name) or not registry.get_package(name):is_installed() then
        missing[#missing + 1] = name
      end
    end
    local installed = require("nvim-treesitter").get_installed("parsers")
    for _, name in ipairs(parsers) do
      if not vim.tbl_contains(installed, name) then
        missing[#missing + 1] = "parser:" .. name
      end
    end
    for _, package in ipairs(registry.get_all_packages()) do
      if package:is_installing() then
        return false
      end
    end
    return #missing == 0
  end, 200)
  assert(done, "Neovim dependencies incomplete: " .. table.concat(missing, ", "))
  assert(vim.v.errmsg == "", vim.v.errmsg)
end, debug.traceback)

if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
else
  print("Neovim plugins and tools ready")
  vim.cmd("qa")
end
