extends Control


@export var scroll_speed: int = 30

@export var manual_dtree_button: Button
@export var algorithmic_dtree_button: Button

@export_file("*.tscn") var controller_dtree_scene: String


@onready var scroll_container:      ScrollContainer = $ScrollContainer
@onready var dtree_selection_panel: CenterContainer = $DTreeSelectionPanel
@onready var subviewport_container: SubViewportContainer = $ScrollContainer/SubViewportContainer
@onready var subviewport:           SubViewport = $ScrollContainer/SubViewportContainer/SubViewport
@onready var dtree:                 DTreeLogical = $ScrollContainer/SubViewportContainer/SubViewport/DTree
@onready var dtree_menu:            Control = $DTreeMenu

var dtree_controller: Node = null
var algorithm: AlgorithmDTree = null
var current_mode: String = ""

var is_middle_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

# Zoom variables
var zoom_level: float = 1.0
var min_zoom: float = 0.25
var max_zoom: float = 4.0
var zoom_step: float = 0.1



func _ready():
	
	# Connect the signals of the buttons to the respective mode of creation
	manual_dtree_button.      pressed.connect(_on_manual_dtree_button_pressed)
	algorithmic_dtree_button. pressed.connect(_on_algorithmic_dtree_button_pressed)
	
	# Make the ui elements invisible but the selecion panel
	dtree_selection_panel. visible = true
	scroll_container.      visible = false
	dtree_menu.            visible = false
	
	# Configure SubViewport
	subviewport.transparent_bg = true
	subviewport.size = scroll_container.size
	
	# Connect resize signal to update SubViewport size
	scroll_container.resized.connect(_on_scroll_container_resized)


func _on_scroll_container_resized():
	# Update SubViewport size when ScrollContainer is resized
	if subviewport:
		subviewport.size = scroll_container.size / zoom_level
	

func _on_manual_dtree_button_pressed():
	# Cange visibility
	dtree_selection_panel. visible = false
	scroll_container.      visible = true
	dtree_menu.            visible = true

	# Set mode
	current_mode = "manual"
	
	# Set the mode on the tree
	dtree.set_mode("manual")
	
	# Create controller as child of this view
	dtree_controller = load(controller_dtree_scene).instantiate()
	add_child(dtree_controller)
	dtree_controller.initialize(dtree, dtree, "manual", self)


func _on_algorithmic_dtree_button_pressed():
	# Cange visibility
	dtree_selection_panel. visible = false
	scroll_container.      visible = true

	# Set mode
	current_mode = "automatic"
	
	# Set the mode on the tree
	dtree.set_mode("automatic")
	
	# Create algorithm as child of this view
	algorithm = AlgorithmDTree.new()
	add_child(algorithm)
	
	# Create controller as child of this view
	dtree_controller = load(controller_dtree_scene).instantiate()
	add_child(dtree_controller)
	dtree_controller.algorithm = algorithm
	dtree_controller.initialize(dtree, dtree, "automatic", self)


func _input(event):
	# Handle mouse motion for middle mouse dragging
	if event is InputEventMouseMotion and is_middle_mouse_dragging:
		var delta_position = event.position - last_mouse_position
		scroll_container.scroll_horizontal -= int(delta_position.x)
		scroll_container.scroll_vertical -= int(delta_position.y)
		last_mouse_position = event.position
		get_viewport().set_input_as_handled()
	
	# If there is a mouse event
	if event is InputEventMouseButton:
		# Handle middle mouse button drag
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				# Start dragging
				is_middle_mouse_dragging = true
				last_mouse_position = event.position
			else:
				# Stop dragging
				is_middle_mouse_dragging = false
			get_viewport().set_input_as_handled()
		
		# Handle zoom with Ctrl+Wheel
		elif event.pressed and event.ctrl_pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var zoom_delta = zoom_step if event.button_index == MOUSE_BUTTON_WHEEL_UP else -zoom_step
			var new_zoom = clamp(zoom_level + zoom_delta, min_zoom, max_zoom)
			
			# Apply the new zoom
			zoom_level = new_zoom
			subviewport_container.scale = Vector2(zoom_level, zoom_level)
			subviewport.size = scroll_container.size / zoom_level
			
			get_viewport().set_input_as_handled()
		
		# Handle mouse wheel scrolling (only if Ctrl is NOT pressed)
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
