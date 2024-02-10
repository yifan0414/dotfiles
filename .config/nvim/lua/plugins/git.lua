return {
  "lewis6991/gitsigns.nvim",
  opts = {
    on_attach = function(buffer)
      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { silent = true, buffer = buffer, desc = desc })
      end
      map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
      map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
    end,
  },
  {
    "tpope/vim-fugitive",
    cmd = "Git",
    keys = {
      -- { "<leader>gl", "<cmd>Git log<cr>", { silent = true, noremap = true }, desc = "Git log" },
      -- { "<leader>gd", "<cmd>Git diff %<cr>", { silent = true, noremap = true }, desc = "Git diff %" },
      { "<leader>gb", "<cmd>Git blame<cr>", { silent = true, noremap = true }, desc = "Git blame" },
      { "<leader>gs", "<cmd>Git<cr>", { silent = true, noremap = true }, desc = "Git status" },
    },
  },
}
