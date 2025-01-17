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

local expr_query = [[
            [
              (call_expression)
              (identifier)
              (type_identifier)
              (subscript_expression)
              (field_expression)
            ] @prefix
]]

ls.add_snippets("cpp", {
  treesitter_postfix(
    {
      trig = ".sc",
      name = "(.sc) static_cast<TYPE>(?)",
      dscr = "Wraps an expression with static_cast<TYPE>(?)",
      wordTrig = false,
      reparseBuffer = "live",
      snippetType = "autosnippet",
      matchTSNode = {
        query = expr_query,
        query_lang = "cpp",
      },
    },
    fmt(
      [[
      static_cast<{body}>({expr}){end}
      ]],
      {
        body = i(1),
        expr = f(function(_, parent)
          return parent.snippet.env.LS_TSMATCH
        end, {}),
        ["end"] = i(0),
      }
    )
  ),
  treesitter_postfix(
    {
      trig = ".mv",
      matchTSNode = {
        query = expr_query,
        query_lang = "cpp",
        select = "longest",
      },
      reparseBuffer = "live",
      snippetType = "autosnippet",
    },
    fmt(
      [[
          std::move({expr})
      ]],
      {
        expr = f(function(_, parent)
          return parent.snippet.env.LS_TSMATCH
        end, {}),
      }
    )
  ),

  treesitter_postfix(
    {
      trig = ".cout",
      matchTSNode = {
        query = expr_query,
        query_lang = "cpp",
        select = "longest",
      },
      reparseBuffer = "live",
      snippetType = "autosnippet",
    },
    fmt(
      [[
          cout << {expr} << endl;
      ]],
      {
        expr = f(function(_, parent)
          return parent.snippet.env.LS_TSMATCH
        end, {}),
      }
    )
  ),

  postfix({
    trig = ".printf",
    trigEngine = "ecma",
    match_pattern = "[%w%.%_%->%[%]]+$",
    snippetType = "autosnippet",
  }, {
    t('printf("'),
    f(function(_, parent)
      return parent.snippet.env.POSTFIX_MATCH .. " = %"
    end),
    i(1, "d"), -- 用户输入的格式化类型，如 %d, %f 等
    t('\\n", '),
    f(function(_, parent)
      return parent.snippet.env.POSTFIX_MATCH .. ");"
    end),
  }),

  -- postfix({
  --   trig = "\\.cout",
  --   trigEngine = "ecma",
  --   match_pattern = "[%w%.%_%->%[%]]+$",
  --   snippetType = "autosnippet",
  -- }, {
  --   f(function(_, parent)
  --     return "cout << " .. parent.snippet.env.POSTFIX_MATCH .. " << endl;"
  --   end),
  -- }),

  postfix({
    trig = ".all",
    trigEngine = "ecma",
    match_pattern = "[%w%.%_%->%[%]]+$",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return parent.snippet.env.POSTFIX_MATCH .. ".begin(), " .. parent.snippet.env.POSTFIX_MATCH .. ".end()"
    end),
  }),

  postfix({
    trig = ".scanf",
    trigEngine = "ecma",
    match_pattern = "[%w%.%_%->%[%]]+$",
    snippetType = "autosnippet",
  }, {
    t('scanf("%'),
    i(1, "d"), -- 第一个输入节点，让用户输入想要的格式化字符串或数字
    f(function(_, parent)
      -- 使用用户输入的格式化字符串来构造 scanf 或 cin 的参数
      -- local format_str = args[1][1] -- 获取第一个输入节点的内容
      return '", &' .. parent.snippet.env.POSTFIX_MATCH .. ");"
    end, i(0), { 1 }), -- 依赖于第一个输入节点的内容
  }),

  postfix({
    trig = ".cin",
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
    trigEngine = "ecma",
    match_pattern = "[%w%.%_%->%[%]]+$",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "cerr << " .. parent.snippet.env.POSTFIX_MATCH .. " << endl;"
    end),
  }),

  postfix({
    trig = ".for",
    match_pattern = "[%w%.%_%->%[%]%(%)]+$",
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

  postfix({
    trig = ".2d",
    match_pattern = "[%w%.%_%->%[%]%(%)]+$",
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {

    t("vector<vector<"),
    i(1, "int"), -- 这是你将要替换的循环变量名
    t(">> "),
    f(function(_, parent)
      return parent.snippet.env.POSTFIX_MATCH .. "("
    end, { 1 }), -- 使用之前插入点的值
    -- t({"("}),
    i(2, "n"),
    f(function(args)
      return ", vector<" .. args[1][1] .. ">"
    end, { 1 }), -- 根据第1个插入点动态更新
    t("("),
    i(3, "n"),
    t(", 0));"),
    -- d(3, function(args)
    --   local varName = args[2][1] -- 获取第2个插入点的内容
    --   return sn(nil, {
    --     t("(" .. varName .. ", 0));"), -- 使用变量名创建动态代码片段
    --   })
    -- end, { 1, 2 }),
  }),

  postfix({
    trig = ".3d",
    match_pattern = "[%w%.%_%->%[%]%(%)]+$",
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {

    t("vector<vector<vector<"),
    i(1, "int"), -- 这是你将要替换的循环变量名
    t(">>> "),
    f(function(_, parent)
      return parent.snippet.env.POSTFIX_MATCH .. "("
    end, { 1 }), -- 使用之前插入点的值
    i(2, "n"),
    f(function(args)
      return ", vector<vector<" .. args[1][1] .. ">>"
    end, { 1 }), -- 根据第1个插入点动态更新
    d(3, function(args)
      local varName = args[2][1] -- 获取第2个插入点的内容
      return sn(nil, {
        t("(" .. varName .. ", vector<" .. args[1][1] .. ">(" .. varName .. ", 0)));"), -- 使用变量名创建动态代码片段
      })
    end, { 1, 2 }),
  }),

  postfix({
    trig = ".range",
    match_pattern = "[%w%.%_%->%[%]%(%)]+$",
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, _)
      return "for (const auto &"
    end),
    i(1, "it"), -- 这是你将要替换的循环变量名
    f(function(_, parent)
      return " : " .. parent.snippet.env.POSTFIX_MATCH .. ")"
    end, { 1 }), -- 使用之前插入点的值
    t({ " {" }),
    t({ "", "\t" }),
    i(0),
    t({ "", "}" }),
  }),

  postfix({
    trig = ".sort",
    match_pattern = "[%w%.%_%->%[%]%(%)]+$",
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "sort("
        .. parent.snippet.env.POSTFIX_MATCH
        .. ".begin(), "
        .. parent.snippet.env.POSTFIX_MATCH
        .. ".end());"
    end),
  }),

  postfix({
    trig = ".post",
    match_pattern = "[%w%.%_%->%[%]%(%)]+$",
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    i(1),
    f(function(_, parent)
      return "(" .. parent.snippet.env.POSTFIX_MATCH .. ".begin(), " .. parent.snippet.env.POSTFIX_MATCH .. ".end());"
    end),
  }),
})
