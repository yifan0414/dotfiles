return {
  "folke/noice.nvim",
  event = "VeryLazy",
  -- init = function()
  --   vim.o.incsearch = false -- this causes a flicker when searching maybe fixed when new version is release?
  -- end,
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
    routes = {
      {
        filter = {
          event = "msg_show",
          any = {
            { find = "%d+L, %d+B" },
            { find = "; after #%d+" },
            { find = "; before #%d+" },
            { find = "%d fewer lines" },
            { find = "%d more lines" },
            { find = "No active Snippet" },
          },
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = {
          skip = true,
        },
      },
    },
    presets = {
      bottom_search = false,
      command_palette = true,
      long_message_to_split = true,
      inc_rename = true,
      lsp_doc_border = false,
    },
    messages = {
      view_search = false,
    },
    lsp = {
      progress = {
        enabled = false,
        -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
        -- See the section on formatting for more details on how to customize.
        format = "lsp_progress",
        format_done = "lsp_progress_done",
        throttle = 1000 / 30, -- frequency to update lsp progress message
        view = "mini",
      },

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
      signature = {
        enabled = false,
        auto_open = {
          enabled = true,
        },
        opts = {
          size = {
            max_width = 60,
            max_height = 10,
          },
        },
      },
      documentation = {
        view = "hover",
        opts = {
          size = {
            -- max_width = 70,
            -- max_length = 50,
          },
          -- "double"|"none"|"rounded"|"shadow"|"single"|"solid"
          border = { style = "rounded" },
          -- border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
          relative = "cursor",
          position = {
            row = 2,
            col = 2,
          },
        },
      },
    },
  },
}
