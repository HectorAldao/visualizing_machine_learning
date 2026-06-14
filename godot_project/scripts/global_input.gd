extends Node

var scale_step: float = 0.1
var min_scale: float = 0.1
var max_scale: float = 3.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		_change_scale(scale_step)
	elif event.is_action_pressed("zoom_out"):
		_change_scale(-scale_step)

func _change_scale(amount: float) -> void:
	var root = get_tree().root
	var new_scale = clamp(root.content_scale_factor + amount, min_scale, max_scale)
	root.content_scale_factor = new_scale
