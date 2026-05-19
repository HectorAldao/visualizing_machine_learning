extends PanelContainer

@export var algorithm_name: String = ""

@onready var load_button: Button = %LoadButton
@onready var save_button: Button = %SaveButton
@onready var home_button: Button = %HomeButton


func _ready() -> void:
	
	# Update the text depending on the algorithm
	load_button.text = load_button.text + algorithm_name
	save_button.text = save_button.text + algorithm_name
	
	# Connect buttons
	home_button.pressed.connect(_go_home)


## Returns home
func _go_home() -> void:
	get_tree().change_scene_to_file(Constants.SCENES.main_menu)
