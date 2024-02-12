-- local mode_map = {
--   ["NORMAL"] = "N",
--   ["O-PENDING"] = "N",
--   ["INSERT"] = "I",
--   ["VISUAL"] = "V",
--   ["V-BLOCK"] = "VB",
--   ["V-LINE"] = "VL",
--   ["V-REPLACE"] = "VR",
--   ["REPLACE"] = "R",
--   ["COMMAND"] = "!",
--   ["SHELL"] = "SH",
--   ["TERMINAL"] = "T",
--   ["EX"] = "X",
--   ["S-BLOCK"] = "SB",
--   ["S-LINE"] = "SL",
--   ["SELECT"] = "S",
--   ["CONFIRM"] = "Y?",
--   ["MORE"] = "M",
-- }
--
-- return {
--   {
--     "nvim-lualine/lualine.nvim",
--     event = "VeryLazy",
--     opts = function(_, opts)
--       -- table.insert(opts.sections.lualine_x, {
--       --   function()
--       --     local msg = "No Active Lsp"
--       --     local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
--       --     local clients = vim.lsp.get_active_clients()
--       --     if next(clients) == nil then
--       --       return msg
--       --     end
--       --     for _, client in ipairs(clients) do
--       --       local filetypes = client.config.filetypes
--       --       if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
--       --         return client.name
--       --       end
--       --     end
--       --     return msg
--       --   end,
--       --   icon = " LSP:",
--       --   color = { fg = "#7fB4CA", gui = "bold" },
--       -- })
--       table.remove(opts.sections.lualine_a)
--       table.insert(opts.sections.lualine_a, {
--         "mode",
--         fmt = function(s)
--           return mode_map[s] or s
--         end,
--       })
--       table.insert(opts.sections.lualine_b, {
--         function()
--           return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
--         end,
--         icon = "",
--       })
--       table.remove(opts.sections.lualine_c)
--       table.insert(opts.sections.lualine_c, {
--         "filename",
--         shorting_target = 40,
--         path = 1,
--       })
--     end,
--   },
-- }

return {
  "nvim-lualine/lualine.nvim", -- status line
  event = "VeryLazy",
  config = function()
    local lualine = require("lualine")

    -- local cmake = require("cmake-tools")

    -- you can find the icons from https://github.com/Civitasv/runvim/blob/master/lua/config/icons.lua
    -- local icons = require("config.icons")

    local icons = {
      kind = {
        Text = "󰦨 ",
        Method = " ",
        Function = " ",
        Constructor = " ",
        Field = " ",
        Variable = " ",
        Class = " ",
        Interface = " ",
        Module = " ",
        Property = " ",
        Unit = " ",
        Value = "󰾡 ",
        Enum = " ",
        Keyword = " ",
        Snippet = " ",
        Color = " ",
        File = " ",
        Reference = " ",
        Folder = " ",
        EnumMember = " ",
        Constant = " ",
        Struct = " ",
        Event = " ",
        Operator = " ",
        TypeParameter = " ",
        Specifier = " ",
        Statement = "",
        Recovery = " ",
        TranslationUnit = " ",
        PackExpansion = " ",
      },
      type = {
        Array = " ",
        Number = " ",
        String = " ",
        Boolean = " ",
        Object = " ",
        Template = " ",
      },
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
      ui = {
        Lock = "",
        TinyCircle = "",
        Circle = "",
        BigCircle = "",
        BigUnfilledCircle = "",
        CircleWithGap = "",
        LogPoint = "",
        Close = "",
        NewFile = "",
        Search = "",
        Lightbulb = "",
        Project = "",
        Dashboard = "",
        History = "",
        Comment = "",
        Bug = "",
        Code = "",
        Telescope = " ",
        Gear = "",
        Package = "",
        List = "",
        SignIn = "",
        Check = "",
        Fire = " ",
        Note = "",
        BookMark = "",
        Pencil = " ",
        -- ChevronRight = "",
        ChevronRight = ">",
        Table = "",
        Calendar = "",
        Line = "▊",
        Evil = "",
        Debug = "",
        Run = "",
        VirtualPrefix = "",
        Next = "",
        Previous = "",
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

    -- Credited to [evil_lualine](https://github.com/nvim-lualine/lualine.nvim/blob/master/examples/evil_lualine.lua)
    local conditions = {
      buffer_not_empty = function()
        return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
      end,
      hide_in_width = function()
        return vim.fn.winwidth(0) > 80
      end,
      check_git_workspace = function()
        local filepath = vim.fn.expand("%:p:h")
        local gitdir = vim.fn.finddir(".git", filepath .. ";")
        return gitdir and #gitdir > 0 and #gitdir < #filepath
      end,
    }

    local colors = {
      normal = {
        bg = "#202328",
        fg = "#bbc2cf",
        yellow = "#ECBE7B",
        cyan = "#008080",
        darkblue = "#081633",
        green = "#98be65",
        orange = "#FF8800",
        violet = "#a9a1e1",
        magenta = "#c678dd",
        blue = "#51afef",
        red = "#ec5f67",
      },
      nightfly = {
        bg = "#011627",
        fg = "#acb4c2",
        yellow = "#ecc48d",
        cyan = "#7fdbca",
        darkblue = "#82aaff",
        green = "#21c7a8",
        orange = "#e3d18a",
        violet = "#a9a1e1",
        magenta = "#ae81ff",
        blue = "#82aaff ",
        red = "#ff5874",
      },
      light = {
        bg = "#f6f2ee",
        fg = "#3d2b5a",
        yellow = "#ac5402",
        cyan = "#287980",
        darkblue = "#2848a9",
        green = "#396847",
        orange = "#a5222f",
        violet = "#8452d5",
        magenta = "#6e33ce",
        blue = "#2848a9",
        red = "#b3434e",
      },
      catppuccin_mocha = {
        bg = "#1E1E2E",
        fg = "#CDD6F4",
        yellow = "#F9E2AF",
        cyan = "#7fdbca",
        darkblue = "#89B4FA",
        green = "#A6E3A1",
        orange = "#e3d18a",
        violet = "#a9a1e1",
        magenta = "#ae81ff",
        blue = "#89B4FA",
        red = "#F38BA8",
      },
      kana = {
        bg = "#1F1F28",
        fg = "#DCD7BA",
        yellow = "#C0A36E",
        cyan = "#6A9589",
        darkblue = "#7E9CD8",
        green = "#98BB6D",
        orange = "#ff9e3b",
        violet = "#a9a1e1",
        magenta = "#ae81ff",
        blue = "#7FB4CA",
        red = "#ff5d62",
      },
    }

    colors = colors.kana

    local config = {
      options = {
        icons_enabled = true,
        component_separators = "",
        section_separators = "",
        -- disabled_filetypes = { "alpha", "dashboard", "Outline" },
        disabled_filetypes = { "alpha", "dashboard" },
        always_divide_middle = true,
        theme = {
          -- We are going to use lualine_c an lualine_x as left and
          -- right section. Both are highlighted by c theme .  So we
          -- are just setting default looks o statusline
          normal = { c = { fg = colors.fg, bg = colors.bg } },
          inactive = { c = { fg = colors.fg, bg = colors.bg } },
        },
      },
      sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        -- c for left
        lualine_c = {},
        -- x for right
        lualine_x = {},
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
      },
      tabline = {},
      extensions = {},
    }

    -- Inserts a component in lualine_c at left section
    local function ins_left(component)
      table.insert(config.sections.lualine_c, component)
    end

    -- Inserts a component in lualine_x ot right section
    local function ins_right(component)
      table.insert(config.sections.lualine_x, component)
    end

    -- ins_left({
    --   function()
    --     return icons.ui.Line
    --   end,
    --   color = { fg = colors.blue }, -- Sets highlighting of component
    --   padding = { left = 0, right = 1 }, -- We don't need space before this
    -- })

    ins_left({
      -- mode component
      function()
        return icons.misc.Neovim
      end,
      color = function()
        -- auto change color according to neovims mode
        local mode_color = {
          n = colors.blue,
          i = colors.green,
          v = colors.violet,
          ["�"] = colors.violet,
          V = colors.violet,
          c = colors.violet,
          no = colors.red,
          s = colors.orange,
          S = colors.orange,
          ["�"] = colors.orange,
          ic = colors.yellow,
          R = colors.violet,
          Rv = colors.violet,
          cv = colors.red,
          ce = colors.red,
          r = colors.red,
          rm = colors.cyan,
          ["r?"] = colors.cyan,
          ["!"] = colors.red,
          t = colors.violet,
        }
        return { fg = mode_color[vim.fn.mode()] }
      end,
      padding = { left = 1, right = 0 },
    })

    -- ins_left({
    --   -- filesize component
    --   "filesize",
    --   cond = conditions.buffer_not_empty,
    -- })

    ins_left({
      function()
        return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      end,
      icon = "",
      color = { fg = "#7fB4CA", gui = "bold" },
    })
    ins_left({
      "filename",
      cond = conditions.buffer_not_empty,
      color = { fg = colors.violet, gui = "bold" },
    })

    ins_left({
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
    })

    -- ins_left({
    --   function()
    --     local c_preset = cmake.get_configure_preset()
    --     return "CMake: [" .. (c_preset and c_preset or "X") .. "]"
    --   end,
    --   icon = icons.ui.Search,
    --   cond = function()
    --     return cmake.is_cmake_project() and cmake.has_cmake_preset()
    --   end,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeSelectConfigurePreset")
    --       end
    --     end
    --   end,
    -- })
    --
    -- ins_left({
    --   function()
    --     local type = cmake.get_build_type()
    --     return "CMake: [" .. (type and type or "") .. "]"
    --   end,
    --   icon = icons.ui.Search,
    --   cond = function()
    --     return cmake.is_cmake_project() and not cmake.has_cmake_preset()
    --   end,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeSelectBuildType")
    --       end
    --     end
    --   end,
    -- })
    --
    -- ins_left({
    --   function()
    --     local kit = cmake.get_kit()
    --     return "[" .. (kit and kit or "X") .. "]"
    --   end,
    --   icon = icons.ui.Pencil,
    --   cond = function()
    --     return cmake.is_cmake_project() and not cmake.has_cmake_preset()
    --   end,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeSelectKit")
    --       end
    --     end
    --   end,
    -- })
    --
    -- ins_left({
    --   function()
    --     return "Build"
    --   end,
    --   icon = icons.ui.Gear,
    --   cond = cmake.is_cmake_project,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeBuild")
    --       end
    --     end
    --   end,
    -- })
    --
    -- ins_left({
    --   function()
    --     local b_preset = cmake.get_build_preset()
    --     return "[" .. (b_preset and b_preset or "X") .. "]"
    --   end,
    --   icon = icons.ui.Search,
    --   cond = function()
    --     return cmake.is_cmake_project() and cmake.has_cmake_preset()
    --   end,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeSelectBuildPreset")
    --       end
    --     end
    --   end,
    -- })
    --
    -- ins_left({
    --   function()
    --     local b_target = cmake.get_build_target()
    --     return "[" .. (b_target and b_target or "X") .. "]"
    --   end,
    --   cond = cmake.is_cmake_project,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeSelectBuildTarget")
    --       end
    --     end
    --   end,
    -- })
    --
    -- ins_left({
    --   function()
    --     return icons.ui.Debug
    --   end,
    --   cond = cmake.is_cmake_project,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeDebug")
    --       end
    --     end
    --   end,
    -- })
    --
    -- ins_left({
    --   function()
    --     return icons.ui.Run
    --   end,
    --   cond = cmake.is_cmake_project,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeRun")
    --       end
    --     end
    --   end,
    -- })
    --
    -- ins_left({
    --   function()
    --     local l_target = cmake.get_launch_target()
    --     return "[" .. (l_target and l_target or "X") .. "]"
    --   end,
    --   cond = cmake.is_cmake_project,
    --   on_click = function(n, mouse)
    --     if n == 1 then
    --       if mouse == "l" then
    --         vim.cmd("CMakeSelectLaunchTarget")
    --       end
    --     end
    --   end,
    -- })

    -- Insert mid section. You can make any number of sections in neovim :)
    -- for lualine it's any number greater then 2
    ins_left({
      function()
        return "%="
      end,
    })

    -- ins_left({
    --   function()
    --     local msg = "No Active Lsp"
    --     local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
    --     local clients = vim.lsp.get_active_clients()
    --     if next(clients) == nil then
    --       return msg
    --     end
    --     for _, client in ipairs(clients) do
    --       local filetypes = client.config.filetypes
    --       if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
    --         return client.name
    --       end
    --     end
    --     return msg
    --   end,
    --   icon = " LSP:",
    --   color = { fg = "#7fB4CA", gui = "bold" },
    -- })

    -- Add components to right sections
    ins_right({
      require("noice").api.status.command.get,
      cond = require("noice").api.status.command.has,
      color = { fg = "#ff9e64" },
    })

    -- ins_right({
    --   "o:encoding", -- option component same as &encoding in viml
    --   fmt = string.upper, -- I'm not sure why it's upper case either ;)
    --   cond = conditions.hide_in_width,
    --   color = { fg = colors.green, gui = "bold" },
    -- })
    --
    -- ins_right({
    --   "fileformat",
    --   symbols = {
    --     unix = "", -- e712
    --     dos = "", -- e70f
    --     mac = "", -- e711
    --   },
    --   fmt = string.upper,
    --   icons_enabled = false,
    --   color = { fg = colors.green, gui = "bold" },
    -- })

    -- ins_right({
    --   function()
    --     return vim.api.nvim_buf_get_option(0, "shiftwidth")
    --   end,
    --   icons_enabled = false,
    --   color = { fg = colors.green, gui = "bold" },
    -- })

    ins_right({
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
    })

    ins_right({
      "branch",
      icon = icons.git.Branch,
      color = { fg = colors.violet, gui = "bold" },
    })

    ins_right({ "location", color = { fg = colors.violet }, gui = "bold" })

    -- ins_right({
    --   "diff",
    --   -- Is it me or the symbol for modified us really weird
    --   symbols = { added = icons.git.Add, modified = icons.git.Mod, removed = icons.git.Remove },
    --   diff_color = {
    --     added = { fg = colors.green },
    --     modified = { fg = colors.orange },
    --     removed = { fg = colors.red },
    --   },
    --   -- cond = conditions.hide_in_width,
    -- })

    -- ins_right({
    --   function()
    --     local current_line = vim.fn.line(".")
    --     local total_lines = vim.fn.line("$")
    --     local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
    --     local line_ratio = current_line / total_lines
    --     local index = math.ceil(line_ratio * #chars)
    --     return chars[index]
    --     -- return line_ratio .. "%"
    --   end,
    --   color = { fg = colors.violet, gui = "bold" },
    --   padding = { right = 1 },
    -- })

    ins_right({ "progress", color = { fg = colors.violet, gui = "bold" } })

    -- ins_right({
    --   function()
    --     return "▊"
    --   end,
    --   color = { fg = colors.blue },
    --   padding = { left = 1 },
    -- })

    -- Now don't forget to initialize lualine
    lualine.setup(config)
  end,
}
