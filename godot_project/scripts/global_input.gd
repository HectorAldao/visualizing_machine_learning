extends Node

var scale_step: float = 0.1
var min_scale: float = 0.1
var max_scale: float = 3.0
var pinch_pixels_per_step: float = 100.0
var touch_positions: Dictionary = {}
var last_pinch_distance: float = 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		_change_scale(scale_step)
	elif event.is_action_pressed("zoom_out"):
		_change_scale(-scale_step)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_positions[event.index] = event.position

		if touch_positions.size() == 2:
			last_pinch_distance = _get_pinch_distance()
		elif touch_positions.size() > 2:
			last_pinch_distance = 0.0

		return

	touch_positions.erase(event.index)

	if touch_positions.size() == 2:
		last_pinch_distance = _get_pinch_distance()
	else:
		last_pinch_distance = 0.0


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	touch_positions[event.index] = event.position

	if touch_positions.size() == 2:
		var current_pinch_distance = _get_pinch_distance()

		if last_pinch_distance > 0.0 and pinch_pixels_per_step > 0.0:
			var delta = ((current_pinch_distance - last_pinch_distance) / pinch_pixels_per_step) * scale_step
			_change_scale(delta)

		last_pinch_distance = current_pinch_distance
	elif touch_positions.size() > 2:
		last_pinch_distance = 0.0


func _change_scale(amount: float) -> void:
	var root = get_tree().root
	var new_scale = clamp(root.content_scale_factor + amount, min_scale, max_scale)
	root.content_scale_factor = new_scale


func _get_pinch_distance() -> float:
	var touch_indices = touch_positions.keys()
	var first_position: Vector2 = touch_positions[touch_indices[0]]
	var second_position: Vector2 = touch_positions[touch_indices[1]]
	return first_position.distance_to(second_position)
