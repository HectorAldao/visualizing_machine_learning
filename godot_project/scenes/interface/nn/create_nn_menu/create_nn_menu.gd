extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	for c in get_children():

		if c is Button:
			c.pressed.connect(_on_button_pressed.bind(c.name))

		elif c is VBoxContainer:
			var plus_button: Button = c.get_child(0).get_child(0)
			var minus_button: Button = c.get_child(0).get_child(1)

			plus_button.pressed.connect(_on_plus_pressed.bind(c.name))
			minus_button.pressed.connect(_on_minus_pressed.bind(c.name))
			pass

	pass # Replace with function body.


func _on_button_pressed(which: String) -> void:
	SignalsObserver.create_nn_menu_button.emit(which)


func _on_plus_pressed(which: String) -> void:
	SignalsObserver.plus.emit(which)

func _on_minus_pressed(which: String) -> void:
	SignalsObserver.minus.emit(which)
