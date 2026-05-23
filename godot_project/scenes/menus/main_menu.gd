extends Control


# For the menu
@export var max_width: float = 700.0
@export var horizontal_margin: float = 0

@onready var dtree_button: Button = %DTreeButton
@onready var nn_button: Button = %NeuralNetworkButton
@onready var start_button: Button = %StartButton

@onready var title_label: Label = %TitleLabel
@onready var text_label: Label = %TextLabel

@onready var panelcontainer: PanelContainer = %PanelContainer


var selected_algorithm: int = 0:
	set(new_value):
		selected_algorithm = new_value
		_update_panel()


func _ready() -> void:
	# Connect the press of the button to the load of the scene
	dtree_button.pressed.connect(_on_d_tree_button_pressed)
	nn_button.pressed.connect(_on_nn_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)

	start_button.disabled = true

	get_viewport().size_changed.connect(_update_size)
	_update_size()



func _on_d_tree_button_pressed() -> void:
	selected_algorithm = 1


func _on_nn_button_pressed() -> void:
	selected_algorithm = 2


func _on_start_button_pressed() -> void:
	match selected_algorithm:
		1:
			if _is_horizontal():
				get_tree().change_scene_to_file(Constants.SCENES.dtree_view_horizontal)
			else:
				get_tree().change_scene_to_file(Constants.SCENES.dtree_view)
		2:
			get_tree().change_scene_to_file(Constants.SCENES.nn_view)
		_:
			# This shold not happen, because the button should be disabled
			# if there is no selected algorithm. But in case it happended
			start_button.disabled = true


func _update_panel() -> void:
	match selected_algorithm:
		1:
			start_button.disabled = false
		2:
			start_button.disabled = false
		_:
			return

	_update_text(selected_algorithm)


func _update_text(algorithm: int) -> void:
	const dict_of_text: Dictionary[int, Array] = {
		1: ["Árbol de decisión",
			""
			],
		2: ["Red neuronal",
			""
			]
		}
	
	title_label.text = dict_of_text[algorithm][0]
	text_label.text = dict_of_text[algorithm][1]


#func _update_size() -> void:
#
#	var viewport_size: Vector2 = get_viewport_rect().size
#	var available_width: float = viewport_size.x - horizontal_margin * 2.0
#	var available_height: float = viewport_size.y - horizontal_margin * 2.0
#	panelcontainer.custom_minimum_size.x = min(max_width, available_width)
#	panelcontainer.custom_minimum_size.y = available_height

func _update_size() -> void:
	var viewport: Viewport = get_viewport()
	var window_size: Vector2 = Vector2(get_window().size)
	var display_scale: float = DisplayServer.screen_get_scale()
	if display_scale <= 0.0:
		display_scale = 1.0

	var canvas_scale: Vector2 = viewport.get_stretch_transform().get_scale() / display_scale
	if canvas_scale.x <= 0.0 or canvas_scale.y <= 0.0:
		var visible_size: Vector2 = viewport.get_visible_rect().size
		canvas_scale = (window_size / display_scale) / visible_size

	var visual_window_size: Vector2 = window_size / display_scale
	var available_width: float = maxf(0.0, visual_window_size.x - horizontal_margin * 2.0)
	var available_height: float = maxf(0.0, visual_window_size.y - horizontal_margin * 2.0)
	panelcontainer.custom_minimum_size.x = min(max_width, available_width) / canvas_scale.x
	panelcontainer.custom_minimum_size.y = available_height / canvas_scale.y


## Check if the screen is in vertical or horizontal
func _is_horizontal() -> bool:
	var window_size: Vector2 = get_window().size
	return window_size.x >= window_size.y
