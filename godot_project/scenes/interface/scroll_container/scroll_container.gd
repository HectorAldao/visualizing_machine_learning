class_name ScrollContainerV2 extends ScrollContainer


@export var is_horizontal: bool = false
@export var scroll_speed: int = 30
@export_range(0.1, 1) var zoom_speed: float = 0.2
@export var max_zoom: float = 3.
@export var min_zoom: float = 0.1
@export var touch_drag_deadzone: float = 12.0
@export var pinch_zoom_pixels_per_step: float = 100.0

var is_middle_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var touch_positions: Dictionary = {}
var is_touch_dragging: bool = false
var touch_drag_start_position: Vector2 = Vector2.ZERO
var last_touch_position: Vector2 = Vector2.ZERO
var last_pinch_distance: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _input(event: InputEvent) -> void:
	# Handle mouse motion for middle mouse dragging
	if event is InputEventMouseMotion and is_middle_mouse_dragging:
		# The scroll aplied is going to be the dif frame to frame of
		# where the mause where and where the mouse is
		var delta_position = event.position - last_mouse_position

		_apply_drag_scroll(delta_position)

		# The new position is saved and the input is set as handled
		last_mouse_position = event.position
		get_viewport().set_input_as_handled()

	if event is InputEventScreenTouch:
		_handle_screen_touch(event)

	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
	
	# If there is a mouse event
	if event is InputEventMouseButton:
		# Move the view with middle mouse
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_middle_mouse_dragging = true
				last_mouse_position = event.position
			else:
				is_middle_mouse_dragging = false

			get_viewport().set_input_as_handled()

		# Zoom
		elif event.pressed and event.ctrl_pressed:
			# Save the diference frame to frame
			var delta = 0
			
			# Determine direction
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				delta = zoom_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				delta = -zoom_speed

			# Apply zoom
			if delta != 0:
				_apply_zoom_delta(delta)
		
		# Move scroll container view
		elif event.pressed and not event.ctrl_pressed:
			# Save the diference frame to frame
			var delta = 0
			
			# Determine direction
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				delta = -scroll_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				delta = scroll_speed
				
			# Apply scroll
			if delta != 0:
				# Check Shift for horizontal scrolling
				if is_horizontal:
					if event.shift_pressed:
						scroll_vertical += delta
					else:
						scroll_horizontal += delta
				else:
					if event.shift_pressed:
						scroll_horizontal += delta
					else:
						scroll_vertical += delta
				
				# Optional: do not pass the input to lower nodes
				get_viewport().set_input_as_handled()


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_positions[event.index] = event.position

		# One finger
		if touch_positions.size() == 1:
			is_touch_dragging = false
			touch_drag_start_position = event.position
			last_touch_position = event.position

		# Two fingers
		elif touch_positions.size() == 2:
			is_touch_dragging = false
			last_pinch_distance = _get_pinch_distance()
			get_viewport().set_input_as_handled()

		return

	var was_touch_gesture = is_touch_dragging or touch_positions.size() >= 2
	touch_positions.erase(event.index)
	last_pinch_distance = 0.0
	is_touch_dragging = false

	if touch_positions.size() == 1:
		var remaining_position = _get_single_touch_position()
		touch_drag_start_position = remaining_position
		last_touch_position = remaining_position

	if was_touch_gesture:
		get_viewport().set_input_as_handled()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	touch_positions[event.index] = event.position

	if touch_positions.size() == 1:
		if not is_touch_dragging:
			if event.position.distance_to(touch_drag_start_position) < touch_drag_deadzone:
				return

			is_touch_dragging = true
			last_touch_position = event.position
			get_viewport().set_input_as_handled()
			return

		var delta_position = event.position - last_touch_position
		_apply_drag_scroll(delta_position)
		last_touch_position = event.position
		get_viewport().set_input_as_handled()
		return

	if touch_positions.size() == 2:
		var current_pinch_distance = _get_pinch_distance()

		if last_pinch_distance > 0.0 and pinch_zoom_pixels_per_step > 0.0:
			var delta = ((current_pinch_distance - last_pinch_distance) / pinch_zoom_pixels_per_step) * zoom_speed
			_apply_zoom_delta(delta)

		last_pinch_distance = current_pinch_distance
		get_viewport().set_input_as_handled()


func _apply_drag_scroll(delta_position: Vector2) -> void:
	# The diff is aplied
	scroll_horizontal -= int(delta_position.x)
	scroll_vertical -= int(delta_position.y)


func _apply_zoom_delta(delta: float) -> void:
	get_tree().root.content_scale_factor = clamp(
		get_tree().root.content_scale_factor + delta,
		min_zoom,
		max_zoom
	)


func _get_pinch_distance() -> float:
	var touch_indices = touch_positions.keys()
	var first_position: Vector2 = touch_positions[touch_indices[0]]
	var second_position: Vector2 = touch_positions[touch_indices[1]]
	return first_position.distance_to(second_position)


func _get_single_touch_position() -> Vector2:
	var touch_indices = touch_positions.keys()
	return touch_positions[touch_indices[0]]
