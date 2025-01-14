return {
  {
    -- lspconfig
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    -- options for vim.diagnostic.config()
    opts = {
      document_highlight = {
        enabled = false,
      },
      diagnostics = {
        underline = false,
        -- update_in_insert = false,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
          -- max_width = 20,
          -- width = 20,
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰋽 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
          },
        },
        -- virtual_text = {
        --   spacing = 4,
        --   source = "if_many",
        --   prefix = "●",
        --   -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
        --   -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
        --   -- prefix = "icons",
        -- },
        -- virtual_text = false,
        severity_sort = true,
      },
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              hint = { enable = true, setType = true },
            },
          },
        },
        jdtls = {
          inlayHints = { parameterNames = { enabled = "all" } },
        },
        pyright = {
          settings = {
            python = {
              analysis = {
                diagnosticSeverityOverrides = {
                  reportIncompatibleMethodOverride = "none",
                },
              },
            },
          },
          python = {
            analysis = {
              -- Ignore all files for analysis to exclusively use Ruff for linting
              ignore = { "error" },
            },
          },
          capabilities = {
            textDocument = {
              publishDiagnostics = {
                tagSupport = {
                  valueSet = { 3 },
                },
              },
            },
          },
        },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--header-insertion-decorators=false",
          },
        },
      },
      setup = {
        clangd = function(_, opts)
          opts.capabilities.offsetEncoding = { "utf-16" }
        end,
        -- clangd = function(_, opts)
        --   opts.on_attach = function(client, _)
        --     client.server_capabilities.semanticTokensProvider = nil -- 禁用语义高亮
        --   end
        -- end,
      },
      inlay_hints = { enabled = false },
    },
  },
  -- Lazy
  {
    "dgagn/diagflow.nvim",
    enabled = false,
    event = "LspAttach", -- This is what I use personnally and it works great
    opts = {
      enable = function()
        return vim.bo.filetype ~= "lazy"
      end,
      max_width = 60, -- The maximum width of the diagnostic messages
      max_height = 10, -- the maximum height per diagnostics
      severity_colors = { -- The highlight groups to use for each diagnostic severity level
        error = "DiagnosticFloatingError",
        warning = "DiagnosticFloatingWarn",
        info = "DiagnosticFloatingInfo",
        hint = "DiagnosticFloatingHint",
      },
      format = function(diagnostic)
        return diagnostic.message
      end,
      show_sign = false, -- set to true if you want to render the diagnostic sign before the diagnostic message
      gap_size = 1,
      scope = "line", -- 'cursor', 'line' this changes the scope, so instead of showing errors under the cursor, it shows errors on the entire line.
      padding_top = 0,
      padding_right = 0,
      text_align = "right", -- 'left', 'right'
      placement = "top", -- 'top', 'inline'
      inline_padding_left = 0, -- the padding left when the placement is inline
      update_event = { "BufEnter", "DiagnosticChanged", "BufReadPost" }, -- the event that updates the diagnostics cache
      -- toggle_event = { "ModeChanged" }, -- if InsertEnter, can toggle the diagnostics on inserts
      toggle_event = { "InsertEnter", "InsertLeave" },
      render_event = { "CursorMoved", "DiagnosticChanged" },
      border_chars = {
        top_left = "╭",
        top_right = "╮",
        bottom_left = "╰",
        bottom_right = "╯",
        horizontal = "─",
        vertical = "│",
      },
      show_borders = true,
    },
  },
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      progress = {
        ignore = {
          "jdtls",
        },
      },
      -- options
    },
  },
}
