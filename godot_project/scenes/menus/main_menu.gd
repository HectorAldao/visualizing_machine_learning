extends Control




@onready var dtree_button: Button = $VBoxContainer/DTreeButton
@onready var nn_button: Button = $VBoxContainer/NeuralNetworkButton



func _ready() -> void:
	# Connect the press of the button to the load of the scene
	dtree_button.pressed.connect(_on_d_tree_button_pressed)
	nn_button.pressed.connect(_on_nn_button_pressed)


func _on_d_tree_button_pressed() -> void:
	get_tree().change_scene_to_file(Constants.SCENES.dtree_view)

func _on_nn_button_pressed() -> void:
	get_tree().change_scene_to_file(Constants.SCENES.nn_view)
