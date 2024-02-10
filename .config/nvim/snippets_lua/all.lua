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

ls.setup({
  keep_roots = true,
  link_roots = true,
  link_children = true,

  -- Update more often, :h events for more info.
  update_events = "TextChanged,TextChangedI",
  -- Snippets aren't automatically removed if their text is deleted.
  -- `delete_check_events` determines on which events (:h events) a check for
  -- deleted snippets is performed.
  -- This can be especially useful when `history` is enabled.
  delete_check_events = "TextChanged",
  ext_opts = {
    [types.choiceNode] = {
      active = {
        virt_text = { { "choiceNode", "Comment" } },
      },
    },
  },
  -- treesitter-hl has 100, use something higher (default is 200).
  -- ext_base_prio = 300,
  -- minimal increase in priority.
  ext_prio_increase = 1,
  enable_autosnippets = true,
  -- mapping for cutting selected text so it's usable as SELECT_DEDENT,
  -- SELECT_RAW or TM_SELECTED_TEXT (mapped via xmap).
  store_selection_keys = "<Tab>",
  -- luasnip uses this function to get the currently active filetype. This
  -- is the (rather uninteresting) default, but it's possible to use
  -- eg. treesitter for getting the current filetype by setting ft_func to
  -- require("luasnip.extras.filetype_functions").from_cursor (requires
  -- `nvim-treesitter/nvim-treesitter`). This allows correctly resolving
  -- the current filetype in eg. a markdown-code block or `vim.cmd()`.
})

ls.add_snippets("java", {
  s({
    -- trig = "([A-Za-z\\.]*[A-Za-z]+\\d*)\\.print",
    trig = "([A-Za-z\\.]*[A-Za-z]+\\d*)(?<!StdOut)\\.print",
    -- regTrig = true,
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "StdOut.println(" .. parent.captures[1] .. ");"
    end),
  }),
  s({
    trig = "([A-Za-z\\.]*[A-Za-z]+\\d*)\\.sout",
    -- regTrig = true,
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "System.out.println(" .. parent.captures[1] .. ");"
    end),
  }),
  s({
    trig = "([A-Za-z\\.]*[A-Za-z]+\\d*)\\.for",
    -- regTrig = true,
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "for (int i = 0; i < " .. parent.captures[1] .. "; i++)"
    end),
    t({ " {", "\t" }),
    i(0),
    t({ "", "}" }),
  }),
})

ls.add_snippets("c", {
  s({
    trig = "([A-Za-z->]*[A-Za-z\\.]*[A-Za-z]+\\d*)\\.for",
    -- regTrig = true,
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "for (int i = 0; i < " .. parent.captures[1] .. "; i++)"
    end),
    t({ "", "{", "\t" }),
    i(0),
    t({ "", "}" }),
  }),
})

-- ls.add_snippets("c", {
--   postfix({
--     trig = ".iprint",
--     -- snippetType = "autosnippet",
--   }, {
--     f(function(_, parent)
--       return 'printf("' .. parent.snippet.env.POSTFIX_MATCH .. ' = %d\\n", ' .. parent.snippet.env.POSTFIX_MATCH .. ");"
--     end),
--   }),
-- })

ls.add_snippets("c", {
  s({
    -- trig = "([%a->]*[%a.]*[%a]+[%d]*).cout",
    trig = "([A-Za-z->]*[A-Za-z\\.]*[A-Za-z]+\\d*)\\.(print|cout)",
    -- regTrig = true,
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return 'printf("' .. parent.captures[1] .. ' = %d\\n", ' .. parent.captures[1] .. ");"
    end),
  }),
  s({
    -- trig = "([%a->]*[%a.]*[%a]+[%d]*).cin",
    trig = "([A-Za-z->]*[A-Za-z\\.]*[A-Za-z]+\\d*)\\.(scanf|cin)",
    -- regTrig = true,
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return 'scanf("%d", &' .. parent.captures[1] .. ");"
    end),
  }),
})

ls.add_snippets("cpp", {
  s({
    trig = "([A-Za-z->]*[A-Za-z\\.]*[A-Za-z]+\\d*)\\.(print|cout)",
    -- regTrig = true,
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "cout << " .. parent.captures[1] .. " << endl;"
    end),
  }),

  s({
    trig = "([A-Za-z->]*[A-Za-z\\.]*[A-Za-z]+\\d*)\\.(scanf|cin)",
    trigEngine = "ecma",
    snippetType = "autosnippet",
  }, {
    f(function(_, parent)
      return "cin >> " .. parent.captures[1] .. ";"
    end),
  }),
})

local function fn(
  args, -- text from i(2) in this example i.e. { { "456" } }
  parent, -- parent snippet or parent node
  user_args -- user_args from opts.user_args
)
  return "[" .. args[1][1] .. user_args .. "]"
end

ls.add_snippets("plaintex", {
  postfix( -- Insert over-line command to text via post-fix
    { trig = ".ov", snippetType = "autosnippet" },
    {
      f(function(_, parent)
        return "\\overline{" .. parent.snippet.env.POSTFIX_MATCH .. "}"
      end, {}),
    }
  ),
  s( -- Insert over-line command
    { trig = "ov", snippetType = "autosnippet" },
    fmt([[\overline{<>}]], { i(1) }, { delimiters = "<>" })
  ),
  s(
    { trig = "b(%d+)", regTrig = true },
    f(function(_, snip)
      return "Captured Text: " .. snip.captures[1]
    end, {})
  ),
  s({ trig = "c(%d+)", regTrig = true }, {
    t("will only expand for even numbers"),
  }, {
    condition = function(line_to_cursor, matched_trigger, captures)
      return tonumber(captures[1]) % 2 == 0
    end,
  }),
  s(
    { trig = "([%a]+)_([%d]+)", regTrig = true },
    f(function(_, snip)
      return snip.captures[1] .. "_{" .. snip.captures[2] .. "} "
    end)
  ),
  s(
    { trig = "([%a]+)^([%d]+)", regTrig = true },
    f(function(_, snip)
      return snip.captures[1] .. "^{" .. snip.captures[2] .. "} "
    end)
  ),
  s(
    -- { trig = "((d+)|(d*)(\\)?([A-Za-z]+)((^|_)({d+}|d))*)/", regEngine = "ecma" },
    { trig = "([%a]+)/([%a]+)", regTrig = true },
    {
      f(function(args, parent, user_args)
        return "\\frac{" .. parent.captures[1] .. "}{" .. parent.captures[2] .. "}"
      end),
    }
  ),
  s("trig", {
    i(1),
    f(function(args, snip, user_arg_1)
      return user_arg_1 .. args[1][1]
    end, { 1 }, { user_args = { "Will be appended to text from i(0)" } }),
    i(0),
  }),
  s({ trig = ";a", snippetType = "autosnippet" }, {
    t("\\alpha "),
  }),
  s({ trig = ";b", snippetType = "autosnippet" }, {
    t("\\beta "),
  }),
  s({ trig = ";g", snippetType = "autosnippet" }, {
    t("\\gamma "),
  }),

  s({ trig = ";m", snippetType = "autosnippet" }, {
    -- t("\\gamma "),
    t("$"),
    i(1),
    t("$"),
    i(0),
  }),
  s({ trig = "ff", dscr = "Expands 'ff' into '\frac{}{}'" }, {
    t("\\frac{"),
    i(1), -- insert node 1
    t("}{"),
    i(2), -- insert node 2
    t("}"),
  }),
})
