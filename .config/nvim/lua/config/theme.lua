local M = {}

-- local function diagnostic_sp(name)
--   local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
--   return hl.fg or hl.sp
-- end
--
-- local function apply_diagnostic_undercurl()
--   local groups = {
--     Error = "DiagnosticError",
--     Warn = "DiagnosticWarn",
--     Info = "DiagnosticInfo",
--     Hint = "DiagnosticHint",
--     Ok = "DiagnosticOk",
--   }
--
--   for suffix, source in pairs(groups) do
--     local spec = { undercurl = true }
--     local sp = diagnostic_sp(source)
--     if sp then
--       spec.sp = sp
--     end
--     vim.api.nvim_set_hl(0, "DiagnosticUnderline" .. suffix, spec)
--   end
-- end

function M.colorscheme()
  if vim.o.background == "light" then
    return "catppuccin-latte"
  end

  return "kanagawa"
end

function M.apply()
  local colorscheme = M.colorscheme()
  if vim.g.colors_name == colorscheme then
    return
  end

  if colorscheme == "onedark" then
    require("onedark").load()
    -- apply_diagnostic_undercurl()
    return
  end

  if colorscheme == "catppuccin-latte" then
    require("catppuccin").load("latte")
    -- apply_diagnostic_undercurl()
    return
  end

  require("kanagawa").load()
  -- apply_diagnostic_undercurl()
end

local function catppuccin_flavour()
  local colors_name = vim.g.colors_name or ""
  local flavour = colors_name:match("^catppuccin%-(%w+)$")

  if flavour then
    return flavour
  end

  if package.loaded["catppuccin"] then
    local ok, catppuccin = pcall(require, "catppuccin")
    if ok and catppuccin.flavour then
      return catppuccin.flavour
    end
  end

  return vim.o.background == "light" and "latte" or "frappe"
end

function M.inactive_winbar_colors()
  local colors_name = vim.g.colors_name or ""

  if colors_name == "onedark" then
    local palette = require("onedark.palette").light
    return { fg = palette.fg, bg = palette.bg1 }
  end

  if colors_name:find("^catppuccin") then
    local palette = require("catppuccin.palettes").get_palette(catppuccin_flavour())
    return { fg = palette.text, bg = palette.mantle }
  end

  local kanagawa = require("kanagawa")
  local theme = kanagawa.config.background[vim.o.background] or kanagawa.config.theme
  local colors = require("kanagawa.colors").setup({
    theme = theme,
    colors = kanagawa.config.colors,
  })

  return { fg = colors.theme.ui.fg, bg = colors.theme.ui.bg_m1 }
end

return M
