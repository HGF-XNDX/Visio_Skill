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
- `links[].text`, `links[].style`; use `arrow` for a directed connector or `line` for no arrow.
- `notes[]`: labeled note rectangles.

Default colors:

- External actor: `RGB(227, 242, 253)`
- Service: `RGB(232, 245, 233)`
- Data store: `RGB(243, 229, 245)`
- Queue or worker: `RGB(237, 231, 246)`
- Warning or cache: `RGB(255, 235, 238)`

The script draws direct connectors between node edges based on node center positions. For complex routing, add intermediate nodes or revise the layout.
