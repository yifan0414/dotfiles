local ls = require("luasnip")
local f = ls.function_node

local treesitter_postfix = require("luasnip.extras.treesitter_postfix").treesitter_postfix
local postfix_builtin = require("luasnip.extras.treesitter_postfix").builtin

ls.add_snippets("javascript", {
  treesitter_postfix(
    {
      trig = ".mv",
      matchTSNode = postfix_builtin.tsnode_matcher.find_topmost_types({
        "variable_declarator",
        "call_expression",
        "identifier",
      }),
    },
    f(function(_, parent)
      vim.print(parent.snippet.env.LS_TSMATCH)
      -- return "Hello"
      -- local node_content = table.concat(parent.snippet.env.LS_TSMATCH, '\n')
      -- local replaced_content = ("std::move(%s)"):format(node_content)
      -- return vim.split(ret_str, "\n", { trimempty = false })
    end)
  ),
})
