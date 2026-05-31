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
https://github.com/HGF-XNDX/Visio_Skill
```

安装后，在提示词里要求 Codex 使用 `$visio-diagram`。

## 脚本冒烟测试

在仓库根目录执行：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1
```

默认情况下，生成后的图会作为未保存的 Visio 文档打开，用户可以直接检查、编辑，并自己决定如何保存。

导出 PNG 预览图用于视觉检查：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -SpecPath .\diagram.json -ExportPngPath .\diagram-preview.png
```

修改已经打开的图时，复用当前 Visio 页面重画，而不是新建另一个文档：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -SpecPath .\diagram.json -UseActiveDocument -ExportPngPath .\diagram-preview.png -Force
```

如果希望脚本直接写出 `.vsdx`，可以传 `-OutputPath`；如果是自动化冒烟测试或批量生成，不希望留下 Visio 窗口，可以加 `-NoOpen`：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -NoOpen -Json
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
- 默认会打开并保留 Visio 窗口，而且不保存文件；用户从 Visio 中自行保存。
- 只有希望脚本写出 `.vsdx` 时才使用 `-OutputPath`、`-Save` 或 `-NoOpen`。
- 使用 `-ExportPngPath` 导出检查图；使用 `-UseActiveDocument` 在当前打开的 Visio 文档中迭代重画。
- 脚本不会运行 Visio 宏。
