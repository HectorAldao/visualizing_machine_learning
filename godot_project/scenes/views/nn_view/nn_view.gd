extends Control


var state: String = "create_nn"  # Other values: train_nn, evaluate_nn


func _ready() -> void:
	SignalsObserver.load_nn  .connect(_on_load_nn)
	SignalsObserver.reload_nn.connect(_on_reload_nn)
	SignalsObserver.train_nn .connect(_on_train_nn)
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


func _on_load_nn() -> void:
	pass


func _on_reload_nn() -> void:

	print("[LOG] '_on_reload_nn' called in %s " % get_script().resource_path.get_file())

	# Get the wanted nn and the actual nn
	var nn_tmp_dict: Dictionary[int, int] = Variables.nn_tmp
	var nn_dict: Dictionary[int, int] = Variables.nn

	print(nn_tmp_dict)
	print(nn_dict)

	# Calculate de diference in size to know if add or remove layers
	var diference_in_layers: int = nn_tmp_dict.size() - nn_dict.size()

	# If there are new layers, add them, elif remove them, else nothing
	if diference_in_layers > 0:
		for _i in range(diference_in_layers):
			SignalsObserver.add_layer.emit()
	elif diference_in_layers < 0:
		for _i in range(-diference_in_layers):
			SignalsObserver.remove_layer.emit()

	# And now that the NeuralNetwork node has the same amount of layers as the nn_tmp
	# For eah layer in the wanted nn: update its neurons
	for layer in nn_tmp_dict:

		# If this layer allready existed
		if nn_dict.has(layer):

			var diference_in_neurons: int = nn_tmp_dict[layer] - nn_dict[layer]

			# If there are new layers, add them, elif remove them, else nothing
			if diference_in_neurons > 0:
				for _i in range(diference_in_neurons):
					SignalsObserver.add_neuron.emit(layer)
			elif diference_in_neurons < 0:
				for _i in range(-diference_in_neurons):
					SignalsObserver.remove_neuron.emit(layer)

		# If this layer did not existed
		else:

			# Just take the amount of new neurons
			for _i in range(nn_tmp_dict[layer]):
				SignalsObserver.add_neuron.emit(layer)


	# And last, send the signal to update connections
	SignalsObserver.update_all_conections.emit()

	# and save the new nn
	Variables.nn = nn_tmp_dict.duplicate()


func _on_train_nn() -> void:
	pass
