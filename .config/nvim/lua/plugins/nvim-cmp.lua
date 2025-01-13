return {
  "hrsh7th/nvim-cmp",
  version = false, -- last release is way too old
  -- event = "VeryLazy",
  dependencies = {
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "saadparwaiz1/cmp_luasnip" },
    { "onsails/lspkind.nvim" },
    {
      "xzbdmw/colorful-menu.nvim",
      config = function()
        -- You don't need to set these options.
        require("colorful-menu").setup({
          ls = {
            lua_ls = {
              -- Maybe you want to dim arguments a bit.
              arguments_hl = "@comment",
            },
            gopls = {
              -- By default, we render variable/function's type in the right most side,
              -- to make them not to crowd together with the original label.

              -- when true:
              -- foo             *Foo
              -- ast         "go/ast"

              -- when false:
              -- foo *Foo
              -- ast "go/ast"
              align_type_to_right = true,
              -- When true, label for field and variable will format like "foo: Foo"
              -- instead of go's original syntax "foo Foo".
              add_colon_before_type = false,
            },
            -- for lsp_config or typescript-tools
            ts_ls = {
              extra_info_hl = "@comment",
            },
            vtsls = {
              extra_info_hl = "@comment",
            },
            ["rust-analyzer"] = {
              -- Such as (as Iterator), (use std::io).
              extra_info_hl = "@comment",
            },
            clangd = {
              -- Such as "From <stdio.h>".
              arguments_hl = "@comment",
              extra_info_hl = "@comment",
            },
            roslyn = {
              extra_info_hl = "@comment",
            },
            -- The same applies to pyright/pylance
            basedpyright = {
              -- It is usually import path such as "os"
              extra_info_hl = "@comment",
            },

            -- If true, try to highlight "not supported" languages.
            fallback = true,
          },
          -- If the built-in logic fails to find a suitable highlight group,
          -- this highlight is applied to the label.
          -- fallback_highlight = "@variable",
          -- If provided, the plugin truncates the final displayed text to
          -- this width (measured in display cells). Any highlights that extend
          -- beyond the truncation point are ignored. When set to a float
          -- between 0 and 1, it'll be treated as percentage of the width of
          -- the window: math.floor(max_width * vim.api.nvim_win_get_width(0))
          -- Default 60.
          max_width = 60,
        })
      end,
    },
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
    -- 获取现有的 Pmenu 高亮组配置
    local pmenu_hl = vim.api.nvim_get_hl(0, { name = "Pmenu" })

    -- 添加/覆盖 blend 值
    pmenu_hl.blend = 0

    -- 重新设置 Pmenu 高亮组
    vim.api.nvim_set_hl(0, "Pmenu", pmenu_hl)

    -- vim.api.nvim_set_hl(0, "Pmenu", { bg = "#29293b", blend = 0 })
    -- vim.api.nvim_set_hl(0, "PmenuSel", { bg = colors.blue, fg = colors.base, blend = 0 })
    -- vim.api.nvim_set_hl(0, "PmenuBorder", { bg = colors.base, fg = colors.blue, blend = 0 })
    -- vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })

    local neotab = require("neotab")
    local luasnip = require("luasnip")

    luasnip.setup({
      enable_autosnippets = true,
    })

    require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    require("luasnip.loaders.from_lua").lazy_load({ paths = "./snippets_lua" })

    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local cmp = require("cmp")
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

    local has_words_before = function()
      if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
        return false
      end
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
    end

    return {
      window = {
        -- completion = cmp.config.window.bordered({
        --   -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        --   winhighlight = "Normal:Pmenu,FloatBorder:PmenuSel,Search:None",
        -- }),
        -- documentation = cmp.config.window.bordered({
        --   winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        -- }),
        completion = {
          -- winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          col_offset = -3,
          side_padding = 0,
        },
        documentation = {
          -- border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          max_width = 50,
          max_height = math.floor(vim.o.lines * 0.5),
        },
      },
      completion = {
        -- autocomplete = false,
        -- keyword_length = 2,
        -- keyword_length = 1,
      },

      preselect = cmp.PreselectMode.None,

      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },

      mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping(function()
          if cmp.visible() and has_words_before() then
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
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          elseif cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          end
        end),
        ["<C-p>"] = cmp.mapping(function()
          if luasnip.choice_active() then
            luasnip.change_choice(-1)
          elseif luasnip.expand_or_locally_jumpable(-1) then
            luasnip.expand_or_jump(-1)
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
            return not string.match(entry:get_completion_item().label, "^%d+$")
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
            preset = "codicons",
            symbol_map = { Copilot = "" },
            maxwidth = 20,
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
