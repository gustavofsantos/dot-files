---
name: canvas
description: Create and edit JSON Canvas files (.canvas) with nodes, edges, groups, and connections. Use when working with .canvas files, creating visual canvases, mind maps, flowcharts, or when the user mentions Canvas files in Obsidian.
---

# JSON Canvas Skill

A `.canvas` file follows the [JSON Canvas Spec 1.0](https://jsoncanvas.org/spec/1.0/): two top-level arrays, both optional.

```json
{ "nodes": [], "edges": [] }
```

Array order of `nodes` is z-index (first = bottom). After any create/edit: parse the JSON, confirm all `id`s are unique across nodes+edges, and confirm every `fromNode`/`toNode` resolves to an existing node.

See [references/EXAMPLES.md](references/EXAMPLES.md) for full mind-map / project-board / flowchart canvases.

## Nodes

Every node: `id` (unique 16-char lowercase hex, e.g. `"6f0ad84f44ce9c17"`), `type` (`text`|`file`|`link`|`group`), `x`, `y`, `width`, `height` (integers, px; top-left origin, negatives allowed). Optional `color` — preset `"1"`–`"6"` or hex `"#FF0000"`.

Per-type required field and example:

| type | extra field | notes |
|---|---|---|
| `text` | `text` (Markdown) | line breaks are `\n` — **never `\\n`**, Obsidian renders that literally |
| `file` | `file` (path) | optional `subpath` (`#heading`/`#^block`) |
| `link` | `url` | external URL |
| `group` | — | optional `label`, `background` (image path), `backgroundStyle` (`cover`/`ratio`/`repeat`); place child nodes inside its bounds |

```json
{ "id": "6f0ad84f44ce9c17", "type": "text", "x": 0, "y": 0, "width": 400, "height": 200,
  "text": "# Hello\n\n**Markdown** content." }
```

## Edges

| Attribute | Required | Default | Values |
|---|---|---|---|
| `id` | yes | — | unique |
| `fromNode` / `toNode` | yes | — | existing node ids |
| `fromSide` / `toSide` | no | — | `top`/`right`/`bottom`/`left` |
| `fromEnd` | no | `none` | `none`/`arrow` |
| `toEnd` | no | `arrow` | `none`/`arrow` |
| `color` | no | — | preset or hex |
| `label` | no | — | text on the edge |

```json
{ "id": "0123456789abcdef", "fromNode": "6f0ad84f44ce9c17", "fromSide": "right",
  "toNode": "a1b2c3d4e5f67890", "toSide": "left", "toEnd": "arrow", "label": "leads to" }
```

## Colors

Presets are app-defined (brand colors): `"1"` red, `"2"` orange, `"3"` yellow, `"4"` green, `"5"` cyan, `"6"` purple. Or any hex.

## Layout

Space nodes 50–100px apart, 20–50px padding inside groups, align to a 10/20 grid. Text nodes run ~200–600 wide × 80–500 tall depending on content.
