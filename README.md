# Codex Visio Skill

[English](README.md) | [简体中文](README.zh-CN.md)

Generate editable Microsoft Visio `.vsdx` diagrams from text descriptions with Codex.

This repository contains a Codex plugin with one skill, `visio-diagram`. The skill uses a script-only workflow: Codex creates a JSON diagram specification and runs a bundled PowerShell script that automates Microsoft Visio through the Visio COM object model.

It does not use Computer Use, screenshots, mouse clicks, keyboard input, or desktop UI automation.

## Requirements

- Windows
- Microsoft Visio desktop installed
- PowerShell
- Codex with plugin/skill support

Visio for the web and macOS do not support this COM automation path.

## What It Can Create

- Architecture diagrams
- Network and topology diagrams
- Flowcharts
- Process diagrams
- Editable `.vsdx` files with shapes, labels, colors, and connectors

## Repository Layout

```text
.codex-plugin/plugin.json
skills/visio-diagram/SKILL.md
skills/visio-diagram/scripts/new_visio_diagram.ps1
skills/visio-diagram/references/spec-format.md
```

## How It Works

1. The user describes a diagram.
2. Codex invokes the `visio-diagram` skill.
3. Codex writes a JSON diagram spec.
4. `new_visio_diagram.ps1` opens or starts Visio through COM.
5. The script creates an editable `.vsdx` file.
6. Codex verifies by script output, file existence, file size, and COM-reported shape count.

## Script Smoke Test

From the repository root:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -Json
```

Expected output is compact JSON:

```json
{"OutputPath":"...sample.vsdx","Document":"sample.vsdx","Page":"Architecture","ShapeCount":13}
```

Add `-Open` to leave the generated file visible in Visio:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -Open
```

## Example Codex Prompt

```text
Use $visio-diagram to create a Visio architecture diagram:
Client -> API Gateway -> API Service -> Worker -> Database.
Also show Redis cache connected to API Service.
Save it as architecture.vsdx.
```

## Notes

- The generated file is editable in Visio.
- The skill defaults to creating a new `.vsdx`.
- Existing output files are not overwritten unless the script is run with `-Force`.
- The script does not run Visio macros.
