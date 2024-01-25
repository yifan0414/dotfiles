local mode_map = {
  ['NORMAL'] = 'N',
  ['O-PENDING'] = 'N',
  ['INSERT'] = 'I',
  ['VISUAL'] = 'V',
  ['V-BLOCK'] = 'VB',
  ['V-LINE'] = 'VL',
  ['V-REPLACE'] = 'VR',
  ['REPLACE'] = 'R',
  ['COMMAND'] = '!',
  ['SHELL'] = 'SH',
  ['TERMINAL'] = 'T',
  ['EX'] = 'X',
  ['S-BLOCK'] = 'SB',
  ['S-LINE'] = 'SL',
  ['SELECT'] = 'S',
  ['CONFIRM'] = 'Y?',
  ['MORE'] = 'M',
}

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    -- table.insert(opts.sections.lualine_x, {
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
    table.remove(opts.sections.lualine_a)
    table.insert(opts.sections.lualine_a, {
      'mode', fmt = function(s) return mode_map[s] or s end
    })
    table.insert(opts.sections.lualine_b, {
      function()
        return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      end,
      icon = "",
    })
    table.remove(opts.sections.lualine_c)
    table.insert(opts.sections.lualine_c, {
      "filename",
      shorting_target = 40,
      path = 1,
    })
  end,
}
