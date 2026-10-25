# Fcitx5：中州韵版、白霜与科研词库

Mac 默认使用 Fcitx5 中州韵版、白霜全拼和 AI／ML 科研英文补充词库。中州韵版自带 Rime 插件，默认每页显示 7 个候选。Mac 整体安装流程见 [mac-client.md](mac-client.md)。

## 安装与部署

1. 运行 `yadm bootstrap`。选择 `fcitx5` 后，脚本安装遍黑体 P1、P2 字体，下载[白霜官方仓库](https://github.com/gaboolic/rime-frost)的 master 源码到 `~/.local/share/fcitx5/rime/`，然后打开[官方中州韵版安装器](https://github.com/fcitx-contrib/fcitx5-macos-installer/blob/master/README.zh-CN.md) `Fcitx5-Rime.zip`。
2. 在安装器中完成安装。首次安装后注销并重新登录，在「系统设置 → 键盘 → 文本输入 → 编辑」中添加 Fcitx5。
3. 切换到 Fcitx5，使用 Rime 中的「白霜拼音」。首次启动时 Rime 编译方案和词库。

重复运行时复用已有的 Rime 安装与白霜源码。`default.custom.yaml` 首次创建时指定白霜全拼和 7 个候选；后续沿用本机自定义设置与学习词库。已有 Fcitx5 但缺少 Rime 时，同样打开中州韵版安装器。

标点默认将 `/` 直接上屏为斜杠，映射保存在 `default.custom.yaml`。

单独安装字体、更新补充词库或部署白霜：

```sh
python3 ~/.config/yadm/scripts/setup_fcitx5.py --apply
```

Fcitx5 运行时脚本会请求 Rime 重新部署；尚未启动时，准备好的方案在下次启动时部署。

## 配置与路径

| 路径 | 用途与维护方式 |
|---|---|
| `~/.config/fcitx5/config`、`profile`、`conf/*.conf` | 输入法、快捷键和外观设置，纳入 yadm；默认输入法为 Rime |
| `~/.local/share/fcitx5/rime/` | 白霜方案、用户词库与编译结果，留在本机 |
| `~/Library/fcitx5/` | 已安装的插件资源，留在本机 |
| `~/Library/Fonts/PlangothicP1-Regular.otf`、`PlangothicP2-Regular.otf` | 遍黑体补字字体，由安装脚本下载，留在本机 |
| `~/.cache/yadm/` | 安装器与白霜下载缓存 |

键盘布局缓存留在本机。科研词库的维护源文件见下文。

## 候选框字体

候选词、编号、注释和预编辑区统一使用 `系统字体 → 遍黑体 P1 → 遍黑体 P2`，在 `~/.config/fcitx5/conf/webpanel.conf` 的四组 `Font/*FontFamily` 中维护。首项 `0=system-ui` 表示系统字体，后两项补充系统字体缺少的字符。

按照 [Fcitx5 官方 FAQ](https://fcitx-contrib.github.io/docs/faq.html#候选窗中有些字不显示)，安装遍黑体的 P1、P2 两个 Regular OTF 文件到 `~/Library/Fonts/`，然后重启输入法。脚本从[遍黑体官方发布页](https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/tag/V2.9.5795)下载 OTF ZIP 包，校验 SHA-256 后只安装这两个文件。下载缓存位于 `~/.cache/yadm/fcitx5/fonts/`，重复运行会复用已安装字体；yadm 保存安装规则和字体配置。

## AI／ML 科研英文补充词库

词条独立维护在 `~/.config/yadm/packages/fcitx5/ai_ml.dict.yaml`，覆盖模型、研究方法、多模态、训练推理、数据集、评测、工具框架和会议期刊。输入小写字母可选出规范大小写的名称，例如 `qwen` → `Qwen`、`llava` → `LLaVA`、`siglip` → `SigLIP`、`cvpr` → `CVPR`。

模型和工具末尾的数字版本合并到基础名，例如 `Llama 2/3` → `Llama`、`DINOv2/v3` → `DINO`。数字后仍有英文的名称保留完整写法，例如 `Qwen2.5-VL`、`GPT-4o`。

词库格式为 `显示词<Tab>输入编码<Tab>权重`，每行一个词条；多词短语的编码连写。编辑后运行上面的 `setup_fcitx5.py --apply`，脚本会同步至 `~/.local/share/fcitx5/rime/en_dicts/ai_ml.dict.yaml`，并在 `melt_eng.dict.yaml` 的 `import_tables` 中挂载它。bootstrap 同样会同步这份补充词库。

## 验收

1. 运行 `python3 ~/.config/yadm/scripts/machine-status.py --profile auto`，检查 `fcitx5_configuration` 中的 Rime 插件、引擎、默认输入法、白霜方案、AI／ML 补充词库、`plangothic_fonts_installed` 和 `font_fallback_configured` 状态。
2. 在系统键盘设置中确认 Fcitx5 输入源已启用，切换到白霜后确认中文输入和每页 7 个候选正常。
3. 检查 `qwen`、`llava`、`siglip`、`cvpr` 的英文候选出现在第一页；编辑科研词库并重新部署后确认更新生效。
4. 重启输入法后检查候选框中的普通汉字和「𣖐」均可显示，字体顺序为系统字体、遍黑体 P1、遍黑体 P2。
