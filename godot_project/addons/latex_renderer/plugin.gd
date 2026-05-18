@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"LatexRenderer",
		"TextureRect",
		preload("res://addons/latex_renderer/latex_renderer.gd"),
		null
	)


func _exit_tree() -> void:
	remove_custom_type("LatexRenderer")
