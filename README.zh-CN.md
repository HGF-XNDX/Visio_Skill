# Codex Visio Skill

[English](README.md) | [简体中文](README.zh-CN.md)

使用 Codex 根据文字描述生成可编辑的 Microsoft Visio `.vsdx` 图纸。

这个仓库包含一个 Codex 插件，其中有一个 `visio-diagram` skill。它采用纯脚本流程：Codex 先生成 JSON 图规范，然后运行仓库内置的 PowerShell 脚本，通过 Microsoft Visio COM 对象模型创建 `.vsdx` 文件。

它不使用 Computer Use、截图、鼠标点击、键盘输入或桌面 UI 自动化。

## 环境要求

- Windows
- 已安装 Microsoft Visio 桌面版
- PowerShell
- 支持插件/skill 的 Codex

Visio 网页版和 macOS 不支持这套 COM 自动化路径。

## 可以创建什么

- 架构图、网络图、拓扑图、流程图和过程图
- 论文风格方法图，包括面板、表格、列表、树、图标、圆柱体和路由连接线
- 论文里的紧凑图表面板，包括柱状图和折线图
- 包含形状、标签、颜色和连接线的可编辑 `.vsdx` 文件

## 仓库结构

```text
.codex-plugin/plugin.json
skills/visio-diagram/SKILL.md
skills/visio-diagram/scripts/new_visio_diagram.ps1
skills/visio-diagram/references/spec-format.md
figure-tests/
```

## 其他用户如何安装

在 Codex 中从这个 GitHub 仓库 URL 安装 skill/plugin：

```text
https://github.com/HGF-XNDX/Codex_Visio_Skill
```

安装后，在提示词里要求 Codex 使用 `$visio-diagram`。

## 脚本冒烟测试

在仓库根目录执行：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -Json
```

如果希望生成后让 Visio 保持打开，可以加上 `-Open`：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -Open
```

## 示例 Codex 提示词

```text
使用 $visio-diagram 创建一张可编辑的 Visio 论文方法图。
画一个候选池工作流：包含初始化模块、while budget 循环、
score matrix 表格、best candidate 表格、Pareto frontier 面板、
D_train 圆柱体，以及虚线 sample 连接线。
保存为 paper-method.vsdx。
```

## 注意事项

- 生成的文件可以在 Visio 中继续编辑。
- 如果目标文件已经存在，脚本默认不会覆盖；确认需要覆盖时才使用 `-Force`。
- 不加 `-Open` 时，脚本会保存并关闭文档，避免文件被锁住。
- 脚本不会运行 Visio 宏。
