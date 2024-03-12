return {
  "lewis6991/satellite.nvim",
  event = "LazyFile",
  config = function()
    require("satellite").setup({
      current_only = false,
      winblend = 100,
      zindex = 40,
      excluded_filetypes = {
        "Outline",
        "neo-tree",
      },
      width = 2,
      handlers = {
        cursor = {
          enable = true,
          symbols = { "•" },
          overlap = true,
          priority = 1000,
        },
        search = {
          enable = true,
          -- Highlights:
          -- - SatelliteSearch (default links to Search)
          -- - SatelliteSearchCurrent (default links to SearchCurrent)
        },
        diagnostic = {
          enable = true,
          signs = { "-", "=", "≡" },
          min_severity = vim.diagnostic.severity.HINT,
          -- Highlights:
          -- - SatelliteDiagnosticError (default links to DiagnosticError)
          -- - SatelliteDiagnosticWarn (default links to DiagnosticWarn)
          -- - SatelliteDiagnosticInfo (default links to DiagnosticInfo)
          -- - SatelliteDiagnosticHint (default links to DiagnosticHint)
        },
        gitsigns = {
          enable = false,
          signs = { -- can only be a single character (multibyte is okay)
            add = "│",
            change = "│",
            delete = "-",
          },
        },
        marks = {
          enable = true,
          show_builtins = false, -- shows the builtin marks like [ ] < >
          key = "m",
          -- Highlights:
          -- SatelliteMark (default links to Normal)
        },
        quickfix = {
          enable = true,
          signs = { "-", "=", "≡" },
          overlap = true,
          priority = 1000,
          -- Highlights:
          -- SatelliteQuickfix (default links to WarningMsg)
        },
      },
    })
  end,
}
