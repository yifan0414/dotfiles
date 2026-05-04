return {
  name = "g++ build and run",
  builder = function()
    local file = vim.fn.expand("%:p")
    local outfile = vim.fn.expand("%:p:r")

    return {
      cmd = { "sh", "-c", string.format('g++ "%s" -o "%s" && "%s"', file, outfile, outfile) },
      components = {
        { "on_output_quickfix", open = false },
        "default",
      },
    }
  end,
  condition = {
    filetype = { "cpp" },
  },
}
