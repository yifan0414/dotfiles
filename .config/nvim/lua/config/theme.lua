local M = {}

function M.colorscheme()
  if vim.o.background == "light" then
    return "catppuccin-latte"
  end

  return "kanagawa"
end

function M.apply()
  vim.cmd.colorscheme(M.colorscheme())
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
