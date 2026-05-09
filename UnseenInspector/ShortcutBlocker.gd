@tool
extends Control

## Add this as a child of your EditorPlugin node.
## It will block Ctrl+Arrow keys when focus is inside the inspector.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reparent.call_deferred(EditorInterface.get_inspector())

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	if not event.ctrl_pressed:
		return
	if event.keycode not in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		return

	var focused = get_viewport().gui_get_focus_owner()
	if focused and _get_inspector().is_ancestor_of(focused):
		get_viewport().set_input_as_handled()

func _get_inspector() -> EditorInspector:
	return EditorInterface.get_inspector()
