return {
  {
    "xiyaowong/virtcolumn.nvim",
    enabled = false,
    event = "BufReadPost",
  },
  {
    "blob42/vimux",
    keys = {
      {
        "<leader>r",
        function()
          local function vimux_slime()
            -- 调用 VimScript 函数 VimuxRunCommand，传递寄存器 v 的内容和 0 作为参数
            vim.fn.VimuxRunCommand(vim.fn.getreg("v"), 0)
          end
          vim.cmd('normal! "vy')
          vimux_slime()
        end,
        mode = "v",
      },
      {
        "<leader>vr",
        function()
          local function vimux_slime()
            -- 调用 VimScript 函数 VimuxRunCommand，传递寄存器 v 的内容和 0 作为参数
            vim.fn.VimuxRunCommand(vim.fn.getreg("v"), 0)
          end
          vim.cmd('normal! "vyip')
          vim.fn.setreg("v", vim.fn.getreg("v") .. "\n\n")
          vimux_slime()
        end,
        mode = "n",
      },
    },
  },
}
