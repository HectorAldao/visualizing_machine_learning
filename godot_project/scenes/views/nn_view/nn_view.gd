extends Control


@onready var panel_algorithm_nn: PanelContainer = $PanelAlgorithmNn
@onready var create_nn_menu: PanelContainer = $CreateNnMenu

var state: String = "create_nn"  # Other values: train_nn, evaluate_nn

var nn_size: Vector2

var _is_centering: bool = false

#signal nn_size_updated


func _ready() -> void:

	# Create nn menu realted buttons
	SignalsObserver.load_nn  .connect(_on_load_nn)
	SignalsObserver.reload_nn.connect(_on_reload_nn)
	SignalsObserver.train_nn .connect(_on_train_nn)

	# Centering the nn realted info
	SignalsObserver.nn_inform_size.connect(_on_set_nn_size)

	# Dataset selection info
	SignalsObserver.dataset_selected_nn.connect(_on_dataset_selected)
	
	panel_algorithm_nn.visible = false

	_center_nn()


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
	var nn_tmp_dict: Dictionary[int, Array] = Variables.nn.nn_tmp_dict.duplicate()
	var nn_dict: Dictionary[int, Array] = Variables.nn.nn_dict.duplicate()

	# Calculate de diference in size to know if add or remove layers
	var diference_in_layers: int = nn_tmp_dict.size() - nn_dict.size()
	print("diference_in_layers ", diference_in_layers) #debug

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

			print("[LOG] Nn has layer %s" % layer)

			var diference_in_neurons: int = nn_tmp_dict[layer].size() - nn_dict[layer].size()
			print("diference_in_neurons ", diference_in_neurons) #debug

			# If there are new layers, add them, elif remove them, else nothing
			if diference_in_neurons > 0:
				for _i in range(diference_in_neurons):
					SignalsObserver.add_neuron.emit(layer)
			elif diference_in_neurons < 0:
				for _i in range(-diference_in_neurons):
					print("-1 neuron")
					SignalsObserver.remove_neuron.emit(layer)

		# If this layer did not existed
		else:

			print("[LOG] Nn hasnt layer %s, that has %s neurons" % [layer, nn_tmp_dict[layer].size()] )

			# Just take the amount of new neurons (the -1 is bc the layers are created with 1 neuron)
			for _i in range(nn_tmp_dict[layer].size() - 1):
				SignalsObserver.add_neuron.emit(layer)


	# Send the signal to update connections
	SignalsObserver.update_all_conections.emit()

	# and save the new nn
	Variables.nn.apply_tmp_to_main()

	# Center the nn
	_center_nn()


func _on_train_nn() -> void:
	state = "train_nn"
	create_nn_menu.visible = false
	panel_algorithm_nn.visible = true


## Move the nn of the view to the center
func _center_nn() -> void:

	# Idk why, but is needed to wait 2 frames for the deletion/addition
	# of the layers/neurons for the Nn to know its size
	# (mabye 1 frame to the modification, and 1 to change MarginContainer's size?)
	await get_tree().process_frame
	await get_tree().process_frame

	if _is_centering:
		return

	_is_centering = true

	#SignalsObserver.nn_view_want_nn_size.emit.call_deferred()
	SignalsObserver.nn_view_want_nn_size.emit()

	#await nn_size_updated
	#print("2") #debug

	var nn_center: Vector2 = (size - nn_size) / 2

	SignalsObserver.nn_view_set_nn_position.emit(nn_center)

	_is_centering = false

	print("[LOG] Nn centered")


func _on_set_nn_size(new_nn_size: Vector2) -> void:
	nn_size = new_nn_size
	#print("1") #debug
	#nn_size_updated.emit()


func _on_dataset_selected(data:Array[Dictionary], attrs: Array[String], nn_restrictions: Dictionary[int, int]):

	# TODO: things related to set the "data" and "attrs" for the training

	SignalsObserver.establish_nn_dset_restrictions.emit(nn_restrictions)

	pass
