return {
  {
    -- lspconfig
    "neovim/nvim-lspconfig",
    -- event = "LazyFile",
    -- options for vim.diagnostic.config()
    -- dependencies = {
    -- "mason.nvim",
    -- { "williamboman/mason-lspconfig.nvim", config = function() end },
    -- },
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
            -- [vim.diagnostic.severity.ERROR] = " ",
            -- [vim.diagnostic.severity.WARN] = " ",
            -- [vim.diagnostic.severity.HINT] = "󰋽 ",
            -- [vim.diagnostic.severity.INFO] = "󰋽 ",

            [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
            -- [vim.diagnostic.severity.HINT] = "󱐮",
            -- [vim.diagnostic.severity.ERROR] = "✘",
            -- [vim.diagnostic.severity.INFO] = "◉",
            -- [vim.diagnostic.severity.WARN] = "",
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
                  reportAttributeAccessIssue = "none",

                  -- reportMissingImports = "none", -- 禁用报告缺少导入的诊断
                  -- reportGeneralTypeIssues = "none", -- 禁用报告一般类型问题的诊断
                  -- reportUndefinedVariable = "none", -- 禁用未定义变量的报告
                  -- reportUnusedImport = "none", -- 禁用未使用导入的报告
                  -- -- 如果你想禁用 F405 错误代码，可以设置为 "none"（对于某些插件可能有效）
                  -- reportStarImport = "none", -- 禁用通过星号导入的警告
                },
              },
            },
          },
          -- python = {
          --   analysis = {
          --     -- Ignore all files for analysis to exclusively use Ruff for linting
          --     ignore = { "error" },
          --   },
          -- },
          -- capabilities = {
          --   textDocument = {
          --     publishDiagnostics = {
          --       tagSupport = {
          --         valueSet = { 3 },
          --       },
          --     },
          --   },
          -- },
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
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(
              "Makefile",
              "configure.ac",
              "configure.in",
              "config.h.in",
              "meson.build",
              "meson_options.txt",
              "build.ninja"
            )(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(
              fname
            ) or require("lspconfig.util").find_git_ancestor(fname)
          end,
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
        },
      },
      setup = {
        -- clangd = function(_, opts)
        --   opts.capabilities.textDocument.completion.completionItem.snippetSupport = false
        --   opts.capabilities.offsetEncoding = { "utf-16" }
        -- end,
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
    enabled = false,
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
