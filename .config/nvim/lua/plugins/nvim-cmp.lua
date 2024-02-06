return {
  "hrsh7th/nvim-cmp",
  version = false, -- last release is way too old
  event = "InsertEnter",
  dependencies = {
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "saadparwaiz1/cmp_luasnip" },
    { "onsails/lspkind.nvim" },
    {
      "hrsh7th/cmp-cmdline",
      event = "CmdlineEnter",
      -- opt = function()
      --   return {
      --     mapping = {},
      --   }
      -- end,
      config = function()
        local cmp = require("cmp")
        cmp.setup.cmdline("/", {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
            { name = "buffer" },
          },
        })

        cmp.setup.cmdline(":", {
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources({
            { name = "path" },
            {
              name = "cmdline",
              option = {
                ignore_cmds = { '"', "/", "!" },
              },
            },
          }),
        })
      end,
    },
  },

  opts = function()
    -- gray
    vim.api.nvim_set_hl(0, "CmpItemAbbrDeprecated", { bg = "NONE", strikethrough = true, fg = "#808080" })
    -- blue
    -- vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { bg = "NONE", fg = "#569CD6" })
    -- vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { link = "CmpIntemAbbrMatch" })
    -- light blue
    vim.api.nvim_set_hl(0, "CmpItemKindVariable", { bg = "NONE", fg = "#9CDCFE" })
    vim.api.nvim_set_hl(0, "CmpItemKindInterface", { link = "CmpItemKindVariable" })
    vim.api.nvim_set_hl(0, "CmpItemKindText", { link = "CmpItemKindVariable" })
    -- pink
    vim.api.nvim_set_hl(0, "CmpItemKindFunction", { bg = "NONE", fg = "#C586C0" })
    vim.api.nvim_set_hl(0, "CmpItemKindMethod", { link = "CmpItemKindFunction" })
    vim.api.nvim_set_hl(0, "CmpItemKindConstructor", { link = "CmpItemKindFunction" })
    -- front
    vim.api.nvim_set_hl(0, "CmpItemKindKeyword", { bg = "NONE", fg = "#D4D4D4" })
    vim.api.nvim_set_hl(0, "CmpItemKindProperty", { link = "CmpItemKindKeyword" })
    vim.api.nvim_set_hl(0, "CmpItemKindUnit", { link = "CmpItemKindKeyword" })

    vim.api.nvim_set_hl(0, "CmpItemKindClass", { bg = "NONE", fg = "#d4983e" })
    vim.api.nvim_set_hl(0, "CmpItemKindField", { bg = "NONE", fg = "#87beef" })
    vim.api.nvim_set_hl(0, "CmpItemKindStruct", { bg = "NONE", fg = "#7eaaa0" })

    vim.api.nvim_set_hl(0, "CmpItemKindReference", { bg = "NONE", fg = "#ffe4b5" })
    -- Customization for Pmenu
    vim.api.nvim_set_hl(0, "PmenuSel", { fg = "#54546D", bg = "#1F1F28", blend = 0 })
    vim.api.nvim_set_hl(0, "Pmenu", { fg = "#dcd7ba", bg = "#1F1F28", blend = 0 })

    local neotab = require("neotab")
    local luasnip = require("luasnip")

    -- require("luasnip.loaders.from_vscode").lazy_load()
    require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
    local cmp = require("cmp")
    return {
      window = {
        completion = cmp.config.window.bordered({
          -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
          winhighlight = "Normal:Pmenu,FloatBorder:PmenuSel,Search:None",
        }),
        -- documentation = cmp.config.window.bordered({
        --   winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        -- }),
        documentation = {
          border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
          -- winhighlight = 'Normal:Pmenu,FloatBorder:PmenuSel,Search:None',
          max_width = 50,
          max_height = math.floor(vim.o.lines * 0.5),
        },
      },
      completion = {
        -- completeopt = "menu,menuone,noinsert",
        keyword_length = 2,
      },
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        -- ["<Tab>"] = cmp.mapping(function(fallback)
        --   if cmp.visible() then
        --     cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
        --     -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
        --     -- they way you will only jump inside the snippet region
        --   elseif luasnip.expand_or_jumpable() then
        --     luasnip.expand_or_jump()
        --   elseif has_words_before() then
        --     cmp.complete()
        --   else
        --     fallback()
        --   end
        -- end, { "i", "s" }),
        -- use noetab
        ["<Tab>"] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          elseif luasnip.expand_or_jumpable(1) then
            luasnip.expand_or_jump(1)
          else
            neotab.tabout()
          end
        end),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<DOWN>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<UP>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-c>"] = cmp.mapping.abort(),
        -- ["<esc>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<S-CR>"] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      }),
      sources = cmp.config.sources({
        {
          name = "nvim_lsp",
          entry_filter = function(entry)
            local kind = entry:get_kind()
            return cmp.lsp.CompletionItemKind.Snippet ~= kind
          end,
        },
        { name = "luasnip" },
        -- { name = "buffer" },
        { name = "path" },
      }),
      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(_, item)
          item.abbr = string.sub(item.abbr, 1, 35)
          item.menu = string.sub(1, 30) -- 暂时解决了问题
          -- local icons = require("lazyvim.config").icons.kinds
          local cmp_kinds = {
            Text = " ",
            Method = " ",
            Function = " ",
            Constructor = " ",
            Field = " ",
            Variable = " ",
            Class = " ",
            Interface = " ",
            Module = " ",
            Property = " ",
            Unit = " ",
            Value = " ",
            Enum = " ",
            Keyword = " ",
            Snippet = " ",
            Color = " ",
            File = " ",
            Reference = " ",
            Folder = " ",
            EnumMember = " ",
            Constant = " ",
            Struct = " ",
            Event = " ",
            Operator = " ",
            TypeParameter = " ",
          }

          -- if icons[item.kind] then
          --   item.abbr = icons[item.kind] .. item.abbr
          -- end
          item.kind = string.format("%s", cmp_kinds[item.kind])
          -- item.kind = string.format("%s %s", cmp_kinds[item.kind], item.kind)
          return item
        end,
      },
      -- experimental = {
      --   ghost_text = {
      --     hl_group = "CmpGhostText",
      --   },
      -- },
      -- sorting = defaults.sorting,
    }
  end,
}
