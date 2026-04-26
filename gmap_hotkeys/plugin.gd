@tool
extends EditorPlugin

#EDIT after = in format of KEY_(name of key)
# List of valid keys linked in document: 
# https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enum-globalscope-key

var gmap_ctrl = KEY_CTRL #button that needs to be held along side other ones. 


var scene_tab = KEY_1
var inspector_tab = KEY_2
var file_tab = KEY_3
var bottom_panel_tab = KEY_4
var signals_tab = KEY_5
var menu_bar = KEY_6
var open_scene_tabs = KEY_7
var import_tab = KEY_8
var focus_method_list = KEY_9

#Goes to create script button, or script of focused scene
var find_script = KEY_EQUAL
#prints in output what is currently focused
var print_focus = KEY_0

var up_category = KEY_U
var up_parent_cooldown = false

var find_error = KEY_SEMICOLON
var open_node_search = KEY_T

var bus_forward_key = KEY_PERIOD
var bus_moved = false

var plugin

var all_nodes #used to find needed  nodes for hot keys

var inspector = EditorInterface.get_inspector()
var file_system = EditorInterface.get_file_system_dock()
var script_editor = EditorInterface.get_script_editor()
var editor_settings = EditorInterface.get_editor_settings()

const HBoxFocusFixer = preload("res://addons/gmap_hotkeys/focus fixer/h_box_focus_fixer.gd")
const VBoxFocusFixer = preload("res://addons/gmap_hotkeys/focus fixer/v_box_focus_fixer.gd")

var focus_remove_list = [] #array of nodes that we disable focus for

#playing error noises!
const GMAP_ALERT = preload("res://addons/gmap_hotkeys/gmap_alert.tscn")
const SUCCESSSFX = preload("res://addons/gmap_hotkeys/gmap_success.mp3")
const ALERTSFX = preload("res://addons/gmap_hotkeys/gmap_alert.wav")
var gmap_alert 
#used to track error bar popups during coding
var error_bar 
var error_bar_text = ""
var vis
#runtime error tracking
var error_runtime
var error_runtime_text =""

var debug_timer = 1000
var debug_var
var debug_array = []
var debug_array2 = []


@export var t:int
var check  = KEY_COMMA #used when testing
var focused:Control #any tasks that need to check focused item checks here to not repeat work.


	
func _enter_tree():
	gmap_alert = GMAP_ALERT.instantiate()
	add_child(gmap_alert)
	#adding custom nodes for containers that check their focus whenever updated
	add_custom_type("GmVBoxContainer", "VBoxContainer", preload("res://addons/gmap_hotkeys/focus fixer/gm_v_box_container.gd"), preload("icon.svg")) #adds GMAP to game
	add_custom_type("GmHBoxContainer", "HBoxContainer", preload("res://addons/gmap_hotkeys/focus fixer/gm_h_box_container.gd"), preload("icon.svg")) #adds GMAP to game
	
	focus_remover()
	
func _ready():
	replace_event("print_focus",print_focus)
	replace_event("find_script",find_script,true,true)
	#connecting signal to know when a new container enters
	get_tree().connect("node_added",add_container_reorg)
	add_container_reorg_all()

func walk_up_ui():
	if up_parent_cooldown == false:
		go_up_parent(focused)
		up_parent_cooldown = true
	else:
		up_parent_cooldown = false
		


func goto_method_list():
		var parent_node = get_parent().find_child("*ScriptEditor*",true,false)
		var list = parent_node.find_children("*LineEdit*","",true,false)
		
		for t in list:
			if t.placeholder_text == "Filter Methods":
				t.grab_focus()
				break

func _process(float):
	#checking what has focus 
	focused = get_viewport().gui_get_focus_owner()
	
	bus_changer()
	
	tree_focus_locked()
	
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	# bus_moved reset — equivalent to the !is_key_pressed check in _process
	if event.keycode != bus_forward_key:
		bus_moved = false

	var ctrl := Input.is_key_pressed(gmap_ctrl)

	# 1 — Scene Tree
	if event.keycode == scene_tab and ctrl:
		goto_scene_tree()

	# 2 — Inspector
	elif event.keycode == inspector_tab and ctrl:
		goto_inspector()

	# 3 — FileSystem
	elif event.keycode == file_tab and ctrl:
		goto_file_system()

	# 4 — Output (bottom panel)
	elif event.keycode == bottom_panel_tab and ctrl:
		goto_output()

	# 5 — Signals tab
	elif event.keycode == signals_tab and ctrl:
		goto_signals()

	# 6 — Menu bar 
	elif event.keycode == menu_bar and ctrl:
		goto_main_menu_bar()

	# 7 — Open scene tabs
	elif event.keycode == open_scene_tabs and ctrl:
		goto_open_scene_tabs()

	# 8 — Import tab
	elif event.keycode == import_tab and ctrl:
		goto_import_tab()

	# 9 — Method list
	elif event.keycode == focus_method_list and ctrl:
		goto_method_list()

	# Ctrl+U — Walk up inspector UI tree
	elif event.keycode == up_category and ctrl:
		walk_up_ui()

	# Find script of selected node
	elif event.is_action("find_script") and ctrl:
		goto_script_of_selected_scene()

	# Focus check ctrl +0
	elif event.is_action("print_focus") and ctrl:
		focus_checking()

	# Bus forward (ctrl + period by default)
	elif event.keycode == bus_forward_key and ctrl and not bus_moved:
		bus_forward()

#1
func goto_scene_tree():
	var scene_tree_editor = get_parent().find_child("@SceneTreeEditor*",true,false)
	var scene_tab_container = scene_tree_editor.get_parent().get_parent().get_parent().get_parent()
	for i in range(scene_tab_container.get_tab_count()):
		if scene_tab_container.get_tab_title(i) == "Scene":
			scene_tab_container.current_tab = i
			break
	var st_trees = scene_tree_editor.find_children("*", "Tree", true, false)
	if st_trees.size() > 0:
		st_trees[0].grab_focus()
	elif not _focus_first_in(scene_tab_container.get_current_tab_control()):
		scene_tab_container.get_tab_bar().grab_focus()
#2
func goto_inspector():
		var inspector_grandparent = inspector.get_parent().get_parent().get_parent().get_parent()
		for i in range(inspector_grandparent.get_tab_count()):
			if inspector_grandparent.get_tab_title(i) == "Inspector":
				inspector_grandparent.current_tab = i
				break
		if not _focus_first_in(inspector):
			inspector_grandparent.get_tab_bar().grab_focus()
			
#3
func goto_file_system():
	var file_system_parent = file_system.get_parent()
	for i in range(file_system_parent.get_tab_count()):
		if file_system_parent.get_tab_title(i) == "FileSystem":
			file_system_parent.current_tab = i
			break
	var fs_trees = file_system.find_children("*", "Tree", true, false)
	if fs_trees.size() > 0:
		fs_trees[0].grab_focus()
	elif not _focus_first_in(file_system):
		file_system_parent.get_tab_bar().grab_focus()

#4
func goto_output():
	var bottom = EditorInterface.get_base_control().find_children("*", "EditorBottomPanel", true, false)
	if bottom.is_empty():
		return
	var list = bottom[0].get_children()
	# EditorBottomPanel is itself a TabContainer now - just set the tab directly
	if bottom[0] is TabContainer:
		bottom[0].current_tab = 0
		var bottom_tabs:TabContainer = bottom[0]
		var bar = bottom_tabs.get_tab_bar()
		bar.grab_focus()

#5 by default, goes to signals tab that is right of inspector in right most container.
func goto_signals():
		var inspector_grandparent = inspector.get_parent().get_parent().get_parent().get_parent()
		for i in range(inspector_grandparent.get_tab_count()):
			if inspector_grandparent.get_tab_title(i) == "Signals":
				inspector_grandparent.current_tab = i
				break
		if not _focus_first_in(inspector):
			inspector_grandparent.get_tab_bar().grab_focus()

#6
func goto_main_menu_bar():
	var parent_node = get_parent().find_child("*EditorTitleBar*",true,false)
	parent_node.get_child(0).grab_focus()

#7
func goto_open_scene_tabs():
	var parent_node = get_parent().find_child("*EditorSceneTabs*",true,false)
	var tab_bar = parent_node.find_child("*TabBar*",true,false)
	tab_bar.grab_focus()

#8
func goto_import_tab():
		var scene_tree_import = get_parent().find_child("@SceneTreeEditor*",true,false)
		var scene_tab_container_import = scene_tree_import.get_parent().get_parent().get_parent().get_parent()
		for i in range(scene_tab_container_import.get_tab_count()):
			if scene_tab_container_import.get_tab_title(i) == "Import":
				scene_tab_container_import.current_tab = i
				break
		if not _focus_first_in(scene_tab_container_import.get_current_tab_control()):
			scene_tab_container_import.get_tab_bar().grab_focus()

func _focus_first_in(control: Control) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	if control.focus_mode == Control.FOCUS_ALL:
		control.grab_focus()
		return true
	for child in control.get_children():
		if child is Control:
			if _focus_first_in(child):
				return true
	return false

func goto_script_of_selected_scene():
	var picked_node = get_editor_interface().get_selection().get_selected_nodes()[0]
	if picked_node.get_script():
		get_editor_interface().edit_script(picked_node.get_script())
	else:
		var scene_tree = get_parent().find_child("@SceneTreeEditor*",true,false)
		var scene_tab = (scene_tree.get_parent().get_parent().get_parent())
		var scene_bar = scene_tab.get_child(0)
		var button = scene_bar.get_child(0)
		if button.visible == true:
			button.get_child(3).grab_focus()
		
func bus_changer():#makes volume slider accessible and add effect menu selectable
	if focused != null:
		if focused.get_class() == 'VSlider':
			var slide : VSlider = focused
			if slide.get_parent().get_parent().get_parent().get_class() == 'EditorAudioBus':
				slide.step = .1
				slide.accessibility_name = slide.tooltip_text
		if focused.get_class() == 'Tree':
			if focused.get_parent().get_parent().get_class() == 'EditorAudioBus':
				var tree_menu : Tree = focused
				enable_all_tree_items_selectable(tree_menu)

func enable_all_tree_items_selectable(tree: Tree) -> void:
	var root := tree.get_root()
	if root == null:
		return
	_enable_item_recursive(root, tree.columns)
func _enable_item_recursive(item: TreeItem, column_count: int) -> void:
	for c in column_count:
		item.set_selectable(c, true)

	var child := item.get_first_child()
	while child:
		_enable_item_recursive(child, column_count)
		child = child.get_next()
	
func bus_forward(): #moving the bus in audio tab forward one, or to start of line.
	if focused.get_class() == 'EditorAudioBus' and focused.get_index() !=0:#making sure audiobus has focus and it's not master.
		bus_moved = true
		if focused.get_index()+1 == focused.get_parent().get_child_count():#if last item, move to just after master.
			print("set to 1")
			focused.get_parent().move_child(focused,1)
		else: #If not the last item, move it forward one.
			print("moved forward")
			focused.get_parent().move_child(focused,focused.get_index()+1)

#When focus goes to tree, sets it to mode where focus and selected are the same, and sets top item selected if none selected
func tree_focus_locked():
	if focused == null:
		return
	if focused.get_class() == "Tree":
		focused.set_select_mode(0)
		if focused.get_root() and focused.get_selected() == null:
			focused.set_selected(focused.get_root(),0)
	pass

#going through and fixing focus for different container types
func add_container_reorg_all():
	find_container(get_node("/root"),"HBoxContainer",HBoxFocusFixer)
	find_container(get_node("/root"),"VBoxContainer",VBoxFocusFixer)
	
#VBoxFocusFixer
func add_container_reorg(node):
	if node == null:
		return
	
	if node.get_class() == "HBoxContainer" and node.get_script() == null and "@" in node.name:
		node.set_script(HBoxFocusFixer)
		node.attach()
		
	elif node.get_class() == "VBoxContainer" and node.get_script() == null and "@" in node.name:
		node.set_script(VBoxFocusFixer)
		node.attach()
	#disabling focus for nodes we don't like
	if node.get_class() in focus_remove_list and node.focus_mode != 1 and node.focus_mode != 0:
		node.focus_mode = 1
	elif node is BaseButton:
		if node is TextureButton:
			if node.accessibility_description == "":
				node.accessibility_description = node.tooltip_text
		elif node.text == "" and node.accessibility_description == "":
			node.accessibility_description =  node.tooltip_text
			
func find_container(parent: Node,type,script) -> Array:
	var windows = []
	for child in parent.get_children():
		if child.get_class() == type:
			#if previously added for some reason, script
			if child.get_script() == null:
				child.set_script(script)
				child.attach()
				
			windows.append(child)
		if child.get_children():
			windows += find_container(child,type,script)
	return windows

func _exit_tree():
	remove_inspector_plugin(plugin)

func error_runtime_check():
	if error_runtime.text != error_runtime_text:
		error_runtime_text = error_runtime.text
		if error_runtime.text != "" and error_runtime.text != "Debug session closed."and error_runtime.text != "Debug session started.":
			gmap_alert.stream = ALERTSFX
			gmap_alert.play()
			
func focus_remover():
	#disabling 2d canvas editor
	for t in EditorInterface.get_editor_main_screen().find_children("*CanvasItemEditorViewport*","",true,false):
		t.visible =false
	focus_remove_list = ["SplitContainerDragger","CanvasItemEditorViewport","VScrollBar","HScrollBar"]
	var root = get_node("/root")
	#some nodes can have focus that we can not want to ever have focus via keyboard
	var draggers = root.find_children("*SplitContainerDragger*","",true,false)
	for f in draggers:
		f.focus_mode =1
		
	var viewer2d = root.find_children("*CanvasItemEditorViewport*","",true,false)
	for i in viewer2d:
		i.focus_mode = 1
		
	var vscrolls = root.find_children("*VScrollBar*","",true,false)
	for i in vscrolls:
		i.focus_mode = 1
		
	var vscrolls2 = root.find_children("_v_scroll","",true,false)
	for i in vscrolls2:
		i.focus_mode = 1
		
	var hscrolls = root.find_children("*HScrollBar*","",true,false)
	for i in hscrolls:
		i.focus_mode = 1

func error_line():
#below the text editor there is a little line that will display syntax error messages.
#This code finds where that is. 
	if error_bar:
		if vis.visible == true:
			if error_bar_text != error_bar.text:
				error_bar_text = error_bar.text
				if error_bar.text != "":
					gmap_alert.stream = ALERTSFX
					gmap_alert.play()
				elif error_bar.text == "":
					gmap_alert.stream = SUCCESSSFX
					gmap_alert.play()
		else:
			error_bar = null
	else:
		#making the error bar assertive, and getting it stored so can beep if found.
		#Has to wait until certain assets are loaded to find. Giant pain, but why it's in a loop like this.
		var chk
		var chk2
		chk2 = script_editor.get_current_editor()
		vis = chk2
		if chk2:
			chk2 = chk2.find_child("*VSplitContainer*",true,false)
			if chk2 == null:
				return
			
			chk2 = chk2.find_child("*CodeTextEditor*",true,false)
			chk2 = chk2.find_child("*HBoxContainer*",true,false)
			chk2 = chk2.find_child("*ScrollContainer*",true,false)
			error_bar = chk2.get_child(0)
			error_bar.accessibility_live = DisplayServer.LIVE_ASSERTIVE

func replace_event(event_name:String,new_key,control = false, shift = false):
	#input key class being assigned the key
	var e1 = InputEventKey.new()
	e1.physical_keycode = new_key
	e1.ctrl_pressed = control
	e1.shift_pressed = shift
	
	if InputMap.has_action(event_name):
		InputMap.erase_action(event_name)
	InputMap.add_action(event_name)
	InputMap.action_add_event(event_name, e1)
	
func go_up_parent(f):
	var parent = f.get_parent()
	var c = 0
	while parent.get_child(c) and parent.get_child(c) is not Control and (parent.get_child(c).focus_mode == 0 or  parent.get_child(c).focus_mode == 1):
		c+=1
	if focused == parent.get_child(c):
		go_up_parent(parent)
	else:
		parent.get_child(c).grab_focus()



func focus_checking():
	print("Parent of focused node: ")
	print(focused.get_parent())
	print("Focused:")
	print(focused)
	print("Children of focused node: ")
	print(focused.get_children())
