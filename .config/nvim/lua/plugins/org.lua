return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter", Lazy = true },
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
    config = function()
      -- Load treesitter grammar for org
      require("orgmode").setup_ts_grammar()

      require("nvim-treesitter.configs").setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "org" },
        },
        ensure_installed = { "org" },
      })
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = "~/orgfiles/**/*",
        org_default_notes_file = "~/orgfiles/refile.org",
      })
    end,
  },
}
