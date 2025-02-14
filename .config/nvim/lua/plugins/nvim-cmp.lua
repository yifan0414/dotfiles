return {
  "hrsh7th/nvim-cmp",
  version = false, -- last release is way too old
  enabled = false,
  event = "VeryLazy",
  dependencies = {
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "saadparwaiz1/cmp_luasnip" },
    {
      "onsails/lspkind.nvim",
      config = function()
        require("lspkind").init({
          symbol_map = {
            Array = " ",
            Boolean = "󰨙 ",
            Class = "󰯳 ",
            Codeium = "󰘦 ",
            Color = "󰰠 ",
            Control = " ",
            Collapsed = "> ",
            Constant = "󰯱 ",
            Constructor = " ",
            Copilot = " ",
            Enum = "󰯹 ",
            EnumMember = "E ",
            Event = " ",
            Field = " ",
            File = " ",
            Folder = " ",
            Function = "󰡱 ",
            Interface = "󰰅 ",
            Key = " ",
            Keyword = "󱕴 ",
            Method = "󰰑 ",
            Module = "󰆼 ",
            Namespace = "󰰔 ",
            Null = " ",
            Number = "󰰔 ",
            Object = "󰲟 ",
            Operator = " ",
            Package = "󰰚 ",
            Property = "󰲽 ",
            Reference = "󰰠 ",
            Snippet = " ",
            String = " ",
            Struct = "󰰣 ",
            TabNine = "󰏚 ",
            Text = "󱜥 ",
            TypeParameter = "󰰦 ",
            Unit = "󱜥 ",
            Value = " ",
            Variable = "󰫧 ",
          },
        })
      end,
    },
    { "L3MON4D3/LuaSnip" },
    { "xzbdmw/colorful-menu.nvim" },
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
              { name = "buffer", max_item_count = 7 },
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
    local neotab = require("neotab")
    local luasnip = require("luasnip")
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local cmp = require("cmp")
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

    return {
      window = {
        completion = {
          col_offset = -3,
          side_padding = 0,
        },
        documentation = {
          -- border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          -- max_width = 50,
          -- max_height = math.floor(vim.o.lines * 0.5),
        },
      },

      preselect = cmp.PreselectMode.None,

      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },

      mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          else
            neotab.tabout()
          end
        end, { "i", "s" }),
        ["<C-n>"] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
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
        ["<C-p>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
          elseif luasnip.expand_or_locally_jumpable(-1) then
            luasnip.expand_or_jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        -- ["<C-n>"] = cmp.mapping(function()
        --   if luasnip.choice_active() then
        --     luasnip.change_choice(1)
        --   elseif luasnip.expand_or_locally_jumpable() then
        --     luasnip.expand_or_jump()
        --   elseif cmp.visible() then
        --     cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
        --   end
        -- end),
        -- ["<C-p>"] = cmp.mapping(function()
        --   if luasnip.choice_active() then
        --     luasnip.change_choice(-1)
        --   elseif luasnip.expand_or_locally_jumpable(-1) then
        --     luasnip.expand_or_jump(-1)
        --   elseif cmp.visible() then
        --     cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
        --   end
        -- end),
        ["<DOWN>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<UP>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-g>"] = cmp.mapping.complete(),
        ["<C-c>"] = cmp.mapping.abort(),
        -- ["<esc>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      }),
      sources = cmp.config.sources({
        -- {
        --   name = "copilot",
        --   group_index = 1,
        --   priority = 100,
        -- },
        {
          name = "nvim_lsp",
          -- group_index = 1,
          -- max_item_count = 5,
          entry_filter = function(entry)
            local kind = entry:get_kind()
            return cmp.lsp.CompletionItemKind.Snippet ~= kind
          end,
        },
        {
          name = "buffer",
          -- group_index = 2,
          max_item_count = 5,
          -- 筛选出去数字
          option = {
            get_bufnrs = function()
              local bufs = {}
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                bufs[vim.api.nvim_win_get_buf(win)] = true
              end
              return vim.tbl_keys(bufs)
            end,
          },
          entry_filter = function(entry)
            -- return not string.match(entry:get_completion_item().label, "^%d+$")
            return not string.match(entry:get_completion_item().label, "^%d+%.?%d*[eE]?%d*$")
          end,
        },
        {
          name = "luasnip",
          -- group_index = 1,
          max_item_count = 4,
          entry_filter = function()
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
        },
        -- { name = "vim-dadbod-completion" },
        -- { name = "orgmode" },
        -- { name = "path" },
      }),

      formatting = {
        fields = { "kind", "abbr" },
        format = function(entry, vim_item)
          local kind = require("lspkind").cmp_format({
            mode = "symbol_text",
            maxwidth = {
              abbr = 15,
            },
            ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
            show_labelDetails = true, -- show labelDetails in menu. Disabled by default
          })(entry, vim.deepcopy(vim_item))

          local highlights_info = require("colorful-menu").cmp_highlights(entry)

          if highlights_info ~= nil then
            vim_item.abbr_hl_group = highlights_info.highlights
            vim_item.abbr = highlights_info.text
          end

          vim_item.dup = ({
            luasnip = 1,
            nvim_lsp = 0,
            buffer = 0,
            path = 0,
          })[entry.source.name] or 0

          local strings = vim.split(kind.kind, "%s", { trimempty = true })
          vim_item.kind = " " .. (strings[1] or "") .. " "
          vim_item.menu = "    (" .. (strings[2] or "") .. ")"
          return vim_item
        end,
      },

      performance = {
        debounce = 30,
        throttle = 20,
        fetching_timeout = 500,
        filtering_context_budget = 3,
        confirm_resolve_timeout = 80,
        async_budget = 1,
        max_view_entries = 200,
      },

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
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      },
      matching = {
        disallow_fuzzy_matching = false,
        disallow_fullfuzzy_matching = false,
        disallow_partial_fuzzy_matching = true,
        disallow_partial_matching = false,
        disallow_prefix_unmatching = false,
      },
      -- experimental = {
      --   ghost_text = true, -- this feature conflict with copilot.vim's preview.
      -- },
    }
  end,
}
