@tool
extends EditorPlugin

#stuff to try and block editor from seeing our hotkeys outside of the inspector
const InspectorShortcutBlocker = preload("res://addons/UnseenInspector/ShortcutBlocker.gd")
var _shortcut_blocker: Control

var inspector = EditorInterface.get_inspector()
var focus_list_global
var focused
var up_parent_cooldown = false
#EditorInterface.get_inspector()

func _enter_tree() -> void:
	_shortcut_blocker = InspectorShortcutBlocker.new()
	add_child(_shortcut_blocker)  # _ready() handles injecting itself into the inspector

func _exit_tree() -> void:
	if _shortcut_blocker:
		_shortcut_blocker.queue_free()
		_shortcut_blocker = null



func _process(delta):
	if focused != get_viewport().gui_get_focus_owner():
		rebuild_inspector_focus()
	focused = get_viewport().gui_get_focus_owner()
	var ctrl := Input.is_key_pressed(KEY_CTRL)
	if Input.is_key_pressed(KEY_LEFT) and ctrl:
		if up_parent_cooldown == false:
			up_parent_cooldown = true
			go_up_parent(focused)
	elif Input.is_key_pressed(KEY_DOWN) and ctrl:
		if up_parent_cooldown == false:
			up_parent_cooldown = true
			goto_next()
	elif Input.is_key_pressed(KEY_UP) and ctrl:
		if up_parent_cooldown == false:
			up_parent_cooldown = true
			goto_previous()
	else:
		up_parent_cooldown = false

func rebuild_inspector_focus():
	focus_list_global = []
	recurse_check(inspector.get_parent(),0)
	set_vertical_focus_chain(focus_list_global)
	
func go_up_parent(f):
	var parent = f.get_parent()
	if parent is Control:
		if parent.focus_mode !=0:
			print(parent)
			parent.grab_focus()
		else:
			go_up_parent(parent)

func goto_next():
	var found = focus_list_global.find(focused,0)
	if "Category" in focused.name:
		if found != -1:
			var t = focus_list_global.find_custom(func(el): return "Category" in el.name, found+1)
			if t != -1:
				focus_list_global[t].grab_focus()
	if "EditorInspectorSection" in focused.name:
		if found != -1:
			var t = focus_list_global.find_custom(func(el): return "EditorInspectorSection" in el.name, found+1)
			if t != -1:
				focus_list_global[t].grab_focus()
	if focused is EditorProperty:
		if found != -1:
			var t = focus_list_global.find_custom(func(el): return "EditorProperty" in el.name, found+1)
			if t:
				focus_list_global[t].grab_focus()
				
func goto_previous():
	var found = focus_list_global.find(focused, 0)
	if "Category" in focused.name:
		if found != -1:
			print("found cat")
			var t = -1
			for i in range(found - 1, -1, -1):
				if "Category" in focus_list_global[i].name:
					t = i
					break
			if t != -1:
				focus_list_global[t].grab_focus()
	if "EditorInspectorSection" in focused.name:
		if found != -1:
			print("found section")
			var t = -1
			for i in range(found - 1, -1, -1):
				if "EditorInspectorSection" in focus_list_global[i].name:
					t = i
					break
			if t != -1:
				focus_list_global[t].grab_focus()
	if focused is EditorProperty:
		if found != -1:
			print("found property")
			var t = -1
			for i in range(found - 1, -1, -1):
				if "EditorProperty" in focus_list_global[i].name:
					t = i
					break
			if t != -1:
				focus_list_global[t].grab_focus()

func recurse_check(item,lvl):
	for ch in item.get_children():
		if ch is Control:
			if ch.visible == true:
				if 'EditorInspectorSection' in ch.name or  ch is EditorProperty or "Category" in ch.name:
					ch.focus_mode = 2
					if 'EditorInspectorSection' in ch.name:
						_is_expanded(ch)
				if ch.focus_mode !=0: 
					#ch.accessibility_name = get_accessibility_label(ch) + " " + ch.accessibility_name
					
					focus_list_global.append(ch)
					#some things were randomlly marked as toggleable
					if ch is Button and ch is not CheckBox and ch is not CheckButton :
						ch.toggle_mode = false
				
				recurse_check(ch,lvl+1)
				
func set_vertical_focus_chain(nodes: Array):
	for i in nodes.size():
		if i > 0:
			nodes[i].focus_neighbor_top = nodes[i].get_path_to(nodes[i - 1])
		if i < nodes.size() - 1:
			nodes[i].focus_neighbor_bottom = nodes[i].get_path_to(nodes[i + 1])

func get_accessibility_label(node: Control) -> String:
	# Walk up to find a parent EditorProperty and use its label
	var parent = node.get_parent()
	while parent != null:
		if parent is EditorProperty:
			return parent.label
		if parent is EditorInspector:
			break
		parent = parent.get_parent()
	return ""
	
#updating focus whenever keyboard input happen
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner and _is_in_inspector(focus_owner):
			rebuild_inspector_focus()

func _is_in_inspector(control: Control) -> bool:
	var node = control
	while node:
		if node is EditorInspector:
			return true
		node = node.get_parent()
	return false
#Saying if node is inspector section or not

func _is_expanded(section):
	for child in section.get_children():
		if child is Container:
			if child.visible:
				section.accessibility_description = "Unfolded"
			else: 
				section.accessibility_description = "Folded"
			return child.visible
	return false
