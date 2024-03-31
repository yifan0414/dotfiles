local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

local treesitter_postfix = require("luasnip.extras.treesitter_postfix").treesitter_postfix
local postfix_builtin = require("luasnip.extras.treesitter_postfix").builtin

ls.add_snippets("lua", {
  treesitter_postfix(
    {
      matchTSNode = {
        query = [[
            (function_declaration
              name: (identifier) @fname
              parameters: (parameters) @params
              body: (block) @body
            ) @prefix
        ]],
        query_lang = "lua",
      },
      trig = ".var",
    },
    fmt(
      [[
        local {} = function{}
            {}
        end
      ]],
      {
        l(l.LS_TSCAPTURE_FNAME),
        l(l.LS_TSCAPTURE_PARAMS),
        l(l.LS_TSCAPTURE_BODY),
      }
    )
  ),
})

ls.add_snippets("rust", {
  treesitter_postfix({
    trig = ".testing",
    matchTSNode = {
      query = [[(call_expression) @prefix]],
      query_lang = "rust",
    },
  }, { t("hello") }),
})
