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
    -- vim.api.nvim_set_hl(0, "PmenuSel", { fg = "#54546D", bg = "#1F1F28", blend = 0 })
    -- vim.api.nvim_set_hl(0, "Pmenu", { fg = "#dcd7ba", bg = "#1F1F28", blend = 0 })

    local neotab = require("neotab")
    local luasnip = require("luasnip")

    -- require("luasnip.loaders.from_vscode").lazy_load()
    require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    require("luasnip.loaders.from_lua").load({ paths = "./snippets_lua" })
    vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
    local cmp = require("cmp")
    return {
      window = {
        -- completion = cmp.config.window.bordered({
        --   -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        --   winhighlight = "Normal:Pmenu,FloatBorder:PmenuSel,Search:None",
        -- }),
        -- documentation = cmp.config.window.bordered({
        --   winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        -- }),
        documentation = {
          -- border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
          -- winhighlight = 'Normal:Pmenu,FloatBorder:PmenuSel,Search:None',
          max_width = 50,
          max_height = math.floor(vim.o.lines * 0.5),
        },
      },
      completion = {
        -- completeopt = "menu,menuone,noinsert",
        -- keyword_length = 2,
      },
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },

      mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          elseif luasnip.expand_or_jumpable(1) then
            luasnip.expand_or_jump(1)
          else
            neotab.tabout()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-n>"] = cmp.mapping(function()
          if luasnip.choice_active() then
            luasnip.change_choice(1)
          elseif cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          end
        end),
        ["<C-p>"] = cmp.mapping(function()
          if luasnip.choice_active() then
            luasnip.change_choice(-1)
          elseif cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
          end
        end),
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
        { name = "luasnip" },
        {
          name = "nvim_lsp",
          entry_filter = function(entry)
            local kind = entry:get_kind()
            return cmp.lsp.CompletionItemKind.Snippet ~= kind
          end,
        },
        -- { name = "buffer" },
        { name = "path" },
      }),
      enabled = function()
        -- disable completion in comments
        local context = require("cmp.config.context")
        -- keep command mode completion enabled when cursor is in a comment
        if
          vim.bo.buftype == "prompt"
          or context.in_treesitter_capture("comment")
          or context.in_syntax_group("Comment")
          or context.in_treesitter_capture("string")
          or context.in_syntax_group("String")
        then
          return false
        else
          return true
        end
      end,
      formatting = {
        fields = { "abbr", "menu", "kind" },
        format = require("lspkind").cmp_format({
          preset = "codicons",
          mode = "symbol_text",
          maxwidth = 15,
          show_labelDetails = true,
          ellipsis_char = "...",
          before = function(entry, vim_item)
            if vim_item.menu ~= nil then
              vim_item.menu = string.sub(vim_item.menu, 1, 20)
              -- vim_item.abbr = vim_item.abbr .. " " .. vim_item.menu
            end
            return vim_item
          end,
        }),
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
