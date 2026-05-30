# Visio Diagram JSON Spec

The bundled script accepts a JSON object with this shape:

```json
{
  "title": "Example architecture",
  "page": {
    "name": "Architecture",
    "width": 11,
    "height": 8.5
  },
  "nodes": [
    {
      "id": "client",
      "text": "Client",
      "x": 1.8,
      "y": 6.2,
      "width": 1.6,
      "height": 0.75,
      "fill": "RGB(227, 242, 253)"
    }
  ],
  "links": [
    {
      "from": "client",
      "to": "api",
      "text": "HTTPS",
      "style": "arrow"
    }
  ],
  "arrows": [
    {
      "x1": 5.5,
      "y1": 4.2,
      "x2": 5.5,
      "y2": 5.1,
      "style": "arrow"
    }
  ],
  "labels": [
    {
      "text": "Dense Layer",
      "x": 7.1,
      "y": 6.4,
      "width": 1.8,
      "height": 0.35,
      "fontSize": "16 pt"
    }
  ],
  "tables": [
    {
      "x": 2,
      "y": 2,
      "width": 3,
      "height": 1.4,
      "headerRows": 1,
      "rows": [
        ["", "P1", "P2"],
        ["Task 1", "OK", "X"],
        ["Task 2", "X", "OK"]
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
  "notes": [
    {
      "text": "Optional note text",
      "x": 1,
      "y": 1,
      "width": 9,
      "height": 0.8
    }
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
- `links[].text`, `links[].style`; use `arrow` for a directed connector or `line` for no arrow.
- `arrows[]`: explicit coordinate arrows with `x1`, `y1`, `x2`, `y2`, optional `text`, `line`, `lineWeight`, `style`.
- `labels[]`: free-positioned text boxes. They default to no fill and no border.
- `tables[]`: grid tables with `rows`, `x`, `y`, `width`, `height`, optional `headerRows`, `fill`, `headerFill`, `line`, `fontSize`.
- `trees[]`: small subgraphs with `nodes[]` and `edges[]`; useful for candidate pools or local tree diagrams.
- `barCharts[]`: compact chart panels with `bars[]`, `maxValue`, title, colors, and labels.
- `elbowConnectors[]`: multi-segment connectors with `points[]`, line styling, and arrow on the final segment.
- `notes[]`: labeled note rectangles.

Default colors:

- External actor: `RGB(227, 242, 253)`
- Service: `RGB(232, 245, 233)`
- Data store: `RGB(243, 229, 245)`
- Queue or worker: `RGB(237, 231, 246)`
- Warning or cache: `RGB(255, 235, 238)`

The script draws direct connectors between node edges based on node center positions. For complex routing or paper-style diagrams, use explicit `arrows`.

Use `tables` for score matrices or detail boxes instead of manually positioning dozens of labels. Use `barCharts` for small performance panels; they are not a replacement for publication-quality statistical plotting, but are much more stable than manually drawn rectangles.

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
      "fill": "RGB(224, 210, 235)",
      "line": "RGB(145, 105, 170)",
      "lineWeight": "1.6 pt",
      "fontSize": "20 pt",
      "layerCopies": 3,
      "copyOffsetX": 0.12,
      "copyOffsetY": 0.10
    },
    {
      "id": "g1",
      "text": "G1",
      "shape": "circle",
      "x": 4,
      "y": 5.45,
      "width": 0.62,
      "height": 0.62,
      "fill": "RGB(176, 197, 233)",
      "line": "none",
      "fontSize": "18 pt"
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
