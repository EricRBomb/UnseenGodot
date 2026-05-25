# Unseen Virtual Cursor

Keyboard-friendly 2D scene editor tab. One readout label tells you what sits inside a square box; arrow keys move that box through the scene.

## Enable

## Hotkeys (Ctrl held)

| Key | Action |
|-----|--------|
| F2 | Open this tab |
| J | Jump virtual cursor to the selected node |
| T | Focus box size control |
| = / - | Grow or shrink the box by 4 pixels |

## Readout label (focus here to explore)

| Key | Action |
|-----|--------|
| Arrow keys | Move the box by one box-width step |
| Space | Select node(s) at the cursor (menu if several) |
| Ctrl+C / Ctrl+X / Ctrl+V | Copy, cut, paste at cursor |

## Cursor field

Type `x, y` (for example `128, 64`) and press Enter to jump the top-left corner of the box there.

## What gets listed

- **Node2D / Control** nodes whose position is inside the box 
- **TileMapLayer** tiles whose drawn position is inside the box 
- Packed-scene **children are hidden**, matching the scene tree dock.
