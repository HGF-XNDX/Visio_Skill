# Codex Visio Skill

[English](README.md) | [简体中文](README.zh-CN.md)

使用 Codex 根据文字描述生成可编辑的 Microsoft Visio `.vsdx` 图纸。

这个仓库包含一个 Codex 插件，插件里有一个 `visio-diagram` skill。它采用纯脚本流程：Codex 先生成一份 JSON 图规格，然后运行仓库内置的 PowerShell 脚本，通过 Microsoft Visio 的 COM 对象模型创建 `.vsdx` 文件。

它不使用 Computer Use、截图、鼠标点击、键盘输入或桌面 UI 自动化。

## 环境要求

- Windows
- 已安装 Microsoft Visio 桌面版
- PowerShell
- 支持插件/skill 的 Codex

Visio 网页版和 macOS 不支持这套 COM 自动化路径。

## 可以创建什么

- 架构图
- 网络图和拓扑图
- 流程图
- 业务流程图
- 包含形状、标签、颜色和连接线的可编辑 `.vsdx` 文件

## 仓库结构

```text
.codex-plugin/plugin.json
skills/visio-diagram/SKILL.md
skills/visio-diagram/scripts/new_visio_diagram.ps1
skills/visio-diagram/references/spec-format.md
```

## 工作原理

1. 用户描述想要的图。
2. Codex 调用 `visio-diagram` skill。
3. Codex 写入一份 JSON 图规格。
4. `new_visio_diagram.ps1` 通过 COM 打开或启动 Visio。
5. 脚本创建一个可编辑的 `.vsdx` 文件。
6. Codex 通过脚本输出、文件是否存在、文件大小和 COM 返回的形状数量进行验证。

## 脚本冒烟测试

在仓库根目录执行：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -Json
```

期望输出是一段紧凑 JSON：

```json
{"OutputPath":"...sample.vsdx","Document":"sample.vsdx","Page":"Architecture","ShapeCount":13}
```

如果希望生成后让 Visio 显示该文件，可以加上 `-Open`：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -Open
```

## 示例 Codex 提示词

```text
Use $visio-diagram to create a Visio architecture diagram:
Client -> API Gateway -> API Service -> Worker -> Database.
Also show Redis cache connected to API Service.
Save it as architecture.vsdx.
```

也可以直接用中文描述：

```text
使用 $visio-diagram 创建一张 Visio 架构图：
用户浏览器访问 API 网关，API 网关转发到订单服务；
订单服务连接 Redis 缓存、消息队列和数据库；
后台 Worker 从消息队列消费任务并写入数据库。
保存为 order-architecture.vsdx。
```

## 注意事项

- 生成的文件可以在 Visio 中继续编辑。
- skill 默认创建新的 `.vsdx` 文件。
- 如果目标文件已存在，脚本默认不会覆盖；确认需要覆盖时才使用 `-Force`。
- 脚本不会运行 Visio 宏。
