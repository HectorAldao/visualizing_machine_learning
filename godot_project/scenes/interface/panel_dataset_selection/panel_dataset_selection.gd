extends PanelContainer

@onready var hboxcontainer: HBoxContainer = $VBoxContainer/HBoxContainer

var selected_option: String

func _ready() -> void:
	for button: Button in hboxcontainer.get_children():
		button.pressed.connect(_on_dataset_selected(button.text))


func _on_dataset_selected(option: String):
	selected_option = option
	match option:
		"Csv":
			_load_csv()
		_:
			pass


func _load_csv() -> Dictionary:
	return {}
