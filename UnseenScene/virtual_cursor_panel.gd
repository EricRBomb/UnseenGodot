@tool
extends VBoxContainer

## Emitted when the user chooses a node under the cursor (Space or pick menu); plugin selects it in the scene tree.
signal node_focused(node: Node)
## Emitted when the user presses Ctrl+V on the readout; plugin pastes or moves clipboard nodes at the cursor.
signal paste_at_position(position: Vector2)
## Emitted when box size changes; plugin rebuilds cached nodes and readout.
signal box_size_changed()

var box_size: int = 32
var cursor_pos: Vector2i = Vector2i.ZERO

var cached_nodes: Array[Node] = []
var nodes_in_box: Array[Node] = []

var clipboard_nodes: Array[Node] = []
var clipboard_is_cut := false

## Set when the user Space-selects or picks from the overlap menu; used as sole copy/cut root.
var copy_target_node: Node = null
## Optional; plugin sets this to return editor scene-tree selection for copy resolution.
var get_selection_nodes: Callable

var box_size_spin: SpinBox
var cursor_field: LineEdit
var readout_label: Label

const PASTE_KEY := KEY_V
const CUT_KEY := KEY_X
const COPY_KEY := KEY_C


## Called when the panel enters the scene tree.
## Sets layout flags, builds UI controls, and shows the initial readout.
func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_readout()


## Called by _ready only.
## Creates box-size spinbox, cursor field, and readout label; connects their signals.
func _build_ui() -> void:
	var box_row := HBoxContainer.new()
	add_child(box_row)

	var box_label := Label.new()
	box_label.text = "Box size:"
	box_row.add_child(box_label)

	box_size_spin = SpinBox.new()
	box_size_spin.min_value = 1
	box_size_spin.max_value = 1024
	box_size_spin.value = box_size
	box_size_spin.step = 1
	box_size_spin.focus_mode = Control.FOCUS_ALL
	box_size_spin.select_all_on_focus = true
	box_size_spin.accessibility_description = "Width and height of the square you are looking at, in pixels."
	box_size_spin.value_changed.connect(_on_box_size_spin_changed)
	box_row.add_child(box_size_spin)

	var cursor_row := HBoxContainer.new()
	add_child(cursor_row)

	var cursor_label := Label.new()
	cursor_label.text = "Cursor:"
	cursor_row.add_child(cursor_label)

	cursor_field = LineEdit.new()
	cursor_field.placeholder_text = "0, 0"
	cursor_field.text = _cursor_pos_as_text()
	cursor_field.focus_mode = Control.FOCUS_ALL
	cursor_field.accessibility_description = "Top-left corner of your selection box. Type numbers and press Enter to jump there."
	cursor_field.text_submitted.connect(_on_cursor_field_submitted)
	cursor_field.focus_exited.connect(_on_cursor_field_focus_exited)
	cursor_row.add_child(cursor_field)

	readout_label = Label.new()
	readout_label.focus_mode = Control.FOCUS_ALL
	readout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout_label.custom_minimum_size = Vector2(200, 48)
	readout_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	readout_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	readout_label.gui_input.connect(_on_readout_input)
	readout_label.focus_entered.connect(refresh_readout)
	add_child(readout_label)


## Called by unseen_scene_plugin._refresh_scene_nodes when the edited scene or selection changes.
## Clears and repopulates cached_nodes from the scene root.
func rebuild_node_list_from_scene(scene_root: Node) -> void:
	cached_nodes.clear()
	if scene_root == null:
		return
	collect_scene_nodes(scene_root, cached_nodes, scene_root)


## Called by rebuild_node_list_from_scene (recursive).
## Walks the scene tree into out, skipping into packed sub-scenes like the old grid did.
func collect_scene_nodes(node: Node, out: Array[Node], scene_root: Node) -> void:
	if node != scene_root:
		out.append(node)
		if node.get_scene_file_path() != "":
			return
	for child in node.get_children():
		collect_scene_nodes(child, out, scene_root)

## Called after cursor or box changes, when readout gains focus, and from the plugin after scene refresh.
## Updates nodes_in_box, label text, and the accessibility description for what's under the cursor.
func refresh_readout() -> void:
	var box := Rect2(Vector2(cursor_pos), Vector2(box_size, box_size))
	var labels: PackedStringArray = []
	nodes_in_box.clear()

	labels.append_array(find_node_names_inside_box(box, nodes_in_box))
	labels.append_array(find_tile_labels_inside_box(box))

	if labels.is_empty():
		readout_label.text = "(empty)"
	else:
		readout_label.text = ", ".join(labels)

	readout_label.accessibility_description = (
		"Cursor at %d, %d. Box size %d. %s"
		% [cursor_pos.x, cursor_pos.y, box_size, readout_label.text]
	)

	if copy_target_node and (
		not is_instance_valid(copy_target_node) or copy_target_node not in nodes_in_box
	):
		copy_target_node = null


## Called by refresh_readout.
## Collects Node2D/Control names whose global position lies inside box into out_nodes.
func find_node_names_inside_box(box: Rect2, out_nodes: Array[Node]) -> PackedStringArray:
	var names: PackedStringArray = []
	for node in cached_nodes:
		if node is TileMapLayer:
			continue
		if not node is Node2D and not node is Control:
			continue
		var pos: Vector2 = node.global_position
		if not box.has_point(pos):
			continue
		out_nodes.append(node)
		names.append(node.name)
	return names


## Called by refresh_readout.
## Collects human-readable tile descriptions from TileMapLayers intersecting box.
func find_tile_labels_inside_box(box: Rect2) -> PackedStringArray:
	var labels: PackedStringArray = []
	for node in cached_nodes:
		if node is TileMapLayer:
			labels.append_array(find_tiles_on_layer_inside_box(node as TileMapLayer, box))
	return labels


## Called by find_tile_labels_inside_box for each TileMapLayer.
## Returns labels for used cells whose world position is inside box.
func find_tiles_on_layer_inside_box(layer: TileMapLayer, box: Rect2) -> PackedStringArray:
	var labels: PackedStringArray = []
	if layer.tile_set == null:
		return labels

	for tile_coords in layer.get_used_cells():
		var world_pos: Vector2 = layer.to_global(layer.map_to_local(tile_coords))
		if not box.has_point(world_pos):
			continue
		labels.append(describe_placed_tile(layer, tile_coords))
	return labels


## Called by find_tiles_on_layer_inside_box for each cell in the box.
## Builds a display string with atlas coords and collision/solid info.
func describe_placed_tile(layer: TileMapLayer, tile_coords: Vector2i) -> String:
	var tileset: TileSet = layer.tile_set
	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(tile_coords)
	var text: String = "%s[%d,%d]" % [layer.name, atlas_coords.x, atlas_coords.y]

	var tile_data: TileData = layer.get_cell_tile_data(tile_coords)
	if tile_data == null:
		return text

	var collision_mask: int = 0
	var physics_layer_count: int = tileset.get_physics_layers_count()
	for i in range(physics_layer_count):
		if tile_data.get_collision_polygons_count(i) > 0:
			collision_mask |= tileset.get_physics_layer_collision_layer(i)

	if collision_mask == 0:
		return text

	if layer.collision_enabled:
		text += " solid:%s" % ("%b" % collision_mask)
	else:
		text += " solid(disabled):%s" % ("%b" % collision_mask)
	return text


## Called when the user presses arrow keys on the readout (_on_readout_input).
## Moves the cursor by one box width or height and refreshes the readout.
func move_cursor_by_box_step(offset: Vector2i) -> void:
	cursor_pos += offset
	sync_cursor_field_to_display()
	refresh_readout()


## Called by unseen_scene_plugin.jump_cursor_to_selected_node (Ctrl+J).
## Snaps the cursor to a Node2D/Control global position and focuses the readout.
func jump_cursor_to_node(node: Node) -> void:
	if not node is Node2D and not node is Control:
		return
	cursor_pos = Vector2i(int(node.global_position.x), int(node.global_position.y))
	sync_cursor_field_to_display()
	refresh_readout()
	if readout_label:
		readout_label.grab_focus()


## Called when the user submits or leaves the cursor field.
## Parses "x, y" text into cursor_pos, or reverts the field on invalid input.
func apply_typed_cursor_position(text: String) -> void:
	var parsed: Variant = _parse_cursor_text(text)
	if parsed == null:
		sync_cursor_field_to_display()
		return
	cursor_pos = parsed as Vector2i
	sync_cursor_field_to_display()
	refresh_readout()


## Called after any programmatic cursor move.
## Updates the LineEdit to match cursor_pos.
func sync_cursor_field_to_display() -> void:
	if cursor_field:
		cursor_field.text = _cursor_pos_as_text()


## Called by sync_cursor_field_to_display, _build_ui, and field setup.
## Formats cursor_pos as "x, y".
func _cursor_pos_as_text() -> String:
	return "%d, %d" % [cursor_pos.x, cursor_pos.y]


## Called by apply_typed_cursor_position.
## Parses comma- or space-separated integers; returns null if invalid.
func _parse_cursor_text(text: String) -> Variant:
	var cleaned: String = text.strip_edges()
	if cleaned.is_empty():
		return null

	var parts: PackedStringArray
	if "," in cleaned:
		parts = cleaned.split(",", false)
	else:
		parts = cleaned.split(" ", false)

	if parts.size() < 2:
		return null

	if not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return null

	return Vector2i(parts[0].to_int(), parts[1].to_int())


## Called by the spinbox, step_box_size, and plugin shortcuts.
## Clamps size, syncs spinbox, emits box_size_changed, and refreshes readout.
func set_box_size(new_size: int) -> void:
	box_size = maxi(1, new_size)
	if box_size_spin and box_size_spin.value != box_size:
		box_size_spin.value = box_size
	box_size_changed.emit()
	refresh_readout()


## Called by plugin Ctrl+= and Ctrl+- shortcuts.
## Adds delta to box size via set_box_size.
func step_box_size(delta: int) -> void:
	set_box_size(box_size + delta)


## Called by plugin Ctrl+T shortcut.
## Focuses the box-size spinbox line edit for keyboard editing.
func focus_box_size_control() -> void:
	if box_size_spin:
		box_size_spin.get_line_edit().grab_focus()

## Called when the user presses Space on the readout.
## Emits node_focused for one node, or shows a pick menu if several overlap.
func select_nodes_at_cursor() -> void:
	if nodes_in_box.is_empty():
		return
	if nodes_in_box.size() == 1:
		copy_target_node = nodes_in_box[0]
		node_focused.emit(copy_target_node)
	else:
		_show_pick_one_node_menu(nodes_in_box)


func _set_clipboard(is_cut: bool) -> void:
	var sources: Array[Node] = _clipboard_source_nodes()
	if sources.is_empty():
		return
	clipboard_nodes.assign(sources)
	clipboard_is_cut = is_cut
	
## Returns clipboard roots: picked target, single in box, editor selection in box, or top-level in box.
func _clipboard_source_nodes() -> Array[Node]:
	if nodes_in_box.is_empty():
		return []

	if copy_target_node and is_instance_valid(copy_target_node) and copy_target_node in nodes_in_box:
		return [copy_target_node]

	if nodes_in_box.size() == 1:
		return [nodes_in_box[0]]

	var from_selection: Array[Node] = _selected_nodes_in_box()
	if not from_selection.is_empty():
		return _top_level_nodes_in_list(from_selection)

	return _top_level_nodes_in_list(nodes_in_box)


## Returns editor selection nodes that are also listed in nodes_in_box.
func _selected_nodes_in_box() -> Array[Node]:
	if get_selection_nodes.is_null() or not get_selection_nodes.is_valid():
		return []

	var selected: Array = get_selection_nodes.call()
	var in_box: Array[Node] = []
	for node in selected:
		if node is Node and is_instance_valid(node) and node in nodes_in_box:
			in_box.append(node)
	return in_box


## Drops nodes that are descendants of another node in the same list.
func _top_level_nodes_in_list(nodes: Array[Node]) -> Array[Node]:
	var result: Array[Node] = []
	for node in nodes:
		var dominated := false
		for other in nodes:
			if other != node and other.is_ancestor_of(node):
				dominated = true
				break
		if not dominated:
			result.append(node)
	return result


## Called by select_nodes_at_cursor when multiple nodes overlap the box.
## Shows a popup menu so the user can choose which node to focus.
func _show_pick_one_node_menu(nodes: Array[Node]) -> void:
	var popup := PopupMenu.new()
	popup.transparent_bg = true

	for i in range(nodes.size()):
		popup.add_item(nodes[i].name, i)

	popup.index_pressed.connect(func(index: int) -> void:
		if index < nodes.size():
			copy_target_node = nodes[index]
			node_focused.emit(copy_target_node)
	)

	add_child(popup)
	var anchor: Rect2 = readout_label.get_global_rect()
	popup.position = anchor.position + Vector2(0, anchor.size.y)
	popup.popup()

	popup.popup_hide.connect(func() -> void:
		if is_instance_valid(popup):
			popup.queue_free()
	)


## Called when the user changes the Box size spinbox value.
## Forwards to set_box_size, which emits box_size_changed for the plugin to refresh.
func _on_box_size_spin_changed(new_value: float) -> void:
	set_box_size(int(new_value))


## Called when the user presses Enter in the cursor field.
## Applies typed coordinates via apply_typed_cursor_position.
func _on_cursor_field_submitted(new_text: String) -> void:
	apply_typed_cursor_position(new_text)


## Called when the cursor field loses focus.
## Applies typed coordinates (same behavior as submit).
func _on_cursor_field_focus_exited() -> void:
	apply_typed_cursor_position(cursor_field.text)


## Called on key events while the readout has focus.
## Handles arrows (move box), Space (select), and Ctrl+C/X/V (copy/cut/paste).
func _on_readout_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	if event.keycode == KEY_RIGHT:
		move_cursor_by_box_step(Vector2i(box_size, 0))
		readout_label.accept_event()
	elif event.keycode == KEY_LEFT:
		move_cursor_by_box_step(Vector2i(-box_size, 0))
		readout_label.accept_event()
	elif event.keycode == KEY_DOWN:
		move_cursor_by_box_step(Vector2i(0, box_size))
		readout_label.accept_event()
	elif event.keycode == KEY_UP:
		move_cursor_by_box_step(Vector2i(0, -box_size))
		readout_label.accept_event()
	elif event.keycode == KEY_SPACE:
		select_nodes_at_cursor()
		readout_label.accept_event()
	elif event.ctrl_pressed and event.keycode == PASTE_KEY:
		paste_at_position.emit(Vector2(cursor_pos))
		readout_label.accept_event()
	elif event.ctrl_pressed and event.keycode == COPY_KEY:
		_set_clipboard(false)
		readout_label.accept_event()
	elif event.ctrl_pressed and event.keycode == CUT_KEY:
		_set_clipboard(true)
		readout_label.accept_event()


##Called by main script when it needs to clear the clipboard for tracking
##Empty clipboard
##Debug, will add more to this later, need to keep it.
func _empty_clipboard():
	clipboard_nodes.clear()
