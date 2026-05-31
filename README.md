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

- Architecture, network, topology, process, and flow diagrams
- Paper-style method figures with panels, tables, lists, trees, icons, cylinders, and routed connectors
- Compact paper chart panels including bar charts and line charts
- Editable `.vsdx` files with shapes, labels, colors, and connectors

## Repository Layout

```text
.codex-plugin/plugin.json
skills/visio-diagram/SKILL.md
skills/visio-diagram/scripts/new_visio_diagram.ps1
skills/visio-diagram/references/spec-format.md
figure-tests/
```

## How Other Users Install It

In Codex, install the skill/plugin from this GitHub repository URL:

```text
https://github.com/HGF-XNDX/Visio_Skill
```

After installation, ask Codex to use `$visio-diagram`.

## Script Smoke Test

From the repository root:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1
```

By default, the generated diagram is opened as an unsaved Visio document so the user can inspect, edit, and choose how to save it from Visio.

Export a PNG preview for visual review:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -SpecPath .\diagram.json -ExportPngPath .\diagram-preview.png
```

When revising an open diagram, redraw the active Visio page instead of creating another document:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -SpecPath .\diagram.json -UseActiveDocument -ExportPngPath .\diagram-preview.png -Force
```

Use `-OutputPath` when the script should save a `.vsdx`, and use `-NoOpen` for automated smoke tests or batch generation:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\skills\visio-diagram\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -NoOpen -Json
```

## Example Codex Prompt

```text
Use $visio-diagram to create an editable Visio method figure.
Draw a candidate-pool workflow with an initialization block, while-budget loop,
a score matrix table, a best-candidate table, a Pareto frontier panel,
a D_train cylinder, and dashed sample connectors.
Save it as paper-method.vsdx.
```

## Notes

- Generated files are editable in Visio.
- Existing output files are not overwritten unless the script is run with `-Force`.
- By default, the script leaves Visio open and does not save a file; the user saves from Visio.
- Use `-OutputPath`, `-Save`, or `-NoOpen` only when the script should write a `.vsdx`.
- Use `-ExportPngPath` for visual review and `-UseActiveDocument` for iterative redraws in the same open Visio document.
- The script does not run Visio macros.
