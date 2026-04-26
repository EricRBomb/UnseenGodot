@tool
extends EditorPlugin

var known_nodes = [null]
var names = []
var selection = EditorInterface.get_selection()
#Storing step by step tutorial steps
var log_path = "res://Addons/StepLogger/PrettyLog.txt"
var file
#Storing all input into godot UI, and whenever focus changes
var raw_path = "res://Addons/StepLogger/RawLog.txt"
var raw_file #used as open file object
#If tutorial loggis is on. raw logging is always on if addon is on.
var logging = false
#Only log something if it's a unique message
var previous_text = ""
#only update when focus change relevant
var current_focus = ""
#only say to go to inspector when going for first time
var inspector_target = ""
#Tracks if was just created to skip focus message
var new_node = false
var last_focus


#enables with ctrl-d 
func _enter_tree():
	var t = EditorInterface.get_inspector()
	# Track the scene when first loaded
	connect("scene_changed",_scene_changed)
	selection.connect("selection_changed",_selection_changed)
	t.connect("property_edited",_property_edited)
	var sc = EditorInterface.get_script_editor()
	sc.connect("editor_script_changed",_editor_script_changed)
	connect("resource_saved",_resource_saved)
	
	raw_file = FileAccess.open(raw_path, FileAccess.WRITE_READ)
	raw_file.seek_end() # move to end for appending

func _scene_changed(scene):
	if scene:
		save_to_log("Change scence to "  + scene.name +" Ctrl+shift+o opens scene selector")
		
		known_nodes = gather_children(scene,[])
		for k in known_nodes:
			attach_signals(k)

func gather_children(node,arr):
	arr += [node]
	for ch in node.get_children():
		arr = gather_children(ch,arr)
	return arr
		
func _process(_delta):
	if Input.is_action_just_pressed("ui_graph_duplicate"):
		if logging == false:
			logging = true
			print("enabled")
		else:
			logging = false
			print("disabled")
	var node = EditorInterface.get_edited_scene_root()
	
	if node:
		#confirming we didn't miss a switch
		if known_nodes[0] == node:
			var temp = gather_children(node,[])
			#checking if something changed
			if known_nodes != temp:
				for n in temp:
					if n not in known_nodes:
						attach_signals(n)
						new_node = true
						save_to_log("Add node " + n.name + " as child of "+ n.get_parent().name+"("+n.get_parent().get_class()+" Node) CTRL+A to open node create menu.")
				known_nodes = temp
		else:
			save_to_log("Create a new scene. CTRL+N, CTRL+A, then select: " + node.name)
			known_nodes = gather_children(node,[])
			for k in known_nodes:
				attach_signals(k)
				pass


func attach_signals(node):
	node.connect("renamed", func(): _renamed(node))
	node.connect("script_changed", func(): _script_changed(node))
	#node.connect("property_list_changed", func(): _propery_list_changed(node))
	#node.connect("editor_state_changed", func(): _editor_state_changed(node))

func _script_changed(node):
	save_to_log("Attach a script to " +node.name + "(CTRL+Equal Sign) ")

func _renamed(new_name):
	save_to_log("Press enter on "+new_name.get_class()+ " and rename it to " +new_name.name + ".")

func _selection_changed():
	if selection.get_selected_nodes():
		if new_node == false:
			save_to_log("Set focus to "+ selection.get_selected_nodes()[0].name + " in scene tab (CTRL+1).")
		else:
			new_node = false

func _property_edited(passed):
	var t = EditorInterface.get_inspector()
	var o = t.get_edited_object()
	if inspector_target != o.name:
		inspector_target = o.name 
		save_to_log("Go to inspector, ctrl+2 to get to inspector tab, ctrl+U to inspector categories.")
	save_to_log("Property "+str(passed)+" set to " + str(o.get(passed)) )
	

func _editor_script_changed(sc): 
	if sc:
		pass
	
#saving a copy of the script for reference 
func _resource_saved(passed):  
	if logging == true:
		var passed_path = passed.get_path()
		var time =str(Time.get_unix_time_from_system())
		save_to_log("Updated: " + passed_path +" "+ time)
		if ".gd" in passed_path:
			var script = FileAccess.open(passed_path, FileAccess.READ)
			if script:
				var script_content = script.get_as_text()
				var saved_script = FileAccess.open("res://Addons/tutoriallogging/saved_scripts/script"+ time +".txt", FileAccess.WRITE)
				saved_script.store_string(script_content)


func save_to_log(txt):
	if logging == true and txt != previous_text:
		previous_text = txt 
		file = FileAccess.open(log_path, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
			print(txt)
			file.store_line(txt)
			file.close()
			

func _input(event):
	if event is InputEventKey and event.pressed:
		var key_name = OS.get_keycode_string(event.keycode)
		var timestamp = Time.get_datetime_string_from_system()
		var focused = get_viewport().gui_get_focus_owner()
		var line =""
		if focused != last_focus:
			last_focus = focused
			line = focused.name + ":"
			
		line += "%s - %s\n" % [timestamp, key_name]

		raw_file.store_string(line)
		raw_file.flush() # ensure it's written immediately
