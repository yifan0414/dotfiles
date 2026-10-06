---
name: setup-machine
description: Configure or reconcile the current Mac SSH workstation or Linux deep-learning server using this yadm checkout.
---

# 使用 yadm 配置当前机器

1. 读取 `~/.config/yadm/AGENTS.md` 和 [机器安装流程](references/machine-setup.md)，确定本次是仓库维护还是机器配置；角色选择、授权范围和 shell 组织遵循该入口。
2. 配置机器时先运行 `python3 ~/.config/yadm/scripts/machine-status.py --profile auto` 盘点。缺少基础工具才执行安装流程中的对应步骤。
3. 按角色读取 [Linux 服务器](references/dl-server.md) 或 [Mac 工作机](references/mac-client.md)。涉及组件时按需读取 [Conda/pip](references/conda-management.md) 或 [Hugging Face](references/huggingface.md)，使用其部署入口完成已授权的配置。
4. 按角色和组件的验收条件验证，报告当前机器已完成、未验证和受阻事项。其他机器的现场状态由各机独立核对。

`references/` 链接到 `~/.config/yadm/docs/` 的同一份文档。配置规则在主题文档维护，技能保留执行流程；修改规则时检查引用即可。
