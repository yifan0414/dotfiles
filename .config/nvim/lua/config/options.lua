-- INFO: Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 检查 tmux 环境的 Lua 脚本

-- if os.getenv("TMUX") then
vim.g.clipboard = {
  name = "TmuxClipboard",
  copy = {
    ["+"] = "tmux load-buffer -w -",
    ["*"] = "tmux load-buffer -w -",
  },
  paste = {
    ["+"] = "tmux save-buffer -",
    ["*"] = "tmux save-buffer -",
  },
  cache_enabled = 1, -- 要设置成1，不然使用x或者d的时候鼠标会闪烁
}
-- else
--   vim.g.clipboard = {
--     name = "WslClipboard",
--     copy = {
--       ["+"] = "clip.exe",
--       ["*"] = "clip.exe",
--     },
--     paste = {
--       ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
--       ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
--     },
--     cache_enabled = 1,
--   }
-- end

vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.list = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.relativenumber = false
vim.opt.autowrite = true
vim.opt.autoread = true
vim.opt.scrolloff = 7 -- Lines of context
vim.go.guicursor = "a:block"
vim.g.autoformat = false
vim.g.python3_host_prog = "/usr/bin/python3"
vim.g.node_host_prog = "/usr/local/lib/node_modules/neovim/bin/cli.js"
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.o.report = 100 -- 为了关闭行数提示

-- floaterm

-- init.lua

-- 启用当前行高亮
vim.wo.cursorline = true
-- 设置当前行高亮的选项为同时显示行号
vim.wo.cursorlineopt = "number"

-- NOTE: asyncrun 的配置
vim.g.asyncrun_open = 12
vim.g.VimuxHeight = "50"
vim.g.VimuxOrientation = "h"

-- 手动fold
vim.opt.foldmethod = "manual"

vim.g.indent_blankline_context_patterns = {
  "abstract_class_declaration",
  "abstract_method_signature",
  "accessibility_modifier",
  "ambient_declaration",
  "arguments",
  "array",
  "array_pattern",
  "array_type",
  "arrow_function",
  "as_expression",
  "asserts",
  "assignment_expression",
  "assignment_pattern",
  "augmented_assignment_expression",
  "await_expression",
  "binary_expression",
  "break_statement",
  "call_expression",
  "call_signature",
  "catch_clause",
  "class",
  "class_body",
  "class_declaration",
  "class_heritage",
  "computed_property_name",
  "conditional_type",
  "constraint",
  "construct_signature",
  "constructor_type",
  "continue_statement",
  "debugger_statement",
  "declaration",
  "decorator",
  "default_type",
  "do_statement",
  "else_clause",
  "empty_statement",
  "enum_assignment",
  "enum_body",
  "enum_declaration",
  "existential_type",
  "export_clause",
  "export_specifier",
  "export_statement",
  "expression",
  "expression_statement",
  "extends_clause",
  "finally_clause",
  "flow_maybe_type",
  "for_in_statement",
  "for_statement",
  "formal_parameters",
  "function",
  "function_declaration",
  "function_signature",
  "function_type",
  "generator_function",
  "generator_function_declaration",
  "generic_type",
  "if_statement",
  "implements_clause",
  "import",
  "import_alias",
  "import_clause",
  "import_require_clause",
  "import_specifier",
  "import_statement",
  "index_signature",
  "index_type_query",
  "infer_type",
  "interface_declaration",
  "internal_module",
  "intersection_type",
  "jsx_attribute",
  "jsx_closing_element",
  "jsx_element",
  "jsx_expression",
  "jsx_fragment",
  "jsx_namespace_name",
  "jsx_opening_element",
  "jsx_self_closing_element",
  "labeled_statement",
  "lexical_declaration",
  "literal_type",
  "lookup_type",
  "mapped_type_clause",
  "member_expression",
  "meta_property",
  "method_definition",
  "method_signature",
  "module",
  "named_imports",
  "namespace_import",
  "nested_identifier",
  "nested_type_identifier",
  "new_expression",
  "non_null_expression",
  "object",
  "object_assignment_pattern",
  "object_pattern",
  "object_type",
  "omitting_type_annotation",
  "opting_type_annotation",
  "optional_parameter",
  "optional_type",
  "pair",
  "pair_pattern",
  "parenthesized_expression",
  "parenthesized_type",
  "pattern",
  "predefined_type",
  "primary_expression",
  "program",
  "property_signature",
  "public_field_definition",
  "readonly_type",
  "regex",
  "required_parameter",
  "rest_pattern",
  "rest_type",
  "return_statement",
  "sequence_expression",
  "spread_element",
  "statement",
  "statement_block",
  "string",
  "subscript_expression",
  "switch_body",
  "switch_case",
  "switch_default",
  "switch_statement",
  "template_string",
  "template_substitution",
  "ternary_expression",
  "throw_statement",
  "try_statement",
  "tuple_type",
  "type_alias_declaration",
  "type_annotation",
  "type_arguments",
  "type_parameter",
  "type_parameters",
  "type_predicate",
  "type_predicate_annotation",
  "type_query",
  "unary_expression",
  "union_type",
  "update_expression",
  "variable_declaration",
  "variable_declarator",
  "while_statement",
  "with_statement",
  "yield_expression",
}
