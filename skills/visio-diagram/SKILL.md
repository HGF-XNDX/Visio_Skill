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
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new_visio_diagram.ps1 -SpecPath .\diagram.json -OutputPath .\diagram.vsdx -Open
```

Use `-Json` when command output will be parsed programmatically:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new_visio_diagram.ps1 -SpecPath .\diagram.json -OutputPath .\diagram.vsdx -Json
```

For a quick environment smoke test, omit `-SpecPath`; the script generates a sample diagram:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new_visio_diagram.ps1 -OutputPath .\sample.vsdx -Open
```

Use `-Force` only after the user has approved overwriting the target `.vsdx`.

## Spec Format

Use `references/spec-format.md` for the JSON schema and examples. Keep generated specs simple:

- `page`: optional page settings.
- `nodes`: boxes with `id`, `text`, `x`, `y`, optional `width`, `height`, `fill`.
- `links`: connectors using `from`, `to`, optional `text`, `style`.
- `arrows`: explicit coordinate arrows for academic figures or non-graph layouts.
- `labels`: free-positioned text labels with no border/fill by default.
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
- Use `layerCopies`, `copyOffsetX`, and `copyOffsetY` for stacked blocks or repeated translucent circles.
- Keep the page close to the target aspect ratio. For square source figures, prefer an 8 by 8 inch page.
- Set `font: "Arial"` and explicit `fontSize` values for readable output.

## Automation Boundary

- Use only file operations, PowerShell, and the Visio COM object model.
- Do not invoke Computer Use or any screen-based automation to operate Visio.
- Do not verify by screenshot; verify by script output, file existence, file size, and COM-reported shape count.
- Use `-Open` only to leave the generated file visible in Visio; it is still script-driven and does not require UI interaction.

## Safety

- Do not overwrite an existing `.vsdx` unless the user asked for that exact path or approved replacement.
- Do not run macros from documents. This skill uses external PowerShell and Visio COM only.
- Do not handle Office security prompts or dialogs. Report the script error and ask the user to resolve the prompt manually.
