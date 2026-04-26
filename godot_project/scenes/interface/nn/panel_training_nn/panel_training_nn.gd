extends PanelContainer

@onready var save_button: Button = $VBoxContainer/SaveButton


func _ready() -> void:
	save_button.pressed.connect(func(): SignalsObserver.save_nn.emit() )
