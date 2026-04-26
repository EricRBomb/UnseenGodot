@tool
extends EditorPlugin


func _enable_plugin():
	add_autoload_singleton("GM", "res://addons/UnseenFunctions/assists/gmap_funcs.gd")
	
func _disable_plugin():
	remove_autoload_singleton("GM")
