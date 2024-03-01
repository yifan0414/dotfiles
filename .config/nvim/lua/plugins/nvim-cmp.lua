return {
  "hrsh7th/nvim-cmp",
  version = false, -- last release is way too old
  event = "VeryLazy",
  dependencies = {
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "saadparwaiz1/cmp_luasnip" },
    { "onsails/lspkind.nvim" },
    {
      "hrsh7th/cmp-cmdline",
      -- event = "CmdlineEnter",
      keys = { ":", "/", "?" }, -- lazy load cmp on more keys along with insert mode
      opts = function()
        local cmp = require("cmp")
        return {
          {
            type = "/",
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = "buffer" },
            },
          },
          {
            type = ":",
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
              { name = "path" },
            }, {
              {
                name = "cmdline",
                option = {
                  ignore_cmds = { "Man", "!" },
                },
              },
            }),
          },
        }
      end,
      config = function(_, opts)
        local cmp = require("cmp")
        vim.tbl_map(function(val)
          cmp.setup.cmdline(val.type, val)
        end, opts)
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
    -- vim.api.nvim_set_hl(0, "Pmenu", { fg = "#dcd7ba", bg = "#223349", blend = 0 })

    local neotab = require("neotab")
    local luasnip = require("luasnip")

    require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    require("luasnip.loaders.from_lua").lazy_load({ paths = "./snippets_lua" })
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
        -- autocomplete = false,
        -- keyword_length = 2,
        -- keyword_length = 1,
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
            -- cmp.abort()
            -- else
            --   neotab.tabout_luasnip()
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          else
            neotab.tabout()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
          elseif luasnip.expand_or_locally_jumpable(-1) then
            luasnip.expand_or_jump(-1)
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
        ["<C-g>"] = cmp.mapping.complete(),
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
          name = "luasnip",
          -- group_index = 1,
          -- max_item_count = 5,
        },
        -- {
        --   name = "buffer",
        --   group_index = 2,
        --   -- max_item_count = 3,
        -- },
        {
          name = "nvim_lsp",
          -- group_index = 2,
          -- max_item_count = 7,
          entry_filter = function(entry)
            local kind = entry:get_kind()
            return cmp.lsp.CompletionItemKind.Snippet ~= kind
          end,
        },
        -- { name = "vim-dadbod-completion" },
        -- { name = "orgmode" },
        -- { name = "path" },
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
        fields = { "abbr", "kind", "menu" },
        format = require("lspkind").cmp_format({
          preset = "codicons",
          mode = "symbol_text",
          maxwidth = 20,
          show_labelDetails = false,
          ellipsis_char = "...",
          before = function(entry, vim_item)
            -- vim_item.menu = string.sub(vim_item.menu, 1, 0)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              buffer = "[Buffer]",
              luasnip = "[LuaSnip]",
            })[entry.source.name]
            vim_item.abbr = string.gsub(vim_item.abbr, "^%s+", "")
            -- vim_item.dup = 0
            vim_item.dup = ({
              buffer = 0,
              path = 0,
              nvim_lsp = 0,
              luasnip = 1,
            })[entry.source.name] or 0
            return vim_item
          end,
        }),
      },
      -- experimental = {
      --   ghost_text = {
      --     hl_group = "CmpGhostText",
      --   },
      -- },
      sorting = {
        priority_weight = 2,
        comparators = {
          cmp.config.compare.offset,
          cmp.config.compare.recently_used,
          cmp.config.compare.exact,
          -- compare.scopes,
          cmp.config.compare.score,
          cmp.config.compare.locality,
          cmp.config.compare.kind,
          -- compare.sort_text,
          -- cmp.config.compare.length,
          cmp.config.compare.order,
        },
      },
      -- matching = {
      --   disallow_fuzzy_matching = true,
      --   disallow_fullfuzzy_matching = true,
      --   disallow_partial_fuzzy_matching = true,
      --   disallow_partial_matching = true,
      --   -- disallow_prefix_unmatching = true,
      -- },
      matching = {
        disallow_fuzzy_matching = false,
        disallow_fullfuzzy_matching = false,
        disallow_partial_fuzzy_matching = true,
        disallow_partial_matching = false,
        disallow_prefix_unmatching = false,
      },
    }
  end,
}
