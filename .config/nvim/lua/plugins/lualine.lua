return {
  "nvim-lualine/lualine.nvim", -- status line
  -- event = "LazyFile",
  event = function()
    return "LazyFile"
  end,
  config = function()
    local colors = {
      blue = "#80a0ff",
      cyan = "#79dac8",
      black = "#1f1f28",
      white = "#c6c6c6",
      red = "#ff5189",
      violet = "#d183e8",
      grey = "#2a2a37",
      normal = "#7fb4ca",
      visual = "#d27e99",
      green = "#98bb6c",
    }

    local bubbles_theme = {
      normal = {
        a = { fg = colors.black, bg = colors.normal },
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.normal, bg = colors.black },
      },

      insert = { a = { fg = colors.black, bg = colors.green }, b = { fg = colors.normal, bg = colors.grey } },
      visual = { a = { fg = colors.black, bg = colors.visual } },
      replace = { a = { fg = colors.black, bg = colors.red } },
      terminal = { a = { fg = colors.black, bg = colors.cyan } },

      inactive = {
        a = { fg = colors.white, bg = colors.black },
        b = { fg = colors.white, bg = colors.black },
        c = { fg = colors.black, bg = colors.black },
      },
    }

    local mode_map = {
      ["NORMAL"] = "NORMAL",
      ["O-PENDING"] = "NORMAL",
      ["INSERT"] = "INSERT",
      ["VISUAL"] = "VISUAL",
      ["V-BLOCK"] = "V-BLOCK",
      ["V-LINE"] = "V-LINE",
      ["V-REPLACE"] = "V-REPLACE",
      ["REPLACE"] = "REPLACE",
      ["COMMAND"] = "COMMAND",
      ["SHELL"] = "SHELL",
      ["TERMINAL"] = "TERMINAL",
      ["EX"] = "EX",
      ["S-BLOCK"] = "S-BLOCK",
      ["S-LINE"] = "S-LINE",
      ["SELECT"] = "SELECT",
      ["CONFIRM"] = "CONFIRM",
      ["MORE"] = "MORE",
    }

    local icons = {
      documents = {
        File = "",
        Files = "",
        Folder = "",
        OpenFolder = "",
        EmptyFolder = "",
        EmptyOpenFolder = "",
        Unknown = "",
        Symlink = "",
        FolderSymlink = "",
      },
      git = {
        Add = " ",
        Mod = " ",
        Remove = " ",
        Untrack = " ",
        Rename = " ",
        Diff = " ",
        Repo = " ",
        Branch = " ",
        Unmerged = " ",
      },
      diagnostics = {
        Error = " ",
        Warning = " ",
        Information = " ",
        Question = " ",
        Hint = " ",
      },
      misc = {
        Robot = "󰚩 ",
        Squirrel = "  ",
        Tag = " ",
        Vim = " ",
        Neovim = " ",
      },
    }

    require("lualine").setup({
      options = {
        theme = bubbles_theme,
        component_separators = "",
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(s)
              return mode_map[s] or s
            end,
            separator = { left = "" },
            right_padding = 2,
          },
        },
        lualine_b = {
          {
            function()
              return vim.fn.fnamemodify(vim.fn.getcwd(0), ":t")
            end,
            icon = "",
            color = { fg = "#7fB4CA", gui = "bold" },
          },
          -- { "filename" },
          {
            "diff",
            symbols = {
              added = icons.git.Add,
              modified = icons.git.Mod,
              removed = icons.git.Remove,
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
        lualine_c = {
          -- { "fileformat" },
        },
        lualine_x = {
          -- {
          --   function()
          --     local space_pat = [[\v^ +]]
          --     local tab_pat = [[\v^\t+]]
          --     local space_indent = vim.fn.search(space_pat, "nwc")
          --     local tab_indent = vim.fn.search(tab_pat, "nwc")
          --     local mixed = (space_indent > 0 and tab_indent > 0)
          --     local mixed_same_line
          --     if not mixed then
          --       mixed_same_line = vim.fn.search([[\v^(\t+ | +\t)]], "nwc")
          --       mixed = mixed_same_line > 0
          --     end
          --     if not mixed then
          --       return ""
          --     end
          --     if mixed_same_line ~= nil and mixed_same_line > 0 then
          --       return "MI:" .. mixed_same_line
          --     end
          --     local space_indent_cnt = vim.fn.searchcount({ pattern = space_pat, max_count = 1e3 }).total
          --     local tab_indent_cnt = vim.fn.searchcount({ pattern = tab_pat, max_count = 1e3 }).total
          --     if space_indent_cnt > tab_indent_cnt then
          --       return "MI:" .. tab_indent
          --     else
          --       return "MI:" .. space_indent
          --     end
          --   end,
          -- },
          -- {
          --   -- 在lualine中显示当前搜索的数量
          --   function()
          --     local result = vim.fn.searchcount()
          --     return result.current .. "/" .. result.total
          --   end,
          --   color = { fg = "#ebdbb2", bg = "#3c3836" },
          --   padding = { left = 1, right = 1 },
          --   cond = function()
          --     --   -- 当我按下 esc 或者 :noh 后不显示
          --     return vim.v.hlsearch == 1
          --   end,
          -- },
          {
            "searchcount",
            color = { fg = "#ebdbb2", bg = "#3c3836" },
          },
          {
            function()
              -- 确保 `get` 函数被正确调用，并处理其返回值
              local command_status = require("noice").api.status.command.get()
              -- 根据 `command_status` 返回正确的字符串
              if command_status then
                return "⌨ " .. command_status
              else
                return ""
              end
            end,
            -- "⌨ " .. require("noice").api.status.command.get,
            cond = require("noice").api.status.command.has,
            color = { fg = "#ff9e64" },
          },
          {
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warning,
              info = icons.diagnostics.Information,
            },
            diagnostics_color = {
              color_error = { fg = colors.red },
              color_warn = { fg = colors.yellow },
              color_info = { fg = colors.cyan },
            },
          },
        },
        lualine_y = {
          {
            "branch",
            color = { fg = "#d27e99" },
          },
          { "filetype" },
          { "progress" },
        },
        lualine_z = {
          { "location", separator = { right = "" }, left_padding = 2 },
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
      extensions = {},
    })
  end,
}
