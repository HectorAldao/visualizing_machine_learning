extends Control


#@export var manual_dtree_button: Button
#@export var algorithmic_dtree_button: Button

const controller_dtree_scene: String = Constants.SCENES.controller_dtree


@onready var scroll_container_dtree: ScrollContainer =      %ScrollContainerDTree
# @onready var dtree_selection_panel : CenterContainer =      %DTreeSelectionPanel
@onready var dtree_menu:             Control =      %DTreeMenu
@onready var dtree:                  DTreeLogical =         %DTree
@onready var dtree_controller:       ControllerDTree =      %ControllerDTree
@onready var window:                 PanelContainer =       %Window
@onready var dataset_selection:      PanelContainer =       %PanelDatasetSelection

var algorithm:        AlgorithmDTree
var current_mode:     String = ""

# Zoom variables
#var zoom_level: float = 1.0
#var min_zoom:   float = 0.25
#var max_zoom:   float = 4.0
#var zoom_step:  float = 0.1



func _ready():
	
	# Connect the signals of the buttons to the respective mode of creation
	#manual_dtree_button.      pressed.connect(_on_manual_dtree_button_pressed)
	#algorithmic_dtree_button. pressed.connect(_on_algorithmic_dtree_button_pressed)
	
	# Make the ui elements invisible but the selecion panel
	# dtree_selection_panel. visible = true
	#scroll_container_dtree.visible = false
	dtree_menu.        visible = false
	window.                visible = false
	dataset_selection.     visible = false
	
	#window.position.x = 830
	#window.position.y = 150

	_on_algorithmic_dtree_button_pressed()

	#%MainMenuButton.pressed.connect(func(): dtree_menu.visible = not dtree_menu.visible)


func _on_manual_dtree_button_pressed():
	# Cange visibility
	# dtree_selection_panel. visible = false
	scroll_container_dtree.      visible = true
	dtree_menu.        visible = true

	# Set mode
	current_mode = "manual"
	
	# Set the mode on the tree
	dtree.set_mode("manual")
	
	# Create controller as child of this view
	dtree_controller.initialize(dtree, window, "manual", self)


func _on_algorithmic_dtree_button_pressed():
	# Cange visibility
	# dtree_selection_panel. visible = false
	dataset_selection.     visible = true
	#scroll_container_dtree.visible = false
	window.                visible = false
	
	
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

	await SignalsObserver.dataset_selected

	# Once the dataset is selected and training starts, show the tree and detail window
	scroll_container_dtree.visible = true
	window.visible = true
