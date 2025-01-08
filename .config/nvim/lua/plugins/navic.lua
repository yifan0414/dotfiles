return {
  "yifan0414/nvim-navic",
  lazy = true,
  init = function()
    vim.g.navic_silence = true
    require("lazyvim.util").lsp.on_attach(function(client, buffer)
      if client.supports_method("textDocument/documentSymbol") then
        require("nvim-navic").attach(client, buffer)
      end
    end)
  end,
  opts = function()
    -- vim.api.nvim_set_hl(0, "NavicIconsPackage", { fg = "#D5616F" })
    -- vim.api.nvim_set_hl(0, "NavicIconsVariable", { fg = "#FFA066" })
    -- -- vim.api.nvim_set_hl(0, "NavicIconsVariable", { fg = "#E46876" })
    -- vim.api.nvim_set_hl(0, "NavicIconsArray", { fg = "#FFA066" })
    -- vim.api.nvim_set_hl(0, "NavicIconsField", { fg = "#E6C384"})
    -- vim.api.nvim_set_hl(0, "NavicIconsFunction", { fg = "#89b4fb", bold = true })
    -- vim.api.nvim_set_hl(0, "NavicIconsPackage", { fg = "#74c7ed" })
    -- vim.api.nvim_set_hl(0, "NavicIconsVariable", { fg = "#cdd6f5" })
    -- vim.api.nvim_set_hl(0, "NavicIconsArray", { fg = "#f9e2b0" })
    -- vim.api.nvim_set_hl(0, "NavicIconsField", { fg = "#E6C384" })
    -- vim.api.nvim_set_hl(0, "NavicIconsString", { fg = "#a6e3a2" })
    -- vim.api.nvim_set_hl(0, "NavicIconsFunction", { fg = "#89b4fb", bold = true })
    return {
      -- { "Module", " ", "Exception" },
      -- { "Namespace", " ", "Include" },
      -- { "Package", " ", "Label" },
      -- { "Class", " ", "Include" },
      -- { "Method", " ", "Function" },
      -- { "Property", " ", "@property" },
      -- { "Field", " ", "@field" },
      -- { "Constructor", " ", "@constructor" },
      -- { "Enum", " ", "@number" },
      -- { "Interface", " ", "Type" },
      -- { "Function", "󰡱 ", "Function" },
      -- { "Variable", " ", "@variable" },
      -- { "Constant", " ", "Constant" },
      -- { "String", "󰅳 ", "String" },
      -- { "Number", "󰎠 ", "Number" },
      -- { "Boolean", " ", "Boolean" },
      -- { "Array", "󰅨 ", "Type" },
      -- { "Object", " ", "Type" },
      -- { "Key", " ", "Constant" },
      -- { "Null", "󰟢 ", "Constant" },
      -- { "EnumMember", " ", "Number" },
      -- { "Struct", " ", "Type" },
      -- { "Event", " ", "Constant" },
      -- { "Operator", " ", "Operator" },
      -- { "TypeParameter", " ", "Type" },
      icons = {
        Module = " ",
        Namespace = " ",
        Package = " ",
        Class = " ",
        Method = " ",
        Property = " ",
        Field = " ",
        Constructor = " ",
        Enum = " ",
        Interface = " ",
        Function = "󰡱 ",
        Variable = " ",
        Constant = " ",
        String = "󰅳 ",
        Number = "󰎠 ",
        Boolean = " ",
        Array = "󰅨 ",
        Object = " ",
        Key = " ",
        Null = "󰟢 ",
        EnumMember = " ",
        Struct = " ",
        Event = " ",
        Operator = " ",
        TypeParameter = " ",
      },
      separator = "%#Comment#" .. " › " .. "%#Normal#",
      highlight = false,
      -- depth_limit = 7,
      -- depth_limit_indicator = "%#Comment#" .. ".." .. "%#Normal#",
      lazy_update_context = false,
      click = true,
      -- format_text = function(text)
      --   -- %#IncSearch#HighlightedText%#
      --   -- return string.format("%#NavicIconsVariable#%s%#", text)
      --   return "%#NavicIconsVariable#" .. text .. "%#Normal#"
      -- end,
      -- format_data = function ()
      --   return "ssss"
      -- end
    }
  end,
}
