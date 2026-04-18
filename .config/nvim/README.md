# Neovim Config

基于 [LazyVim](https://github.com/LazyVim/LazyVim) 的个人 Neovim 配置，偏向终端内开发、C/C++ 工作流、竞赛题目、Markdown 写作，以及 tmux 驱动的日常使用方式。

这份配置不是“最小可移植模板”，而是一套长期自用配置：保留了不少个人习惯、终端工具链和目录约定。如果你准备直接使用，建议先看一遍下面的「个性化路径与假设」。

## 特性

- 以 `lazy.nvim` + `LazyVim` 为基础，启动快，结构清晰。
- 深色模式默认使用 `kanagawa`，浅色模式自动切换到 `catppuccin-latte`。
- 使用 `blink.cmp` + `LuaSnip` + `colorful-menu` 作为补全和片段系统。
- LSP 针对 `clangd`、`lua_ls`、`pyright`、`jdtls` 做了定制，配合 `tiny-inline-diagnostic` 显示行内诊断。
- 搜索与导航以 `telescope.nvim` 为中心，并接入 `Trouble`、`zoxide` 和一些自定义命令选择器。
- 终端工作流较重：集成 `AsyncRun`、`AsyncTask`、`Floaterm`、`Vimux`、tmux popup。
- 内置竞赛工作流：`competitest.nvim`、C/C++ 模板、编译运行快捷键。
- Git 工作流包含 `gitsigns`、`vim-fugitive`、`diffview.nvim`、`tig`。
- 额外覆盖 Markdown 预览、SQL UI、Outline、大纲、Snippet 编辑、录制宏、书签等常用能力。
- 针对 macOS、tmux、WSL 做了剪贴板适配。

## 适用场景

- C / C++ / Rust / Java / Python 开发
- 算法竞赛与题目调试
- Markdown / Org 风格笔记
- 终端重度用户
- tmux / kitty / yazi / tig 组合工作流

## 依赖

### 基础依赖

- `git`
- `Neovim >= 0.10`，推荐较新的版本；我当前使用的是 `0.12.x`
- 一个 Nerd Font
- `ripgrep`
- `fd`（建议）

### 按功能可选安装

- LSP / 调试：`clangd`、`codelldb`
- 编译运行：`gcc`、`g++`、`rustc`、`javac`
- 格式化：`google-java-format`、`pangu`、`shfmt`
- 终端工具：`tmux`、`kitty`、`yazi`、`tig`、`fzf`、`zoxide`
- 数据库：你自己需要的数据库客户端

如果某个功能你不用，不需要把这些都装齐。

## 安装

```bash
mv ~/.config/nvim ~/.config/nvim.bak
git clone <your-repo-url> ~/.config/nvim
nvim
```

首次启动时会自动安装 `lazy.nvim` 和插件。

如果你希望保留自己的旧配置，建议先手动对比这些文件再迁移：

- `lua/config/options.lua`
- `lua/config/keymaps.lua`
- `lua/plugins/`
- `tasks.ini`

## 常用快捷键

| 快捷键 | 作用 |
| --- | --- |
| `<leader>fo` | 强制格式化当前缓冲区 |
| `<leader>a1` | `AsyncTask file-build` |
| `<leader>a2` | `AsyncTask file-run` |
| `<leader>at` | 选择并运行自定义 AsyncTask |
| `<leader>1` | 运行 CompetiTest 当前测试 |
| `<leader>2` / `<leader>3` | 添加 / 编辑测试用例 |
| `<leader>e` | 打开 `vim-dadbod-ui` |
| `<leader>i` | 打开 Outline |
| `<leader>gl` | 用 `tig` 打开 Git 日志 |
| `<leader>gb` / `<leader>gs` | `Git blame` / `Git status` |
| `<F1>` | 切换 Floaterm |
| `<F2>` | 切换 `Snacks` terminal |
| `<F7>` / `<F8>` / `<F9>` | DAP Step Into / 重新编译并重启 / Step Over |
| `<leader>sf` / `<leader>se` | 新增 / 编辑 snippet |
| `<leader>um` | 切换 Markdown 渲染 |

## 目录结构

```text
.
├── init.lua
├── lazyvim.json
├── tasks.ini
├── template/
├── snippets/
├── snippets_lua/
└── lua/
    ├── config/
    └── plugins/
```

### 说明

- `lua/config/`: 基础配置，例如选项、按键、自动命令、主题切换。
- `lua/plugins/`: 所有插件配置，按功能拆分。
- `snippets/` 和 `snippets_lua/`: 分别存放 VS Code 风格和 Lua 风格片段。
- `tasks.ini`: `AsyncTask` 任务定义。
- `template/file.cpp`: 竞赛 / C++ 模板文件。

## 主要组件

### UI / 主题

- `kanagawa.nvim`
- `catppuccin`
- `lualine.nvim`
- `bufferline.nvim`
- `snacks.nvim`
- `noice.nvim`
- `neo-tree.nvim`

### 编辑体验

- `blink.cmp`
- `LuaSnip`
- `nvim-autopairs`
- `nvim-surround`
- `dial.nvim`
- `Comment.nvim`
- `nvim-spider`
- `nvim-various-textobjs`

### 搜索 / 导航 / 诊断

- `telescope.nvim`
- `Trouble`
- `Outline`
- `nvim-navic`
- `tiny-inline-diagnostic.nvim`

### 开发 / 任务 / 调试

- `nvim-lspconfig`
- `nvim-dap`
- `asyncrun.vim`
- `asynctasks.vim`
- `vim-floaterm`
- `vimux`
- `competitest.nvim`

### Git / 笔记 / 其他

- `gitsigns.nvim`
- `vim-fugitive`
- `diffview.nvim`
- `render-markdown.nvim`
- `vim-dadbod-ui`
- `nvim-scissors`
- `nvim-recorder`
- `arrow.nvim`

## 个性化路径与假设

这份配置里有一些明显偏个人的路径和使用前提，直接 clone 后你大概率需要改：

- `lua/config/keymaps.lua`
  - `<leader>td` 会打开 OneDrive 里的日记目录：
    `~/Library/CloudStorage/OneDrive-st.gxu.edu.cn/CSNote/Diary/`
- `lua/plugins/org.lua`
  - 默认 `org` 文件位于 `~/org`
- `lua/plugins/algorithm.lua`
  - `CompetiTest` 使用 `~/.config/nvim/template/file.cpp` 作为 C++ 模板
- `lua/plugins/telescope.lua`
  - 有多条命令直接依赖 `tmux popup`、`yadm`、`tig`
- `lua/plugins/tool.lua`
  - `go` 映射会把光标下 URL 发给 `kitty icat --passthrough tmux`
- `lua/config/options.lua`
  - macOS 下优先使用 `~/miniforge3/bin/python3` 或 `~/miniconda3/bin/python3`
  - tmux / WSL 剪贴板行为有专门适配

如果你只想复用这份配置的主体，优先修改上面这些位置。

## 已包含但未默认启用的能力

仓库里还保留了一些目前关闭的配置，方便以后按需打开，例如：

- `orgmode`
- `leetcode.nvim`
- `overseer.nvim`
- `harpoon`
- `smart-open`

## 备注

- 这份配置偏实用，不追求“开箱即用适配所有人”。
- 如果你准备 fork，建议先从 `lua/plugins/` 和 `lua/config/keymaps.lua` 开始删减。
- 如果你准备长期维护自己的版本，建议把个性化目录、外部命令和快捷键约定尽快抽离出来。
