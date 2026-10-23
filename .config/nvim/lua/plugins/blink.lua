return {
  "saghen/blink.cmp",
  enabled = true,
  -- optional: provides snippets for the snippet source
  event = "InsertEnter",
  dependencies = { { "xzbdmw/colorful-menu.nvim" } },
  -- build = "cargo build --release",
  -- build = "rustup run nightly cargo build --release",
  -- version = false,
  version = "1.*",
  opts = function()
    local kinds = require("blink.cmp.types").CompletionItemKind

    local identifier_cache = {}
    vim.api.nvim_create_autocmd("BufWipeout", {
      group = vim.api.nvim_create_augroup("DotfilesBlinkIdentifiers", { clear = true }),
      callback = function(event)
        identifier_cache[event.buf] = nil
      end,
    })

    local function get_buffer_identifiers(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
        return {}
      end
      local tick = vim.api.nvim_buf_get_changedtick(bufnr)
      -- Bound scanning on large files and reuse results until the text or range changes.
      local cursor = vim.api.nvim_get_current_buf() == bufnr and vim.api.nvim_win_get_cursor(0)[1] or 1
      local first = math.max(0, cursor - 201)
      local last = math.min(vim.api.nvim_buf_line_count(bufnr), cursor + 200)
      local cached = identifier_cache[bufnr]
      if cached and cached.tick == tick and cached.first == first and cached.last == last then
        return cached.words
      end
      local words = {}
      for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, first, last, false)) do
        for word in line:gmatch("[%a_][%w_]*") do
          words[word] = true
        end
      end
      identifier_cache[bufnr] = { tick = tick, first = first, last = last, words = words }
      return words
    end

    return {
      snippets = {
        preset = "luasnip",
        score_offset = 0,
      },
      keymap = {
        -- set to 'none' to disable the 'default' preset
        ["<Tab>"] = {
          function(cmp)
            if cmp.is_visible() then
              return cmp.select_next()
            else
              -- cmp.hide()
              return cmp.snippet_forward()
            end
          end,
          "fallback",
        },
        ["<S-Tab>"] = {
          function(cmp)
            if cmp.is_visible() then
              return cmp.select_prev()
            else
              -- cmp.hide()
              return cmp.snippet_backward()
            end
          end,
          "fallback",
        },
        ["<CR>"] = {
          "select_and_accept",
          "fallback",
        },
        -- optionally, separate cmdline keymaps
        -- cmdline = {
        --   preset = "enter",
        --   -- ["enter"] = {
        --   --   "accept",
        --   --   "fallback",
        --   -- },
        -- },
      },
      cmdline = {
        sources = function()
          local type = vim.fn.getcmdtype()
          -- Search forward and backward
          if type == "/" or type == "?" then
            return { "buffer" }
          end
          -- Commands
          if type == ":" or type == "@" then
            return { "cmdline", "buffer" }
          end
          return {}
        end,
        keymap = {
          preset = "inherit",
          ["<CR>"] = {
            "accept_and_enter",
            "fallback",
          },
          ["<Tab>"] = {
            "select_next",
            "fallback",
          },
          -- ["<S-Tab>"] = {
          --   "select_prev",
          --   "fallback",
          -- },
        },
        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = nil, -- Inherits from top level `completion.trigger.show_on_blocked_trigger_characters` config when not set
          },
          menu = {
            auto_show = true, -- Inherits from top level `completion.menu.auto_show` config when not set
          },
          list = {
            selection = {
              -- When `true`, will automatically select the first item in the completion list
              preselect = false,
              -- When `true`, inserts the completion item automatically when selecting it
              auto_insert = true,
            },
          },
        },
      },
      completion = {
        -- 'prefix' will fuzzy match on the text before the cursor
        -- 'full' will fuzzy match on the text before *and* after the cursor
        -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
        keyword = { range = "prefix" },

        -- trigger = {
        --   prefetch_on_insert = true,
        --   show_in_snippet = true,
        --   show_on_keyword = true,
        --   show_on_blocked_trigger_characters = { " ", "\n", "\t", "-" },
        --
        --   show_on_trigger_character = false,
        --   show_on_accept_on_trigger_character = true,
        --   show_on_x_blocked_trigger_characters = { "'", '"', "(", "{", "[", ".", " ", "-", "+" },
        -- },

        documentation = {
          auto_show = true,
          auto_show_delay_ms = 100,
          window = {
            min_width = 10,
            max_width = 80,
            max_height = 20,
            border = "rounded",
            winblend = 0,
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",

            -- Note that the gutter will be disabled when border ~= 'none'
            scrollbar = true,
            -- Which directions to show the documentation window,
            -- for each of the possible menu window directions,
            -- falling back to the next direction when there's not enough space
            direction_priority = {
              menu_north = { "e", "w", "n", "s" },
              menu_south = { "e", "w", "s", "n" },
            },
          },
        },
        -- Disable auto brackets
        -- NOTE: some LSPs may add auto brackets themselves anyway
        accept = { auto_brackets = { enabled = true } },
        menu = {
          draw = {
            -- We don't need label_description now because label and label_description are already
            -- conbined together in label by colorful-menu.nvim.
            columns = { { "kind_icon" }, { "label", gap = 1 } },
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
          },
        }, -- or set either per mode via a function
        list = {
          selection = {
            preselect = false,
            auto_insert = true,
          },
        },
      },

      appearance = {
        nerd_font_variant = "mono",
        -- use_nvim_cmp_as_default = true,
        kind_icons = {
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
          -- Variable = "󰫧 ",
        },
      },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          lsp = {
            transform_items = function(ctx, items)
              local buffer_words = get_buffer_identifiers(ctx.bufnr)

              return vim.tbl_map(function(item)
                local offset = item.score_offset or 0

                if item.kind == kinds.Variable or item.kind == kinds.Field or item.kind == kinds.Property then
                  offset = offset + 4
                  if buffer_words[item.label] then
                    offset = offset + 6
                  end
                elseif item.kind == kinds.Constant or item.kind == kinds.EnumMember then
                  if buffer_words[item.label] then
                    offset = offset + 5
                  end
                elseif item.kind == kinds.Function or item.kind == kinds.Method then
                  offset = offset - 4
                end

                item.score_offset = offset
                return item
              end, vim.tbl_filter(function(item)
                return item.kind ~= kinds.Snippet and item.kind ~= kinds.Constructor
              end, items))
            end,
            -- should_show_items = function(ctx)
            --   return ctx.trigger.initial_kind ~= "trigger_character"
            -- end,
          },
          snippets = {
            score_offset = 2,
            max_items = 4,
            -- should_show_items = function(ctx)
            --   return ctx.trigger.initial_kind ~= "trigger_character"
            -- end,
            min_keyword_length = 1, -- don't show when triggered manually, useful for JSON keys
            opts = {
              -- Whether to use show_condition for filtering snippets
              use_show_condition = true,
              -- Whether to show autosnippets in the completion list
              show_autosnippets = true,
            },
          },
          buffer = {
            max_items = 5,
            -- should_show_items = function(ctx)
            --   return ctx.trigger.initial_kind ~= "trigger_character"
            -- end,
          },
        },
      },
      fuzzy = {
        max_typos = function(keyword)
          return math.floor(#keyword / 4)
        end,
        implementation = "prefer_rust_with_warning",
        frecency = { enabled = true },
        use_proximity = true,
        sorts = { "exact", "score", "sort_text" },
        prebuilt_binaries = {
          -- force_eersion = "main",
          download = true,
          -- extra_curl_args = { "--proxy", "http://127.0.0.1:7890" },
          proxy = {
            -- When downloading a prebuilt binary, use the HTTPS_PROXY environment variable
            from_env = true,
            -- When downloading a prebuilt binary, use this proxy URL. This will ignore the HTTPS_PROXY environment variable
            -- url = nil,
          },
        },
      },
    }
  end,
}
