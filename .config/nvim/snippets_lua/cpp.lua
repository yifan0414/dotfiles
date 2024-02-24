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

ls.add_snippets("cpp", {

  postfix({
    trig = ".(printf|cout)",
    trigEngine = "ecma",
    match_pattern = "[%w%.%_%->%[%]]+$",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "cout << " .. parent.snippet.env.POSTFIX_MATCH .. " << endl;"
    end),
  }),

  postfix({
    trig = ".(scanf|cin)",
    trigEngine = "ecma",
    match_pattern = "[%w%.%_%->%[%]]+$",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "cin >> " .. parent.snippet.env.POSTFIX_MATCH .. ";"
    end),
  }),

  postfix({
    trig = ".cerr",
    -- trigEngine = "ecma",
    match_pattern = "[%w%.%_%->%[%]]+$",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "cerr << " .. parent.snippet.env.POSTFIX_MATCH .. " << endl;"
    end),
  }),

  postfix({
    trig = ".for",
    match_pattern = "[%w%.%_%->%[%]]+$",
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, _)
      return "for (int "
    end),
    i(1, "i"), -- 这是你将要替换的循环变量名
    f(function(args)
      return " = 0; " .. args[1][1] .. " < "
    end, { 1 }), -- 根据第1个插入点动态更新
    f(function(_, parent)
      return parent.snippet.env.POSTFIX_MATCH .. "; "
    end, { 1 }), -- 使用之前插入点的值
    d(2, function(args)
      local varName = args[1][1] -- 获取第1个插入点的内容
      return sn(nil, {
        t(varName .. "++)"), -- 使用变量名创建动态代码片段
      })
    end, { 1 }),
    t({ " {" }),
    t({ "", "\t" }),
    i(0),
    t({ "", "}" }),
  }),
})
