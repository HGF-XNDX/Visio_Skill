---
name: visio-diagram
description: Generate editable Microsoft Visio .vsdx diagrams from text descriptions by creating a JSON diagram specification and running a bundled PowerShell script through the Visio COM object model. Use when Codex needs to create or modify Visio architecture diagrams, network diagrams, flowcharts, process diagrams, topology diagrams, or other editable Visio drawings on Windows with Microsoft Visio installed.
---

# Visio Diagram

Use this skill to create editable Visio diagrams from user descriptions through scripts only. Do not use Computer Use, screenshot inspection, mouse clicks, keyboard input, or other desktop UI automation for this skill.

## Requirements

- Windows with Microsoft Visio desktop installed.
- PowerShell available.
- The user permits running a local script that automates Visio through COM.
- The output should be an editable `.vsdx`, not a screenshot or static image.

If Visio is unavailable, explain that this skill cannot render `.vsdx` locally and offer to create a JSON spec, Mermaid diagram, SVG, or draw.io XML instead.

## Workflow

1. Convert the user's description into a diagram spec JSON file.
2. Use `scripts/new_visio_diagram.ps1` to generate the `.vsdx`.
3. Verify with shell/script output that the `.vsdx` exists and the script reports a document, page, and shape count.
4. Iterate on layout, labels, colors, and connections by editing the JSON spec and rerunning the script.

Run from the skill directory or pass absolute paths:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new_visio_diagram.ps1 -SpecPath .\diagram.json
```

By default the script opens Visio, creates an unsaved editable diagram, and leaves it visible so the user can inspect, edit, and choose how to save from Visio. Use `-OutputPath` or `-Save` only when the user explicitly wants the script to save a `.vsdx`.

Use `-Json` when command output will be parsed programmatically:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new_visio_diagram.ps1 -SpecPath .\diagram.json -OutputPath .\diagram.vsdx -NoOpen -Json
```

For a quick environment smoke test, omit `-SpecPath`; the script generates a sample diagram:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new_visio_diagram.ps1
```

Use `-NoOpen` for automated smoke tests or batch generation where no visible Visio window should remain open. `-NoOpen` saves to `-OutputPath`, or to `visio-diagram.vsdx` if no output path is provided.

Use `-Force` only after the user has approved overwriting the target `.vsdx`.

## Spec Format

Use `references/spec-format.md` for the JSON schema and examples. Keep generated specs simple:

- `page`: optional page settings.
- `nodes`: boxes with `id`, `text`, `x`, `y`, optional `width`, `height`, `fill`.
- `links`: connectors using `from`, `to`, optional `text`, `style`.
- `arrows`: explicit coordinate arrows for academic figures or non-graph layouts.
- `labels`: free-positioned text labels with no border/fill by default.
- `panels`: section boxes with optional title bars for paper figure modules.
- `tables`: grid layouts for score matrices, module descriptions, and compact comparison panels.
- `cylinders`: database or dataset symbols such as `Dtrain`.
- `icons`: small document, chip, database/dataset, and funnel symbols.
- `lists`: compact bullet or numbered lists inside method/detail panels.
- `trees`: small node-edge subgraphs inside larger figures.
- `barCharts`: compact performance charts for paper overview figures.
- `lineCharts`: compact trend charts with one or more series.
- `elbowConnectors`: routed multi-segment connectors when straight lines cross important content.
- `curvedConnectors`: smooth-looking sampled connectors for dotted sample paths or feedback loops.
- `groups` or advanced Visio masters are not required unless the user asks.

Coordinates are in Visio inches. The origin is bottom-left. A good default page is 11 by 8.5 inches.

## Layout Guidance

- Use left-to-right flow for request paths and top-to-bottom flow for layered systems.
- Keep at least 1 inch between node centers horizontally and 1.25 inches vertically for readability.
- Use short labels on connectors.
- Use pastel fills for node categories; avoid relying only on color to encode meaning.
- Prefer creating a new `.vsdx` unless the user explicitly asks to modify the current Visio document.

For paper-figure recreation or reference-image style diagrams:

- If the user asks for a neural-network/attention-style figure, inspect `references/attention-figure-example.json` as a concrete pattern.
- Use explicit `x`, `y`, `width`, and `height` for every shape; do not rely on auto layout.
- Use `arrows` for precise vertical or diagonal arrows instead of `links` when the figure is not a simple graph.
- Use `labels` for annotations such as "Dense Layer" or "Most Effective!" instead of encoding them as nodes.
- Use `tables` for score matrices, right-side method-detail boxes, and other dense rectangular content.
- Use `colWidths`, `rowHeights`, `colSpan`, and `rowSpan` when recreating paper tables or matrices.
- Use per-cell table objects (`{"text": "...", "fontColor": "...", "fontSize": "..."}`) for highlighted cells, score matrices, and merged notes.
- Use `panels` to frame repeated modules such as "Propose New Candidate" or "Pareto-based Candidate Filtering".
- Use `lists` for dense method notes rather than manually placing many labels.
- Use `cylinders` for datasets, databases, memory stores, or corpus icons.
- Use `barCharts` for small metric panels instead of drawing bars manually.
- Use `lineCharts` for small trend panels, convergence curves, or training/evaluation traces.
- Use `icons` for schematic document, model/chip, dataset, database, or filter symbols.
- Use `elbowConnectors` when a connector must route around a panel.
- Use `curvedConnectors` for sampled data paths, feedback arrows, and soft loop arrows.
- Use `layerCopies`, `copyOffsetX`, and `copyOffsetY` for stacked blocks or repeated translucent circles.
- Set `subscripts: true` on labels, tables, or lists to convert common tokens such as `P_new`, `D_train`, `G_1`, `W_k`, and `W_v` into subscript-like text.
- Keep the page close to the target aspect ratio. For square source figures, prefer an 8 by 8 inch page.
- Set `font: "Arial"` and explicit `fontSize` values for readable output.

## Automation Boundary

- Use only file operations, PowerShell, and the Visio COM object model.
- Do not invoke Computer Use or any screen-based automation to operate Visio.
- Do not verify by screenshot; verify by script output, file existence, file size, and COM-reported shape count.
- The default behavior leaves the generated file visible in Visio; it is still script-driven and does not require UI interaction.
- The default behavior does not save a `.vsdx`; the user chooses whether and where to save from Visio.
- Use `-NoOpen` for automated verification when the document should be saved and closed without leaving a Visio window open.

## Safety

- Do not pass `-OutputPath`, `-Save`, or `-NoOpen` unless the user wants a file saved by the script.
- Do not overwrite an existing `.vsdx` unless the user asked for that exact path or approved replacement.
- Do not run macros from documents. This skill uses external PowerShell and Visio COM only.
- Do not handle Office security prompts or dialogs. Report the script error and ask the user to resolve the prompt manually.
