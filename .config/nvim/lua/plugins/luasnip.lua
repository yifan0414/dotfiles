return {
  "L3MON4D3/LuaSnip",
  event = "InsertEnter",
  -- follow latest release.
  -- version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
  -- install jsregexp (optional!).
  -- build = "make install_jsregexp",
  config = function()
    local luasnip = require("luasnip")
    luasnip.setup({
      enable_autosnippets = true,
    })
    require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    require("luasnip.loaders.from_lua").lazy_load({ paths = "./snippets_lua" })
  end,
}
