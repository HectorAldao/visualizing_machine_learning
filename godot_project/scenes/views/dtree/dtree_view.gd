extends Control

@onready var scroll_container = $ScrollContainer
@export var scroll_speed = 30

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var delta = 0
		
		# Determine direction
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			delta = -scroll_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			delta = scroll_speed
			
		if delta != 0:
			# Check Shift for horizontal scrolling
			if event.shift_pressed:
				scroll_container.scroll_horizontal += delta
			else:
				scroll_container.scroll_vertical += delta
			
			# Optional
			get_viewport().set_input_as_handled()
