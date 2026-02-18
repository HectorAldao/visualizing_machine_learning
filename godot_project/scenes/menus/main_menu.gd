extends Control



@export_file("*.tscn") var dtree_view_scene: String  # "scenes/views/dtree/dtree_view.tscn" "scenes/views/dtree/dtree_view.gd"



@onready var dtree_button: Button = $DTreeButton



func _ready() -> void:
	# Connect the press of the button to the load of the scene
	dtree_button.pressed.connect(_on_d_tree_button_pressed)


func _on_d_tree_button_pressed() -> void:
	get_tree().change_scene_to_file(dtree_view_scene)
