local ls = require("luasnip")
local t = ls.text_node

local treesitter_postfix = require("luasnip.extras.treesitter_postfix").treesitter_postfix

return {
  treesitter_postfix({
    trig = ".testing",
    matchTSNode = {
      query = [[(call_expression) @prefix]],
      query_lang = "rust",
    },
  }, { t("hello") }),
}
