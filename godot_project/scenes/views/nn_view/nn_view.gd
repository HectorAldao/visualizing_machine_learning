extends Control


@onready var panel_algorithm_nn: PanelContainer = $PanelAlgorithmNn
@onready var create_nn_menu: PanelContainer = $CreateNnMenu
@onready var dataset_selecion_menu: PanelContainer = $PanelDatasetSelection
@onready var panel_trainin_nn: PanelContainer = $PanelTrainingNn
@onready var panel_export_format: PanelContainer = $PanelExportFormat
@onready var window_nn: WindowNn = $WindowNn

var state: String = "create_nn"  # Other values: train_nn, evaluate_nn

var nn_size: Vector2

var _is_centering: bool = false

var train_data: Array[Dictionary]
var train_attributtes: Array[String]
var train_target_attributes: Array[String] = []
var algorithm: AlgorithmNn


func _ready() -> void:
	algorithm = AlgorithmNn.new()
	add_child(algorithm)

	# Create nn menu realted buttons
	SignalsObserver.load_nn  .connect(_on_load_nn)
	SignalsObserver.reload_nn.connect(_on_reload_nn)
	SignalsObserver.train_nn .connect(_on_train_nn)

	# Centering the nn realted info
	SignalsObserver.nn_inform_size.connect(_on_set_nn_size)

	# Dataset selection info
	SignalsObserver.dataset_selected_nn.connect(_on_dataset_selected)
	
	# Save nn pressed
	SignalsObserver.save_nn.connect(_on_save_nn_pressed)

	# Start the inference mode
	SignalsObserver.test_nn_start.connect(_on_start_nn_inferece)
	
	create_nn_menu.visible = true
	dataset_selecion_menu.visible = true
	panel_algorithm_nn.visible = false
	panel_trainin_nn.visible = false
	panel_export_format.visible = false
	window_nn.visible = false

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
	window_nn.visible = true
	panel_trainin_nn.visible = true
	_configure_algorithm_training()


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


func _on_dataset_selected(data:Array[Dictionary], attrs: Array[String], target_attrs: Array[String], nn_restrictions: Dictionary[int, int]):

	train_data = data.duplicate(true)
	train_attributtes = attrs.duplicate()
	train_target_attributes = target_attrs.duplicate()

	SignalsObserver.establish_nn_dset_restrictions.emit(nn_restrictions)
	update_neuron_texts_for_layer(train_attributtes, 0)
	update_neuron_texts_for_layer(_get_output_neuron_texts(), -1)

	pass


func update_neuron_texts_for_layer(texts: Array[String], layer_id: int) -> void:
	print("[LOG] NnView requested text update for layer %d with %d labels" % [layer_id, texts.size()])

	var expected_neurons: int = _get_expected_neuron_count(layer_id)
	var labels_to_apply: Array[String] = texts.duplicate()
	if expected_neurons <= 0:
		print("[LOG] NnView could not find layer %d while updating neuron texts. Texts will be cached for late neurons." % layer_id)
	elif texts.size() > expected_neurons:
		print("[LOG] NnView received %d labels for layer %d, but the layer has %d neurons. Extra labels will be ignored by neurons without matching id." % [texts.size(), layer_id, expected_neurons])
		labels_to_apply.resize(expected_neurons)
	elif texts.size() < expected_neurons:
		print("[LOG] NnView received %d labels for layer %d, but the layer has %d neurons. Missing labels will reset to Sigma." % [texts.size(), layer_id, expected_neurons])
		while labels_to_apply.size() < expected_neurons:
			labels_to_apply.append("Σ")

	SignalsObserver.set_nn_layer_neuron_texts(layer_id, labels_to_apply)


func _get_expected_neuron_count(layer_id: int) -> int:
	if Variables.nn.nn_tmp_dict.has(layer_id):
		return Variables.nn.nn_tmp_dict[layer_id].size()

	if Variables.nn.nn_dict.has(layer_id):
		return Variables.nn.nn_dict[layer_id].size()

	return 0


func _get_output_neuron_texts() -> Array[String]:
	var output_texts: Array[String] = []
	var output_activation: int = Variables.nn.nn_func_tmp_dict.get(-1, Variables.nn.nn_func_dict.get(-1, Constants.ACT_FUNCS.identity))

	if output_activation == Constants.ACT_FUNCS.softmax and not Variables.nn_output_class_decoder.is_empty():
		var class_ids: Array = Variables.nn_output_class_decoder.keys()
		class_ids.sort()
		for class_id in class_ids:
			output_texts.append(str(Variables.nn_output_class_decoder[class_id]))
		print("[LOG] NnView prepared %d classification output labels for softmax layer" % output_texts.size())
		return output_texts

	if train_target_attributes.is_empty():
		print("[LOG] NnView could not prepare output labels because target attributes are empty")
		return output_texts

	output_texts = train_target_attributes.duplicate()
	print("[LOG] NnView prepared %d regression output labels" % output_texts.size())
	return output_texts


func _configure_algorithm_training() -> void:
	if algorithm == null or train_data.is_empty() or train_target_attributes.is_empty():
		return

	var loss_type: int = Constants.LOSS_FUNCS.mse
	if Variables.nn.nn_func_dict.get(-1, -1) == Constants.ACT_FUNCS.softmax:
		loss_type = Constants.LOSS_FUNCS.coss_entr

	algorithm.configure_training(
		train_data,
		train_attributtes,
		train_target_attributes,
		Variables.nn.nn_tmp_dict,
		Variables.nn.nn_bias_tmp_dict,
		Variables.nn.nn_func_dict,
		Constants.NN_LEARNINGRATE,
		loss_type
	)

func _on_save_nn_pressed() -> void:
	panel_export_format.visible = not panel_export_format.visible


func _on_start_nn_inferece() -> void:
	
	panel_algorithm_nn.visible = false
