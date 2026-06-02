# Visio Diagram JSON Spec

The bundled script accepts a JSON object. Coordinates are Visio inches and the origin is bottom-left.

```json
{
  "title": "Example paper figure",
  "page": { "name": "Figure", "width": 11, "height": 8.5 },
  "nodes": [
    {
      "id": "client",
      "text": "Client",
      "x": 1.8,
      "y": 6.2,
      "width": 1.6,
      "height": 0.75,
      "fill": "RGB(227,242,253)"
    }
  ],
  "links": [
    { "from": "client", "to": "api", "text": "HTTPS", "style": "arrow" }
  ],
  "arrows": [
    { "x1": 5.5, "y1": 4.2, "x2": 5.5, "y2": 5.1, "style": "arrow" }
  ],
  "labels": [
    { "text": "Dense Layer", "x": 7.1, "y": 6.4, "width": 1.8, "height": 0.35, "fontSize": "16 pt" }
  ],
  "panels": [
    { "title": "Propose New Candidate", "x": 8, "y": 4, "width": 2.8, "height": 2.2, "headerFill": "RGB(255,242,204)" }
  ],
  "tables": [
    {
      "x": 2,
      "y": 2,
      "width": 3,
      "height": 1.4,
      "headerRows": 1,
      "colWidths": [1.2, 1, 1],
      "rowHeights": [0.8, 1, 1],
      "rows": [
        ["", "P1", "P2"],
        ["Task 1", "OK", "X"],
        ["Task 2", { "text": "merged", "colSpan": 2, "fill": "RGB(255,247,216)" }, ""]
      ]
    }
  ],
  "barCharts": [
    {
      "title": "Performance",
      "x": 8,
      "y": 2,
      "width": 2.4,
      "height": 1.1,
      "maxValue": 100,
      "bars": [
        { "label": "A", "value": 42, "fill": "RGB(218,238,216)" },
        { "label": "B", "value": 64, "fill": "RGB(232,218,236)" }
      ]
    }
  ],
  "lineCharts": [
    {
      "title": "Trend",
      "x": 8,
      "y": 3.2,
      "width": 2.4,
      "height": 1.1,
      "minValue": 0,
      "maxValue": 1,
      "series": [
        { "values": [0.2, 0.45, 0.7, 0.82], "line": "RGB(80,120,200)", "markers": true }
      ]
    }
  ],
  "cylinders": [
    { "text": "D_train", "x": 4.2, "y": 3.1, "width": 1.0, "height": 0.7, "subscripts": true }
  ],
  "icons": [
    { "kind": "document", "text": "Doc", "x": 6, "y": 2, "width": 0.45, "height": 0.6 },
    { "kind": "chip", "text": "LLM", "x": 6.8, "y": 2, "width": 0.65, "height": 0.55 },
    { "kind": "funnel", "text": "Filter", "x": 7.7, "y": 2, "width": 0.7, "height": 0.55 }
  ],
  "lists": [
    {
      "x": 2,
      "y": 1,
      "width": 3,
      "height": 1,
      "items": ["Use P_new", "Track D_train"],
      "subscripts": true
    }
  ],
  "curvedConnectors": [
    {
      "points": [
        { "x": 6, "y": 1.6 },
        { "x": 6.8, "y": 1.1 },
        { "x": 7.7, "y": 1.6 }
      ],
      "linePattern": "2",
      "style": "arrow"
    }
  ],
  "notes": [
    { "text": "Optional note text", "x": 1, "y": 1, "width": 9, "height": 0.8 }
  ]
}
```

Required fields:

- `nodes[].id`: unique string.
- `nodes[].text`: label shown inside the node.
- `nodes[].x`, `nodes[].y`: center point in inches.
- `links[].from`, `links[].to`: node ids.

Optional fields:

- `title`: large centered title near the top of the page.
- `page.name`, `page.width`, `page.height`.
- `nodes[].width`, `nodes[].height`, `nodes[].fill`, `nodes[].line`, `nodes[].shape`.
- `nodes[].font`, `nodes[].fontSize`, `nodes[].fontColor`, `nodes[].lineWeight`.
- `nodes[].layerCopies`, `nodes[].copyOffsetX`, `nodes[].copyOffsetY`, `nodes[].copyFill`, `nodes[].copyLine`.
- `nodes[].subscripts`: convert common underscore tokens such as `G_1`, `W_k`, and `P_new`.
- `links[].text`, `links[].style`; use `arrow` for a directed connector or `line` for no arrow. Avoid `text` in complex diagrams; prefer standalone `labels`.
- `arrows[]`: explicit coordinate arrows with `x1`, `y1`, `x2`, `y2`, optional `text`, `line`, `lineWeight`, `style`. Avoid `text` when it would sit on top of the line.
- `labels[]`: free-positioned text boxes. They default to no fill and no border. Set `subscripts: true` for underscore tokens.
- `panels[]`: framed paper modules with `title`, `x`, `y`, `width`, `height`, optional `fill`, `headerFill`, `line`, `fontSize`.
- `tables[]`: grid tables with `rows`, `x`, `y`, `width`, `height`, optional `headerRows`, `colWidths`, `rowHeights`, `fill`, `headerFill`, `line`, `fontSize`, and `subscripts`.
- Table cells may be strings or objects such as `{ "text": "OK", "fontColor": "RGB(0,185,45)", "fontSize": "14 pt" }`.
- Table cell objects can set `colSpan`, `rowSpan`, `fill`, `line`, `font`, `fontSize`, `fontColor`, and `subscripts`.
- `cylinders[]`: dataset/database cylinders with `text`, `x`, `y`, `width`, `height`, optional `ellipseHeight`, `fill`, `line`, `fontSize`.
- `icons[]`: small schematic symbols with `kind` set to `document`, `chip`, `database`, `dataset`, or `funnel`.
- `lists[]`: bullet or numbered lists with `items`, `x`, `y`, `width`, `height`, optional `ordered`, `bullet`, `box`, `fontSize`, `subscripts`.
- `trees[]`: small subgraphs with `nodes[]` and `edges[]`; useful for candidate pools or local tree diagrams.
- `barCharts[]`: compact chart panels with `bars[]`, `maxValue`, title, colors, and labels.
- `lineCharts[]`: compact trend charts with `series[]`, `values`, `minValue`, `maxValue`, optional markers and colors.
- `elbowConnectors[]`: multi-segment connectors with `points[]`, line styling, and arrow on the final segment.
- `curvedConnectors[]`: sampled smooth connector paths with `points[]`, line styling, optional dashed pattern, and arrow on the final segment.
- `notes[]`: labeled note rectangles.

Default colors:

- External actor: `RGB(227,242,253)`
- Service: `RGB(232,245,233)`
- Data store: `RGB(243,229,245)`
- Queue or worker: `RGB(237,231,246)`
- Warning or cache: `RGB(255,235,238)`

The script draws direct connectors between node edges based on node center positions. For complex routing or paper-style diagrams, use explicit `arrows`, `elbowConnectors`, or `curvedConnectors`.

## Visual QA and Anti-Overlap

For complex diagrams, connector labels can become unreadable because Visio places connector text at the line midpoint. Prefer this pattern:

- Use connectors only for direction and topology.
- Put explanations in independent `labels` near the relevant line.
- Give labels a white fill, for example `"fill": "RGB(255,255,255)"`, when they sit near other shapes.
- Route feedback loops above the main flow and data/writeback loops below the data nodes.
- Do not let multiple connectors share the same exact segment; give each path its own lane.
- Avoid vertical support lines from a memory/support band to every node unless they are essential.
- Export a PNG preview with `-ExportPngPath` and inspect it before considering the diagram complete.

Use `tables` for score matrices or detail boxes instead of manually positioning dozens of labels. Use styled table cells for highlighted values, green/red status text, and highlighted headers. Use `barCharts` and `lineCharts` for small performance panels; they are not a replacement for publication-quality statistical plotting, but are much more stable than manually drawn rectangles.

For paper-style diagrams, prefer `panels`, `tables`, `lists`, `icons`, `barCharts`, `lineCharts`, `elbowConnectors`, and `curvedConnectors` before falling back to manual rectangles and arrows. This keeps complex method figures editable and makes iterative layout fixes easier.

## Paper-Figure Example Pattern

Use a square page, explicit coordinates, larger fonts, and `layerCopies` for repeated stacked elements:

```json
{
  "page": { "name": "Attention Figure", "width": 8, "height": 8 },
  "nodes": [
    {
      "id": "sdpa",
      "text": "Scaled Dot Product Attention (SDPA)",
      "shape": "roundRect",
      "x": 4,
      "y": 4.1,
      "width": 7.2,
      "height": 0.8,
      "fill": "RGB(224,210,235)",
      "line": "RGB(145,105,170)",
      "lineWeight": "1.6 pt",
      "fontSize": "20 pt",
      "layerCopies": 3,
      "copyOffsetX": 0.12,
      "copyOffsetY": 0.10
    },
    {
      "id": "g1",
      "text": "G_1",
      "shape": "circle",
      "x": 4,
      "y": 5.45,
      "width": 0.62,
      "height": 0.62,
      "fill": "RGB(176,197,233)",
      "line": "none",
      "fontSize": "18 pt",
      "subscripts": true
    }
  ],
  "arrows": [
    { "x1": 4, "y1": 4.5, "x2": 4, "y2": 5.15, "lineWeight": "1.8 pt" }
  ],
  "labels": [
    { "text": "Most Effective!", "x": 2.4, "y": 5.45, "width": 1.8, "height": 0.35, "fontSize": "16 pt" }
  ]
}
```
