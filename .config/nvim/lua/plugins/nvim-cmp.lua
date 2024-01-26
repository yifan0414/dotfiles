return {
  "hrsh7th/nvim-cmp",
  version = false, -- last release is way too old
  event = "InsertEnter",
  dependencies = {
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "saadparwaiz1/cmp_luasnip" },
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
            { name = "cmdline" },
          }),
        })
      end,
    },
  },
  -- config = function()
  --   local has_words_before = function()
  --     unpack = unpack or table.unpack
  --     local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  --     return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
  --   end
  --   require("luasnip.loaders.from_vscode").lazy_load()
  --   local luasnip = require("luasnip")
  --   local cmp = require("cmp")
  --   cmp.setup({
  --     window = {
  --       -- How to disable scrollbar?
  --       completion = cmp.config.window.bordered(),
  --       documentation = cmp.config.window.bordered(),
  --     },
  --
  --     snippet = {
  --       expand = function(args)
  --         require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
  --       end,
  --     },
  --     sources = cmp.config.sources({
  --       { name = "nvim_lsp" },
  --       { name = "path" },
  --       { name = "luasnip" },
  --       { name = "buffer" },
  --     }),
  --     mapping = cmp.mapping.preset.insert({
  --       ["<Tab>"] = cmp.mapping(function(fallback)
  --         if cmp.visible() then
  --           -- cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
  --           cmp.confirm({ select = false })
  --           -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
  --           -- they way you will only jump inside the snippet region
  --         elseif luasnip.expand_or_jumpable() then
  --           luasnip.expand_or_jump()
  --         elseif has_words_before() then
  --           cmp.complete()
  --         else
  --           fallback()
  --         end
  --       end, { "i", "s" }),
  --
  --       ["<S-Tab>"] = cmp.mapping(function(fallback)
  --         if cmp.visible() then
  --           cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
  --         elseif luasnip.jumpable(-1) then
  --           luasnip.jump(-1)
  --         else
  --           fallback()
  --         end
  --       end, { "i", "s" }),
  --       -- ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --       ["<CR>"] = cmp.mapping({
  --         i = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
  --         -- c = function(fallback)
  --         --   if cmp.visible() then
  --         --     cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true})
  --         --   else
  --         --     fallback()
  --         --   end
  --         -- end
  --       }),
  --     }),
  --     formatting = {
  --       fields = { "abbr", "kind", "menu" },
  --       format = function(_, item)
  --         item.abbr = string.sub(item.abbr, 1, 30)
  --         local icons = require("lazyvim.config").icons.kinds
  --         if icons[item.kind] then
  --           item.kind = icons[item.kind] .. item.kind
  --         end
  --         return item
  --       end,
  --     },
  --
  --     -- experimental = {
  --     --   ghost_text = true,
  --     -- },
  --   })
  -- end,

  opts = function()
    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end
    require("luasnip.loaders.from_vscode").lazy_load()
    local luasnip = require("luasnip")
    vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
    local cmp = require("cmp")
    return {
      window = {
        completion = cmp.config.window.bordered({
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        }),
        -- documentation = cmp.config.window.bordered({
        --   winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        -- }),
        documentation = {
          border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
          max_width = 50,
          max_height = math.floor(vim.o.lines * 0.5)
        }
      },
      completion = {
        -- completeopt = "menu,menuone,noinsert",
      },
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- they way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),

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
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<S-CR>"] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
        -- { name = "buffer" },
        { name = "path" },
      }),
      formatting = {
        fields = { "abbr", "kind", "menu" },
        format = function(_, item)
          item.abbr = string.sub(item.abbr, 1, 30)
          item.menu = string.sub(1, 30) -- 暂时解决了问题
          local icons = require("lazyvim.config").icons.kinds
          if icons[item.kind] then
            item.kind = icons[item.kind] .. item.kind
          end
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
