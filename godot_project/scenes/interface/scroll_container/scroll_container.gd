class_name ScrollContainerV2 extends ScrollContainer


@export var is_horizontal: bool = false
@export var scroll_speed: int = 30
@export_range(0.1, 1) var zoom_speed: float = 0.1
@export var max_zoom: float = 3.
@export var min_zoom: float = 0.1
@export var touch_drag_deadzone: float = 5.0
@export var fallback_scroll_container: ScrollContainerV2

var is_middle_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var touch_positions: Dictionary = {}
var is_touch_dragging: bool = false
var touch_drag_start_position: Vector2 = Vector2.ZERO
var last_touch_position: Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events = true


func _gui_input(event: InputEvent) -> void:
	# Handle mouse motion for middle mouse dragging
	if event is InputEventMouseMotion and is_middle_mouse_dragging:
		# The scroll aplied is going to be the dif frame to frame of
		# where the mause where and where the mouse is
		var delta_position = event.position - last_mouse_position

		var did_scroll = try_drag_scroll(delta_position)

		# The new position is saved and the input is set as handled
		last_mouse_position = event.position
		if did_scroll:
			accept_event()

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

			accept_event()

		# Zoom
		elif event.pressed and event.ctrl_pressed:
			# Save the diference frame to frame
			var delta: float = 0.0
			
			# Determine direction
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				delta = zoom_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				delta = -zoom_speed

			# Apply zoom
			if delta != 0:
				_apply_zoom_delta(delta)
				accept_event()
		
		# Move scroll container view
		elif event.pressed and not event.ctrl_pressed:
			# Save the diference frame to frame
			var delta: int = 0
			
			# Determine direction
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				delta = -scroll_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				delta = scroll_speed
				
			# Apply scroll
			if delta != 0:
				var did_scroll = try_scroll(delta, event.shift_pressed)

				if did_scroll:
					accept_event()


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_positions[event.index] = event.position

		# One finger
		if touch_positions.size() == 1:
			is_touch_dragging = false
			touch_drag_start_position = event.position
			last_touch_position = event.position

		return

	var was_touch_gesture = is_touch_dragging or touch_positions.size() >= 2
	touch_positions.erase(event.index)
	is_touch_dragging = false

	if touch_positions.size() == 1:
		var remaining_position = _get_single_touch_position()
		touch_drag_start_position = remaining_position
		last_touch_position = remaining_position

	if was_touch_gesture:
		accept_event()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	touch_positions[event.index] = event.position

	if touch_positions.size() == 1:
		if not is_touch_dragging:
			if event.position.distance_to(touch_drag_start_position) < touch_drag_deadzone:
				return

			is_touch_dragging = true
			var delta_position = event.position - last_touch_position
			var did_scroll = try_drag_scroll(delta_position)
			last_touch_position = event.position
			if did_scroll:
				accept_event()
			return

		var delta_position = event.position - last_touch_position
		var did_scroll = try_drag_scroll(delta_position)
		last_touch_position = event.position
		if did_scroll:
			accept_event()
		return

func try_drag_scroll(delta_position: Vector2) -> bool:
	return _try_drag_scroll(delta_position, [])


func _try_drag_scroll(delta_position: Vector2, visited_scroll_containers: Array) -> bool:
	if self in visited_scroll_containers:
		return false

	visited_scroll_containers.append(self)

	var previous_horizontal = scroll_horizontal
	var previous_vertical = scroll_vertical

	# The diff is aplied
	scroll_horizontal -= int(delta_position.x)
	scroll_vertical -= int(delta_position.y)

	var did_scroll = scroll_horizontal != previous_horizontal or scroll_vertical != previous_vertical
	if not did_scroll:
		var fallback = _get_fallback_scroll_container()
		if fallback != null:
			did_scroll = fallback._try_drag_scroll(delta_position, visited_scroll_containers)

	return did_scroll


func try_scroll(delta: int, shift_pressed: bool) -> bool:
	return _try_scroll(delta, shift_pressed, [])


func _try_scroll(delta: int, shift_pressed: bool, visited_scroll_containers: Array) -> bool:
	if self in visited_scroll_containers:
		return false

	visited_scroll_containers.append(self)

	var previous_horizontal = scroll_horizontal
	var previous_vertical = scroll_vertical

	if is_horizontal:
		if shift_pressed:
			scroll_vertical += delta
		else:
			scroll_horizontal += delta
	else:
		if shift_pressed:
			scroll_horizontal += delta
		else:
			scroll_vertical += delta

	var did_scroll = scroll_horizontal != previous_horizontal or scroll_vertical != previous_vertical
	if not did_scroll:
		var fallback = _get_fallback_scroll_container()
		if fallback != null:
			did_scroll = fallback._try_scroll(delta, shift_pressed, visited_scroll_containers)

	return did_scroll


func _get_fallback_scroll_container() -> ScrollContainerV2:
	if fallback_scroll_container != null:
		return fallback_scroll_container

	var parent = get_parent()
	while parent != null:
		if parent is ScrollContainerV2:
			return parent

		parent = parent.get_parent()

	return null


func _apply_zoom_delta(delta: float) -> void:
	get_tree().root.content_scale_factor = clamp(
		get_tree().root.content_scale_factor + delta,
		min_zoom,
		max_zoom
	)


func _get_single_touch_position() -> Vector2:
	var touch_indices = touch_positions.keys()
	return touch_positions[touch_indices[0]]
