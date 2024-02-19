return {
  -- lspconfig
  "neovim/nvim-lspconfig",
  -- options for vim.diagnostic.config()
  opts = {
    diagnostics = {
      underline = false,
      update_in_insert = false,
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
      -- virtual_text = {
      --   spacing = 4,
      --   source = "if_many",
      --   prefix = "●",
      --   -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
      --   -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
      --   -- prefix = "icons",
      -- },
      virtual_text = false,
      severity_sort = true,
    },
    servers = {
      -- Ensure mason installs the server
      clangd = {
        keys = {
          { "<leader>cR", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
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
        cmd = {
          "clangd-17",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
      },
    },
  },
}
