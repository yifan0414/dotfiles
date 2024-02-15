return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = "org",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter" },
      { "dhruvasagar/vim-table-mode", enabled = false },
      {
        "akinsho/org-bullets.nvim",
        opts = {
          symbols = {
            -- list symbol
            list = "•",
            -- headlines can be a list
            headlines = { "◉", "○", "✸", "✿" },
            -- or a function that receives the defaults and returns a list
            checkboxes = {
              half = { "", "OrgTSCheckboxHalfChecked" },
              done = { "✓", "OrgDone" },
              todo = { "x", "OrgTODO" },
            },
          },
        },
        config = function(_, opts)
          require("org-bullets").setup(opts)
        end,
      },
    },
    opts = {
      org_capture_templates = {
        t = {
          description = "Task",
          template = "* TODO %?\n  %U",
        },
        J = {
          description = "Journal",
          template = "\n* %U\n%?\n",
          target = "~/org/journal/%<%Y-%m>.org",
        },
        e = "Event",
        er = {
          description = "recurring",
          template = "** %?\n %T",
          target = "~/org/calendar.org",
          headline = "recurring",
        },
        eo = {
          description = "one-time",
          template = "** %?\n %T",
          target = "~/org/calendar.org",
          headline = "one-time",
        },
      },
      -- org_priority_highest = "S",
      org_adapt_indentation = true,
      org_startup_indented = false,
      org_edit_src_content_indentation = 2,
      org_indent_mode_turns_off_org_adapt_indentation = true,
      org_agenda_files = "~/org/**/*.org",
      org_default_notes_file = "~/org/refile.org",
    },
    config = function(_, opts)
      -- Load treesitter grammar for org
      vim.keymap.set(
        "n",
        "<leader>ol",
        "<cmd>Telescope find_files cwd=~/org/<cr>",
        { noremap = true, silent = true, desc = "list org file" }
      )
      require("orgmode").setup_ts_grammar()

      require("nvim-treesitter.configs").setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "org" },
        },
        ensure_installed = { "org" },
      })
      -- Setup orgmode
      require("orgmode").setup(opts)
    end,
  },
}
