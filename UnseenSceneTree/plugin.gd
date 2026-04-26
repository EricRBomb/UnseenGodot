@tool
extends EditorPlugin

var current_tree

func _ready():
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _on_focus_changed(control):
	if control is Tree:
		if not control.is_connected("cell_selected", _refresh_tree):
			control.cell_selected.connect(_refresh_tree)
		current_tree = control
		iterate_tree(control.get_root())

func _refresh_tree():
	iterate_tree(current_tree.get_root())

func iterate_tree(root: TreeItem) -> void:
	var stack = [root]
	while stack.size() > 0:
		var item: TreeItem = stack.pop_back()
		# do something with item here
		
		var tt_text = get_item_depth(item)
		#Windows reads out both name and description atm, so we just update the description so it reads out our tag then name.
		if OS.has_feature("windows"):

			if item.get_first_child() == null:
				item.set_description(0,"Level:"+str(tt_text))
			elif  not item.is_collapsed():
				item.set_description(0,"Expanded level:"+str(tt_text))
			elif item.is_collapsed() and item.get_first_child() != null:
				item.set_description(0,"collapsed Level:"+str(tt_text))
		else:

			if item.get_first_child() == null:
				item.set_description(0,item.get_text(0)+" Level:"+str(tt_text))
			elif  not item.is_collapsed():
				item.set_description(0,item.get_text(0)+" Expanded level:"+str(tt_text))
			elif item.is_collapsed() and item.get_first_child() != null:
				item.set_description(0,item.get_text(0)+" collapsed Level:"+str(tt_text))
		var child = item.get_first_child()
		while child != null:
			stack.append(child)
			child = child.get_next()

func get_item_depth(item: TreeItem) -> int:
	var depth = 0
	var current = item.get_parent()
	while current != null:
		depth += 1
		current = current.get_parent()
	return depth
