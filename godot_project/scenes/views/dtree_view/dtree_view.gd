extends Control




@export var manual_dtree_button: Button
@export var algorithmic_dtree_button: Button

const controller_dtree_scene: String = Constants.SCENES.controller_dtree


@onready var scroll_container:      ScrollContainer =      $ScrollContainer
@onready var dtree_selection_panel: CenterContainer =      $DTreeSelectionPanel
@onready var dtree_alg_menu:        Control =              $DTreeMenu
@onready var dtree:                 DTreeLogical =         $ScrollContainer/DTree
@onready var dtree_controller:      ControllerDTree =      $ControllerDTree
@onready var window:                Window =               $Window

var algorithm:        AlgorithmDTree
var current_mode:     String = ""

# Scroll variables
var is_middle_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
@export var scroll_speed: int = 30

# Zoom variables
#var zoom_level: float = 1.0
#var min_zoom:   float = 0.25
#var max_zoom:   float = 4.0
#var zoom_step:  float = 0.1



func _ready():
	
	# Connect the signals of the buttons to the respective mode of creation
	manual_dtree_button.      pressed.connect(_on_manual_dtree_button_pressed)
	algorithmic_dtree_button. pressed.connect(_on_algorithmic_dtree_button_pressed)
	
	# Make the ui elements invisible but the selecion panel
	dtree_selection_panel. visible = true
	scroll_container.      visible = false
	dtree_alg_menu.        visible = false
	window.                visible = false
	
	window.position.x = 20
	window.position.y = 150
	


func _on_manual_dtree_button_pressed():
	# Cange visibility
	dtree_selection_panel. visible = false
	scroll_container.      visible = true
	dtree_alg_menu.        visible = true

	# Set mode
	current_mode = "manual"
	
	# Set the mode on the tree
	dtree.set_mode("manual")
	
	# Create controller as child of this view
	dtree_controller.initialize(dtree, window, "manual", self)


func _on_algorithmic_dtree_button_pressed():
	# Cange visibility
	dtree_selection_panel. visible = false
	scroll_container.      visible = true
	window.                visible = true

	# Set mode
	current_mode = "automatic"
	
	# Set the mode on the tree
	dtree.set_mode("automatic")
	
	# Create algorithm as child of this view
	algorithm = AlgorithmDTree.new()
	add_child(algorithm)
	
	# Create controller as child of this view
	dtree_controller.algorithm = algorithm
	dtree_controller.initialize(dtree, window, "automatic", self)


# How to move the ScrollContainer
func _input(event):
	# Handle mouse motion for middle mouse dragging
	if event is InputEventMouseMotion and is_middle_mouse_dragging:
		# The scroll aplied is going to be the dif frame to frame of
		# where the mause where and where the mouse is
		var delta_position = event.position - last_mouse_position

		# The diff is aplied
		scroll_container.scroll_horizontal -= int(delta_position.x)
		scroll_container.scroll_vertical -= int(delta_position.y)

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
					scroll_container.scroll_horizontal += delta
				else:
					scroll_container.scroll_vertical += delta
				
				# Optional: do not pass the input to lower nodes
				get_viewport().set_input_as_handled()
