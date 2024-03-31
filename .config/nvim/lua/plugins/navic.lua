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
    vim.api.nvim_set_hl(0, "NavicIconsPackage", { fg = "#D5616F" })
    vim.api.nvim_set_hl(0, "NavicIconsVariable", { fg = "#FFA066" })
    -- vim.api.nvim_set_hl(0, "NavicIconsVariable", { fg = "#E46876" })
    vim.api.nvim_set_hl(0, "NavicIconsArray", { fg = "#FFA066" })
    vim.api.nvim_set_hl(0, "NavicIconsField", { fg = "#E6C384"})

    return {
      -- icons = {
      --   File = " ",
      --   Module = " ",
      --   Namespace = " ",
      --   Package = " ",
      --   Class = " ",
      --   Method = " ",
      --   Property = " ",
      --   Field = " ",
      --   Constructor = " ",
      --   Enum = " ",
      --   Interface = " ",
      --   Function = " ",
      --   Variable = " ",
      --   Constant = " ",
      --   String = " ",
      --   Number = " ",
      --   Boolean = " ",
      --   Array = " ",
      --   Object = " ",
      --   Key = " ",
      --   Null = " ",
      --   EnumMember = " ",
      --   Struct = " ",
      --   Event = " ",
      --   Operator = " ",
      --   TypeParameter = " ",
      -- },
      icons = {
        File = "󰈔 ",
        Module = "󰆧 ",
        Namespace = "󰅪 ",
        Package = "󰏗 ",
        Class = "𝓒 ",
        Method = "ƒ ",
        Property = " ",
        Field = "󰆨 ",
        Constructor = " ",
        Enum = "ℰ ",
        Interface = "󰜰 ",
        Function = "⨐ ",
        Variable = " ",
        Constant = " ",
        String = "𝓐 ",
        Number = "# ",
        Boolean = "⊨ ",
        Array = "󰅪 ",
        Object = "⦿ ",
        Key = "🔐 ",
        Null = "NULL ",
        EnumMember = " ",
        Struct = "𝓢 ",
        Event = "🗲 ",
        Operator = "+ ",
        TypeParameter = "𝙏 ",
        Component = "󰅴 ",
        Fragment = "󰅴 ",
        -- ccls
        TypeAlias = "  ",
        Parameter = "  ",
        StaticMethod = "  ",
        Macro = "  ",
      },
      separator = "%#Comment#" .. " › " .. "%#Normal#",
      highlight = true,
      -- depth_limit = 7,
      depth_limit_indicator = "%#Comment#" .. ".." .. "%#Normal#",
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
