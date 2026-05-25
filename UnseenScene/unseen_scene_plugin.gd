@tool
extends EditorPlugin

var cursor_panel

const OPEN_TAB_KEY := KEY_F2
const JUMP_TO_SELECTION_KEY := KEY_J
const FOCUS_BOX_SIZE_KEY := KEY_T
const BOX_SIZE_STEP := 4

## Called when the editor enables the plugin.
## Instantiates the virtual cursor panel, wires signals, and adds it to the main screen (hidden until opened).
func _enter_tree() -> void:
	const panel_script: Script = preload("uid://b5dsbicwgk6nd")
	
	cursor_panel = panel_script.new()


	get_editor_interface().get_selection().selection_changed.connect(_on_editor_selection_changed)

	cursor_panel.node_focused.connect(_on_node_focused)
	cursor_panel.paste_at_position.connect(_on_paste_at_position)
	cursor_panel.box_size_changed.connect(_refresh_scene_nodes)
	cursor_panel.get_selection_nodes = func() -> Array[Node]:
		return get_editor_interface().get_selection().get_selected_nodes()

	var main_screen := get_editor_interface().get_editor_main_screen()
	main_screen.add_child(cursor_panel)
	cursor_panel.visible = false


## Called when the editor disables the plugin.
## Disconnects selection and panel signals, then frees the panel.
func _exit_tree() -> void:
	var selection := get_editor_interface().get_selection()
	if selection.selection_changed.is_connected(_on_editor_selection_changed):
		selection.selection_changed.disconnect(_on_editor_selection_changed)
		
	if is_instance_valid(cursor_panel):
		cursor_panel.queue_free()


## Called by Godot to decide if this plugin owns a main-screen tab.
## Returns true so "Unseen Virtual Cursor" appears as its own editor tab.
func _has_main_screen() -> bool:
	return true


## Called by Godot when labeling this plugin's main-screen tab.
func _get_plugin_name() -> String:
	return "Unseen Scene"


## Called whenever the user switches to or away from this plugin's main-screen tab.
## Shows or hides the panel; when shown, defers a scene refresh via _on_tab_opened.
func _make_visible(visible: bool) -> void:
	cursor_panel.visible = visible
	if visible:
		call_deferred("_on_tab_opened")


## Called when the tab becomes visible (_make_visible(true), deferred).
## Refreshes the node list for the currently edited scene.
func _on_tab_opened() -> void:
	if not is_instance_valid(cursor_panel):
		return
	_refresh_scene_nodes()


## Called whenever the user changes selection in the scene tree dock.
## If the virtual cursor tab is visible, rebuilds the panel node cache and readout.
func _on_editor_selection_changed() -> void:
	if not cursor_panel.visible:
		return
	_refresh_scene_nodes()


## Called by _on_tab_opened, _on_editor_selection_changed, _on_paste_at_position,
## and when the panel emits box_size_changed. Rebuilds cached nodes from the edited scene root and updates the readout.
func _refresh_scene_nodes() -> void:
	if not cursor_panel or not cursor_panel.is_inside_tree():
		return
	var scene_root := get_editor_interface().get_edited_scene_root()
	if scene_root and is_instance_valid(scene_root):
		cursor_panel.rebuild_node_list_from_scene(scene_root)
		cursor_panel.refresh_readout()


## Called when the panel emits node_focused (user picked a node under the cursor).
## Syncs the editor scene-tree selection to that node.
func _on_node_focused(node: Node) -> void:
	if node and is_instance_valid(node):
		var selection := get_editor_interface().get_selection()
		selection.clear()
		selection.add_node(node)


## Called when the panel emits paste_at_position (Ctrl+V on the readout).
## Moves cut nodes or duplicates copied nodes at the cursor via undo/redo, then refreshes the node list.
func _on_paste_at_position(position: Vector2) -> void:
	if not cursor_panel or cursor_panel.clipboard_nodes.is_empty():
		return

	var scene_root: Node = get_editor_interface().get_edited_scene_root()
	if not scene_root:
		return

	var undo_redo: EditorUndoRedoManager = get_undo_redo()
	var roots: Array[Node] = cursor_panel.clipboard_nodes
	var anchor_node: Node = roots[0]
	if not is_instance_valid(anchor_node):
		return

	var anchor_pos: Vector2 = Vector2.ZERO
	if anchor_node is Node2D or anchor_node is Control:
		anchor_pos = anchor_node.global_position
	var offset: Vector2 = position - anchor_pos

	if cursor_panel.clipboard_is_cut:
		undo_redo.create_action("Move Node(s) to Cursor Position")
		for node: Node in roots:
			if not is_instance_valid(node):
				continue
			if node is Node2D or node is Control:
				var old_pos: Vector2 = node.global_position
				var new_pos: Vector2 = old_pos + offset
				undo_redo.add_do_property(node, "global_position", new_pos)
				undo_redo.add_undo_property(node, "global_position", old_pos)
		cursor_panel._empty_clipboard()
		undo_redo.commit_action()
	else:
		undo_redo.create_action("Paste Node(s) at Cursor Position")
		for node: Node in roots:
			if not is_instance_valid(node):
				continue

			var parent: Node = _paste_parent_for(node, scene_root)
			var flags: int = _duplicate_flags_for(node)
			var duplicate: Node = node.duplicate(flags) as Node
			duplicate.name = _unique_name_under_parent(parent, node.name)

			if duplicate is Node2D or duplicate is Control:
				duplicate.global_position = node.global_position + offset

			undo_redo.add_do_method(parent, "add_child", duplicate)
			undo_redo.add_do_method(self, "_set_subtree_owner", duplicate, scene_root)
			undo_redo.add_do_reference(duplicate)
			undo_redo.add_undo_method(parent, "remove_child", duplicate)

		undo_redo.commit_action()

	_refresh_scene_nodes()


## Assigns scene_root as owner on node and every descendant so the scene tree dock lists them.
func _set_subtree_owner(node: Node, scene_root: Node) -> void:
	if node != scene_root:
		node.set_owner(scene_root)
	for child in node.get_children():
		_set_subtree_owner(child, scene_root)


## Returns the parent to paste under (original parent when valid, else scene root).
func _paste_parent_for(node: Node, scene_root: Node) -> Node:
	var parent: Node = node.get_parent()
	if parent and node.is_inside_tree() and node.owner == scene_root:
		return parent
	return scene_root


## Returns a sibling name under parent that does not collide with existing children.
func _unique_name_under_parent(parent: Node, base_name: String) -> String:
	if parent.get_node_or_null(NodePath(base_name)) == null:
		return base_name
	var counter: int = 2
	while parent.get_node_or_null(NodePath(base_name + str(counter))) != null:
		counter += 1
	return base_name + str(counter)


## Returns duplicate flags for node; uses instantiation for packed scene roots.
func _duplicate_flags_for(node: Node) -> int:
	var flags: int = (
		Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS
	)
	if node.get_scene_file_path() != "":
		flags |= Node.DUPLICATE_USE_INSTANTIATION
	return flags


## Called whenever the user presses a key in the editor.
## Handles Ctrl+F2 (open tab), Ctrl+J (jump to selection), Ctrl+T (focus box size),
## and Ctrl+= / Ctrl+- (resize box) when the tab is visible.
func _shortcut_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not event.ctrl_pressed:
		return

	if event.keycode == OPEN_TAB_KEY:
		open_virtual_cursor_tab()
	if cursor_panel.visible:
		if event.keycode == JUMP_TO_SELECTION_KEY:
			jump_cursor_to_selected_node()
		elif event.keycode == FOCUS_BOX_SIZE_KEY:
			cursor_panel.focus_box_size_control()
		elif event.keycode == KEY_EQUAL:
			cursor_panel.step_box_size(BOX_SIZE_STEP)
		elif event.keycode == KEY_MINUS:
			cursor_panel.step_box_size(-BOX_SIZE_STEP)


## Called when the user presses Ctrl+F2.
## Switches the main editor to the Unseen Scene tab.
func open_virtual_cursor_tab() -> void:
	get_editor_interface().set_main_screen_editor(_get_plugin_name())


## Called when the user presses Ctrl+J while the tab is visible.
## Moves the virtual cursor to the first node selected in the scene tree.
func jump_cursor_to_selected_node() -> void:
	if not cursor_panel:
		return

	var selected := get_editor_interface().get_selection().get_selected_nodes()
	if selected.is_empty():
		return

	var node: Node = selected[0]
	if is_instance_valid(node):
		cursor_panel.jump_cursor_to_node(node)
