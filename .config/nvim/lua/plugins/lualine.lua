return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  config = function()
    -- PERF: we don't need this lualine require madness 🤷
    local icons = LazyVim.config.icons
    vim.o.laststatus = vim.g.lualine_laststatus
    local colors = require("kanagawa.colors").setup()
    local palette_colors = colors.palette
    local theme_colors = colors.theme
    require("lualine").setup({

      winbar = {
        lualine_c = {
          {
            "filetype",
            colored = true, -- Displays filetype icon in color if set to true
            icon_only = true, -- Display only an icon for filetype
            -- icon = { align = "right" }, -- Display filetype icon on the right hand side
            padding = { left = 1, right = -2 },
            -- icon =    {'X', align='right'}
            -- Icon string ^ in table is ignored in filetype component
            -- color = { bg = "#1e1e2f" },
            -- color = { bg = "2a2a37" },
            fmt = function(str)
              if str == "" then
                return "" -- 默认图标（例如，文档图标）
              end
              return str
            end,
          },
          {
            function()
              local filename = vim.fn.expand("%:t")
              local _, type = filename:match("^(CompetiTest)(%a+)(%d+)$")
              if type then
                return type
              else
                return filename
              end
            end,
            padding = { left = -2 },
          },
          {
            function()
              return "› " .. require("nvim-navic").get_location()
            end,
            cond = function()
              return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
            end,
          },
        },
      },
      inactive_winbar = {
        lualine_c = {
          {
            "filetype",
            -- colored = true, -- Displays filetype icon in color if set to true
            icon_only = true, -- Display only an icon for filetype
            padding = { left = 1, right = -2 },
            fmt = function(str)
              if str == "" then
                return "" -- 默认图标（例如，文档图标）
              end
              return str
            end,
            color = { fg = palette_colors.fujiWhite, bg = palette_colors.sumiInk4 },
          },
          {
            function()
              local filename = vim.fn.expand("%:t")
              local _, type = filename:match("^(CompetiTest)(%a+)(%d+)$")
              if type then
                return type
              else
                return filename
              end
            end,
            padding = { left = -2 },
            color = { fg = palette_colors.fujiWhite, bg = palette_colors.sumiInk4 },
          },
          {
            function()
              return "› " .. require("nvim-navic").get_location()
            end,
            cond = function()
              return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
            end,
            color = { fg = palette_colors.fujiWhite, bg = palette_colors.sumiInk4 },
            -- padding = { left = -2 },
          },
        },
      },

      inactive_sections = {
        lualine_a = { "filename" },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { "location" },
      },
      tabline = {},
      options = {
        component_separators = "",
        section_separators = "",
        -- theme = "vscode",
        theme = "kanagawa",
        globalstatus = vim.o.laststatus == 3,
        disabled_filetypes = {
          statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" },
          winbar = {
            "neo-tree",
            "Outline",
            -- "Trouble",
            "qf",
            "leetcode.nvim",
            "dap-repl",
            "snacks_dashboard",
            -- "CompetiTest",
          },
          inactive_winbar = {
            -- "CompetiTest",
          },
        },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },

        lualine_c = {
          LazyVim.lualine.root_dir(),
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
          -- {
          --   "filetype",
          --   icon_only = true,
          --   padding = { left = 1, right = 0 },
          --   fmt = function(str)
          --     if str == "" then
          --       return "" -- 默认图标（例如，文档图标）
          --     end
          --     return str
          --   end,
          -- },
          -- { LazyVim.lualine.pretty_path(), separator = "›" },
        },
        lualine_x = {
          "searchcount",
          Snacks.profiler.status(),
          -- stylua: ignore
          {
            function() return require("noice").api.status.command.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
            color = function() return { fg = Snacks.util.color("Statement") } end,
          },
          -- stylua: ignore
          {
            function() return require("noice").api.status.mode.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
            color = function() return { fg = Snacks.util.color("Constant") } end,
          },
          -- stylua: ignore
          {
            function() return "  " .. require("dap").status() end,
            cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
            color = function() return { fg = Snacks.util.color("Debug") } end,
          },
          -- stylua: ignore
          {
            require("lazy.status").updates,
            cond = require("lazy.status").has_updates,
            color = function() return { fg = Snacks.util.color("Special") } end,
          },
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
        },
        lualine_y = {
          {
            "progress",
            padding = { left = 1, right = 1 },
            color = { bg = palette_colors.crystalBlue, fg = palette_colors.sumiInk0 },
          },
          {
            "location",
            padding = { left = 0, right = 1 },
            color = { bg = palette_colors.crystalBlue, fg = palette_colors.sumiInk0 },
          },
        },
        lualine_z = {
          -- function()
          --   return " " .. os.date("%R")
          -- end,
        },
      },
      extensions = { "neo-tree", "lazy", "fzf" },
    })
  end,
}
