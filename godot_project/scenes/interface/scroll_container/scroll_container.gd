extends ScrollContainer


@export var scroll_speed: int = 30

var is_middle_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _input(event: InputEvent) -> void:
	# Handle mouse motion for middle mouse dragging
	if event is InputEventMouseMotion and is_middle_mouse_dragging:
		# The scroll aplied is going to be the dif frame to frame of
		# where the mause where and where the mouse is
		var delta_position = event.position - last_mouse_position

		# The diff is aplied
		scroll_horizontal -= int(delta_position.x)
		scroll_vertical -= int(delta_position.y)

		# The new position is saved and the input is set as handled
		last_mouse_position = event.position
		get_viewport().set_input_as_handled()
	
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
				if event.shift_pressed:
					scroll_horizontal += delta
				else:
					scroll_vertical += delta
				
				# Optional: do not pass the input to lower nodes
				get_viewport().set_input_as_handled()
