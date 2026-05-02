class_name NeuralNetworkLogial extends RefCounted

var nn_dict: Dictionary[int, Array] = {0: [[1]], -1: [[0.0]]}
var nn_func_dict: Dictionary[int, int] = {-1: Constants.ACT_FUNCS.softmax}
var nn_bias_dict: Dictionary[int, Array] = {-1: [0.0]}
# The tmp_dicts are used to save the state of the create_nn_menu
var nn_tmp_dict: Dictionary[int, Array] = {0: [[1]], -1: [[0.0]]}
var nn_func_tmp_dict: Dictionary[int, int] = {-1: Constants.ACT_FUNCS.softmax}
var nn_bias_tmp_dict: Dictionary[int, Array] = {-1: [0.0]}


func _init() -> void:
	nn_tmp_dict[-1][0][0] = _random_connection_weight()
	nn_bias_tmp_dict[-1][0] = _random_bias()
	nn_dict = nn_tmp_dict.duplicate(true)
	nn_bias_dict = nn_bias_tmp_dict.duplicate(true)


## Constructor of the class
static func newone() -> NeuralNetworkLogial:
	return NeuralNetworkLogial.new()


## Sets the activation function for a layer
func set_layer_activation_tmp(layer_id: int, activation_func_id: int) -> void:

	# The in_layer has no activation function
	if layer_id == 0:
		return

	nn_func_tmp_dict[layer_id] = activation_func_id


## True copy (deep copy) of the tmp dictionary into the definitive one
func apply_tmp_to_main() -> void:
	_force_input_layer_weights_to_one(nn_tmp_dict)
	_sync_bias_dict_to_weights(nn_bias_tmp_dict, nn_tmp_dict)
	nn_dict = nn_tmp_dict.duplicate(true)
	nn_func_dict = nn_func_tmp_dict.duplicate(true)
	nn_bias_dict = nn_bias_tmp_dict.duplicate(true)


func reset_biases_tmp_to_random() -> void:
	nn_bias_tmp_dict.clear()
	_sync_bias_dict_to_weights(nn_bias_tmp_dict, nn_tmp_dict)


## Change the info about a layer: its weights
func set_layer_neuron_count_tmp(layer_id: int, target_neurons: int) -> void:

	# Ensure that there is at least one neuron (else there wont be layer)
	target_neurons = max(target_neurons, 1)

	# Get the info about how many conetions come from the prev layer
	var previous_layer_neurons: int = _get_previous_layer_neuron_count(layer_id)
	# And use the info to create the matrix of weights
	nn_tmp_dict[layer_id] = _resize_layer_matrix(nn_tmp_dict.get(layer_id, []), target_neurons, previous_layer_neurons)
	if layer_id == 0:
		_force_input_layer_weights_to_one(nn_tmp_dict)
		nn_bias_tmp_dict.erase(0)
	else:
		nn_bias_tmp_dict[layer_id] = _resize_bias_vector(nn_bias_tmp_dict.get(layer_id, []), target_neurons)

	# Because of this change in the amount of neurons, the next layer must
	# change its weights too
	var next_layer_id: int = _get_next_layer_id(layer_id)
	if next_layer_id != -2 and nn_tmp_dict.has(next_layer_id):
		var current_neurons: int = nn_tmp_dict[layer_id].size()
		nn_tmp_dict[next_layer_id] = _resize_layer_matrix(nn_tmp_dict[next_layer_id], nn_tmp_dict[next_layer_id].size(), current_neurons)


## Called by the create_nn_menu to change the amount of neurons on a layer
func set_hidden_layer_count_tmp(target_hidden_layers: int) -> void:

	# Ensure that there is at least one neuron (else there wont be layer)
	target_hidden_layers = max(target_hidden_layers, 0)

	var current_hidden_layers: int = _get_hidden_layer_count()

	# And while there are more or less layers

	# If there are less
	while current_hidden_layers < target_hidden_layers:
		# Create a new layer
		var new_hidden_layer_id: int = current_hidden_layers + 1
		var previous_layer_id: int = 0 if new_hidden_layer_id == 1 else new_hidden_layer_id - 1
		#var previous_layer_id: int = new_hidden_layer_id - 1
		var previous_neurons: int = _get_layer_neuron_count(previous_layer_id)

		nn_tmp_dict[new_hidden_layer_id] = _resize_layer_matrix([], 1, previous_neurons)
		nn_func_tmp_dict[new_hidden_layer_id] = Constants.ACT_FUNCS.relu
		nn_bias_tmp_dict[new_hidden_layer_id] = _resize_bias_vector([], 1)

		if nn_tmp_dict.has(-1):
			nn_tmp_dict[-1] = _resize_layer_matrix(nn_tmp_dict[-1], nn_tmp_dict[-1].size(), 1)

		current_hidden_layers += 1

	while current_hidden_layers > target_hidden_layers:
		var layer_id_to_remove: int = current_hidden_layers
		nn_tmp_dict.erase(layer_id_to_remove)
		nn_func_tmp_dict.erase(layer_id_to_remove)
		nn_bias_tmp_dict.erase(layer_id_to_remove)
		current_hidden_layers -= 1

		var new_previous_layer_id: int = 0 if current_hidden_layers == 0 else current_hidden_layers
		var new_previous_neurons: int = _get_layer_neuron_count(new_previous_layer_id)
		if nn_tmp_dict.has(-1):
			nn_tmp_dict[-1] = _resize_layer_matrix(nn_tmp_dict[-1], nn_tmp_dict[-1].size(), new_previous_neurons)


func _get_hidden_layer_count() -> int:
	return nn_tmp_dict.size() - 2


func _get_previous_layer_neuron_count(layer_id: int) -> int:
	if layer_id == 0:
		return 1

	if layer_id == -1:
		var hidden_count: int = _get_hidden_layer_count()
		var previous_id: int = hidden_count if hidden_count > 0 else 0
		return _get_layer_neuron_count(previous_id)

	var previous_hidden_id: int = layer_id - 1
	var previous_layer_id: int = 0 if previous_hidden_id <= 0 else previous_hidden_id
	return _get_layer_neuron_count(previous_layer_id)


func _get_next_layer_id(layer_id: int) -> int:
	if layer_id == -1:
		return -2

	if layer_id == 0:
		return 1 if nn_tmp_dict.has(1) else -1

	if nn_tmp_dict.has(layer_id + 1):
		return layer_id + 1

	if nn_tmp_dict.has(-1):
		return -1

	return -2


func _get_layer_neuron_count(layer_id: int) -> int:
	if not nn_tmp_dict.has(layer_id):
		return 1

	var layer_matrix: Array = nn_tmp_dict[layer_id]
	if layer_matrix.is_empty():
		return 1

	return layer_matrix.size()


func _resize_layer_matrix(current_matrix: Array, target_rows: int, target_columns: int) -> Array:
	target_rows = max(target_rows, 1)
	target_columns = max(target_columns, 1)

	var resized_matrix: Array = []
	resized_matrix.resize(target_rows)

	for row_idx in range(target_rows):
		var source_row: Array = []
		if row_idx < current_matrix.size() and current_matrix[row_idx] is Array:
			source_row = current_matrix[row_idx]

		var new_row: Array = []
		new_row.resize(target_columns)

		for col_idx in range(target_columns):
			if col_idx < source_row.size():
				new_row[col_idx] = source_row[col_idx]
			else:
				new_row[col_idx] = _random_connection_weight()

		resized_matrix[row_idx] = new_row

	return resized_matrix


func _resize_bias_vector(current_biases: Array, target_size: int) -> Array:
	target_size = max(target_size, 1)

	var resized_biases: Array = []
	resized_biases.resize(target_size)

	for bias_idx in range(target_size):
		if bias_idx < current_biases.size():
			resized_biases[bias_idx] = float(current_biases[bias_idx])
		else:
			resized_biases[bias_idx] = _random_bias()

	return resized_biases


func _random_connection_weight() -> float:
	return Constants.NN_CONNECTION_RANDOM_MULT * randfn(0.0, sqrt(Constants.NN_CONNECTION_VARIANCE))


func _random_bias() -> float:
	return _random_connection_weight()


func _sync_bias_dict_to_weights(target_bias_dict: Dictionary[int, Array], weight_dict: Dictionary[int, Array]) -> void:
	var layers_to_remove: Array[int] = []
	for layer_id in target_bias_dict.keys():
		if layer_id == 0 or not weight_dict.has(layer_id):
			layers_to_remove.append(layer_id)

	for layer_id in layers_to_remove:
		target_bias_dict.erase(layer_id)

	for layer_id in weight_dict.keys():
		if layer_id == 0:
			continue

		var layer_matrix: Array = weight_dict[layer_id]
		target_bias_dict[layer_id] = _resize_bias_vector(target_bias_dict.get(layer_id, []), layer_matrix.size())


func _force_input_layer_weights_to_one(target_dict: Dictionary[int, Array]) -> void:
	if not target_dict.has(0):
		return

	var input_layer_matrix: Array = target_dict[0]
	for row_idx in range(input_layer_matrix.size()):
		if not (input_layer_matrix[row_idx] is Array):
			input_layer_matrix[row_idx] = [1.0]
			continue

		var neuron_weights: Array = input_layer_matrix[row_idx]
		if neuron_weights.is_empty():
			neuron_weights.append(1.0)
			continue

		for weight_idx in range(neuron_weights.size()):
			neuron_weights[weight_idx] = 1.0
