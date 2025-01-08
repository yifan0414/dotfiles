return {
  "saghen/blink.cmp",
  enabled = false,
  opts = {
    keymap = {
      preset = "default",
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.accept()
          else
            return cmp.select_next()
          end
        end,
        "snippet_forward",
        "fallback",
      },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },
      ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      ["<Enter>"] = { "select_and_accept", "fallback" },
    },
    completion = {
      ghost_text = {
        enabled = false,
      },
      list = {
        selection = "auto_insert",
      },
      menu = {
        draw = {
          columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
          -- components = {
          --   kind_icon = {
          --     ellipsis = false,
          --     text = function(ctx)
          --       local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
          --       return kind_icon
          --     end,
          --     -- Optionally, you may also use the highlights from mini.icons
          --     highlight = function(ctx)
          --       local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
          --       return hl
          --     end,
          --   },
          --   label = { width = { fill = true, max = 30 } }, -- default is true
          --   label_description = { width = { fill = true } },
          -- },
        },
      },
    },
    snippets = {
      expand = function(snippet)
        require("luasnip").lsp_expand(snippet)
      end,
      active = function(filter)
        if filter and filter.direction then
          return require("luasnip").jumpable(filter.direction)
        end
        return require("luasnip").in_snippet()
      end,
      jump = function(direction)
        require("luasnip").jump(direction)
      end,
    },
    sources = {
      default = { "luasnip", "lsp", "path", "buffer", "lazydev" },
      cmdline = function()
        local type = vim.fn.getcmdtype()
        -- Search forward and backward
        if type == "/" or type == "?" then
          return { "buffer" }
        end
        -- Commands
        if type == ":" then
          return { "cmdline" }
        end
        return {}
      end,
    },
  },
}
