# Dotfiles

一套用于 Mac SSH 工作机和 Linux 深度学习服务器的 yadm 配置。

| 任务 | 入口 |
|---|---|
| 新机器安装、角色选择、公共与主机配置 | [机器安装流程](.config/yadm/docs/machine-setup.md) |
| Linux 服务器配置与验收 | [dl-server](.config/yadm/docs/dl-server.md) |
| Mac 工作机配置与验收 | [mac-client](.config/yadm/docs/mac-client.md) |
| HF 配置、日常工具与验收 | [Hugging Face](.config/yadm/docs/huggingface.md) |
| Conda 与 pip | [Conda/pip 管理](.config/yadm/docs/conda-management.md) |
| 日常同步、加密归档与 GitHub 凭据 | [同步与凭据](.config/yadm/docs/sync.md) |
| 由 agent 维护本仓库 | [AGENTS.md](.config/yadm/AGENTS.md) |

各主题的规则和操作步骤维护在上表对应文档中。软件包清单位于 [packages](.config/yadm/packages)，机器参数位于 [machines](.config/yadm/machines)。

运行离线回归检查：

```sh
python3 -B -m unittest discover -s ~/.config/yadm/tests -q
```

![nvim-startuptime](https://picture-suyifan.oss-cn-shenzhen.aliyuncs.com/uPic/QKCmiJ.png)
