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
      violet = "#bfb1e1",
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

      command = {
        a = { fg = colors.black, bg = colors.normal },
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.normal, bg = colors.black },
      },

      insert = { a = { fg = colors.black, bg = colors.green } },
      visual = { a = { fg = colors.black, bg = colors.visual } },
      replace = { a = { fg = colors.black, bg = colors.red } },
      -- command = { a = { fg = colors.black, bg = colors.violet } },
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
      -- ["INSERT"] = "INSERT",
      -- ["VISUAL"] = "VISUAL",
      -- ["V-BLOCK"] = "V-BLOCK",
      -- ["V-LINE"] = "V-LINE",
      -- ["V-REPLACE"] = "V-REPLACE",
      -- ["REPLACE"] = "REPLACE",
      ["COMMAND"] = "NORMAL", -- 解决闪动问题
      -- ["SHELL"] = "SHELL",
      -- ["TERMINAL"] = "TERMINAL",
      -- ["EX"] = "EX",
      -- ["S-BLOCK"] = "S-BLOCK",
      -- ["S-LINE"] = "S-LINE",
      -- ["SELECT"] = "SELECT",
      -- ["CONFIRM"] = "CONFIRM",
      -- ["MORE"] = "MORE",
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
        -- globalstatus = false,
        disabled_filetypes = {
          statusline = {},
          winbar = {
            "neo-tree",
            "Outline",
            "Trouble",
            "qf",
            "leetcode.nvim",
          },
        },
      },
      sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(s)
              return mode_map[s] or s
            end,
            separator = { left = "" },
            icon = "👾",
            -- right_padding = 2,
          },
        },
        lualine_b = {
          {
            function()
              return vim.fn.fnamemodify(vim.fn.getcwd(0), ":t")
            end,
            icon = "📂",
            color = { fg = "#7fB4CA", gui = "italic" },
          },
          {
            "filename",
            file_status = true, -- Displays file status (readonly status, modified status)
            newfile_status = false, -- Display new file status (new file means no write after created)
            path = 0, -- 0: Just the filename
            -- 1: Relative path
            -- 2: Absolute path
            -- 3: Absolute path, with tilde as the home directory
            -- 4: Filename and parent dir, with tilde as the home directory

            shorting_target = 40, -- Shortens path to leave 40 spaces in the window
            -- for other components. (terrible name, any suggestions?)
            symbols = {
              modified = "", -- Text to show when the file is modified.
              readonly = "🔒", -- Text to show when the file is non-modifiable or readonly.
              unnamed = "[No Name]", -- Text to show for unnamed buffers.
              newfile = "[New]", -- Text to show for newly created file before first write
            },
            color = { gui = "italic" },
            icon = "📝",
          },
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
        lualine_x = {
          {
            function()
              -- 确保 `get` 函数被正确调用，并处理其返回值
              local command_status = require("noice.api.status").command.get()
              -- 根据 `command_status` 返回正确的字符串
              return command_status
              -- if command_status then
              --   return "⌨ " .. command_status
              -- else
              --   return ""
              -- end
            end,
            -- "⌨ " .. require("noice").api.status.command.get,
            cond = require("noice.api.status").command.has,
            color = { fg = "#ff9e64" },
          },

          { "searchcount", icon = "🔍", color = { fg = "#fcba03" } }, -- 󰱽
        },

        lualine_y = {
          {
            "branch",
            color = { fg = "#d27e99" },
          },
          { "filetype", color = { gui = "italic" } },
        },
        lualine_z = {
          {
            function()
              local buf_clients = vim.lsp.get_clients()
              local null_ls_installed, null_ls = pcall(require, "null-ls")
              local buf_client_names = {}
              for _, client in pairs(buf_clients) do
                if client.name == "null-ls" then
                  if null_ls_installed then
                    for _, source in ipairs(null_ls.get_source({ filetype = vim.bo.filetype })) do
                      table.insert(buf_client_names, source.name)
                    end
                  end
                else
                  table.insert(buf_client_names, client.name)
                end
              end
              return table.concat(buf_client_names, ",")
            end,
            -- icon = "󰌘",
            color = { gui = "italic" },
            icon = "⚙️",
          },
          {
            "location",
            icon = { "📍", color = { fg = "#41942C" } }, -- 
            separator = { right = "" },
            left_padding = -1,
          },
        },
      },
      winbar = {
        lualine_c = {
          {
            "filetype",
            colored = true, -- Displays filetype icon in color if set to true
            icon_only = true, -- Display only an icon for filetype
            icon = { align = "right" }, -- Display filetype icon on the right hand side
            -- icon =    {'X', align='right'}
            -- Icon string ^ in table is ignored in filetype component
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
            color = { fg = "#727169" },
            padding = { left = -1 },
          },
          {
            function()
              return "%#Comment#" .. "› " .. "%#Normal#" .. require("nvim-navic").get_location()
            end,
            cond = function()
              return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
            end,
            -- padding = { left = -2 },
          },
        },
      },
      inactive_winbar = {
        lualine_c = {
          {
            "filetype",
            colored = true, -- Displays filetype icon in color if set to true
            icon_only = true, -- Display only an icon for filetype
            icon = { align = "right" }, -- Display filetype icon on the right hand side
            -- icon =    {'X', align='right'}
            -- Icon string ^ in table is ignored in filetype component
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
            color = { fg = "#727169" },
            padding = { left = -1 },
          },

          {
            function()
              return "%#Comment#" .. "› " .. "%#Normal#" .. require("nvim-navic").get_location()
            end,
            cond = function()
              return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
            end,
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
      extensions = {},
    })
  end,
}
