extends Control


var state: String = "create_nn"  # Other values: train_nn, evaluate_nn


func _ready() -> void:
	SignalsObserver.plus.connect(_on_plus)
	SignalsObserver.minus.connect(_on_minus)
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


func _on_plus(which_layer: String, layer_id: int = 0) -> void:
	match which_layer:
		"NeuronsIn":
			SignalsObserver.add_neuron.emit(0)
		"NeuronsOut":
			SignalsObserver.add_neuron.emit(-1)
		"Layers":
			SignalsObserver.add_layer.emit()
		"NeuronsLayer":
			SignalsObserver.add_neuron.emit(layer_id)
		"NeuronsLayer2":
			SignalsObserver.add_neuron.emit(layer_id)


func _on_minus(which_layer: String, layer_id: int = 0) -> void:
	match which_layer:
		"NeuronsIn":
			SignalsObserver.remove_neuron.emit(0)
		"NeuronsOut":
			SignalsObserver.remove_neuron.emit(-1)
		"Layers":
			SignalsObserver.remove_layer.emit()
		"NeuronsLayer":
			SignalsObserver.remove_neuron.emit(layer_id)
		"NeuronsLayer2":
			SignalsObserver.remove_neuron.emit(layer_id)


func _on_layer_updated(layer: int, neuron: int) -> void:
	SignalsObserver.update_conections.emit(layer, neuron)
	pass
