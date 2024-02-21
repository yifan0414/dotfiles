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
      virtual_text = true,
      severity_sort = true,
    },
    -- inlay_hints = { enabled = true },
  },
}
