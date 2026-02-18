@tool
extends Theme

#@export var main_color_palette : ColorPalette = preload("res://colors/main_color_palette.tres"):
	#set(value):
		#main_color_palette = value
		#_update_theme()

#func _init() -> void:
	#_update_theme()
#
#func _update_theme() -> void:
	##if not main_color_palette:
		##return
	#
	##set_color("font_color", "Button", main_color_palette.colors[0])
	#set_color("font_color", "Button", Color.BLACK)
	#set_constant("separation", "VBoxContainer", 20)
	#
	## This notifies the editor to redraw the inspector and UI
	#emit_changed()
