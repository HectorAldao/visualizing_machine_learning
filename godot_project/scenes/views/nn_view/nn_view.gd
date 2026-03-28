extends Control


var state: String = "create_nn"  # Other values: train_nn, evaluate_nn


func _ready() -> void:
	pass


func update_nn_view(new_state) -> void:

	if new_state:
		state = new_state

	match state:
		"create_nn":
			pass

		"train_nn":
			pass

		"evaluate_nn":
			pass
