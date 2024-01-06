return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    cmdline = {
      format = {
        -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
        -- view: (default is cmdline view)
        -- opts: any options passed to the view
        -- icon_hl_group: optional hl_group for the icon
        -- title: set to anything or empty string to hide
        -- cmdline = { pattern = "^:", icon = "", lang = "vim" },
        search_down = { kind = "search", pattern = "^/", icon = "🔍 ", lang = "regex" },
        search_up = { kind = "search", pattern = "^%?", icon = "🔍 ", lang = "regex" },
        -- filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
        -- lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
        -- help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
        -- calculator = { pattern = "^=", icon = "", lang = "vimnormal" },
        -- input = {}, -- Used by input()
        -- lua = false, -- to disable a format, set to `false`
      },
    },
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
      -- hover = {
      --   enabled = true,
      --   opts = {
      --     border = {
      --       style = "rounded"
      --     },
      --     relative = {
      --       type = "cursor",
      --     },
      --     -- position = {
      --     --   row = 2,
      --     -- },
      --   },
      -- },
      documentation = {
        opts = {
          border = { style = "rounded" },
          relative = "cursor",
          -- position = {
          --   row = -1,
          -- },
        },
      },
    },
    -- TODO: 怎么更改hover的颜色呢？
    -- presets = {
    --   lsp_doc_border = true, -- add a border to hover docs and signature help
    -- },
  },
}
