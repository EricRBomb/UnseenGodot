Unseen Grid:

	Unseen Grid is an accessibility addon for the Unseen Godot project, providing a spatial grid view of your scene's nodes to make 2D scene editing accessible without relying on the canvas.

	It appears as a main screen tab called "Unseen Grid" in the editor.

	Hotkeys:
		All hotkeys require CTRL held down. Keys can be changed in grid_editor_plugin.gd.

		Ctrl+F2 : Open the Unseen Grid tab
		Ctrl+U  : Jump to the grid cell of the currently selected node
		Ctrl+5  : Focus the Cell Size input

		Grid cell hotkeys (when a cell is focused):
			Space     : Select the node at this cell (opens a popup if multiple nodes share the cell)
			Ctrl+C    : Copy the node(s) at this cell
			Ctrl+X    : Cut the node(s) at this cell
			Ctrl+V    : Paste copied/cut node(s) to this cell's world position

	Features:
		1. 16x16 grid representing world space, where each cell maps to a region of size Cell Size x Cell Size pixels.
		2. Cells display the names of any Node2D or Control nodes positioned within them.
		3. Focusing a cell and pressing Space selects that node in the editor. If multiple nodes occupy the cell, a popup lets you pick which one.
		4. Cut+Paste moves a node to the target cell's world position, with undo/redo support. Copy+Paste duplicates it there instead.
		5. Jumping to a selected node (Ctrl+U) scrolls the grid focus to whichever cell that node occupies.
		6. TileMapLayer tiles are collected and displayed in the grid with their atlas coordinates and collision info (solid/disabled).
		7. Instanced scenes are shown in the grid but their children are not listed separately.
		8. Each cell's accessibility description is its X Y coordinate, so screen readers announce position when navigating.
		9. Cell size is adjustable via the header SpinBox, which updates the grid mapping live.
