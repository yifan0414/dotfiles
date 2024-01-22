return {
  {
    "skywind3000/asyncrun.vim",
    -- event = "VeryLazy",
    cmd = "AsyncRun",
  },
  {
    "skywind3000/asynctasks.vim",
    -- event = "VeryLazy",
    cmd = "AsyncTask",
    keys = {
      {
        "<F1>",
        "<cmd>AsyncTask file-build<cr>",
        mode = "n",
      },
      {
        "<F2>",
        "<cmd>AsyncTask file-run<cr>",
        mode = "n",
      },
      {
        "<F3>",
        "<cmd>AsyncTask project-build<cr>",
        mode = "n",
      },
      {
        "<F4>",
        "<cmd>AsyncTask project-run<cr>",
        mode = "n",
      },
    },
  },
  {
    "blob42/vimux",
    event = "VeryLazy",
  },
}
