class_name NeuralNetworkLogial extends RefCounted

var nn_dict: Dictionary[int, Array] = {0: [[1]], -1: [[0.5]]}
var nn_tmp_dict: Dictionary[int, Array] = {0: [[1]], -1: [[0.5]]}


static func newone() -> NeuralNetworkLogial:
	return NeuralNetworkLogial.new()


func set_layer_neuron_count_tmp(layer_id: int, target_neurons: int) -> void:
	target_neurons = max(target_neurons, 1)

	var previous_layer_neurons: int = _get_previous_layer_neuron_count(layer_id)
	nn_tmp_dict[layer_id] = _resize_layer_matrix(nn_tmp_dict.get(layer_id, []), target_neurons, previous_layer_neurons)

	var next_layer_id: int = _get_next_layer_id(layer_id)
	if next_layer_id != -9999 and nn_tmp_dict.has(next_layer_id):
		var current_neurons: int = nn_tmp_dict[layer_id].size()
		nn_tmp_dict[next_layer_id] = _resize_layer_matrix(nn_tmp_dict[next_layer_id], nn_tmp_dict[next_layer_id].size(), current_neurons)


func set_hidden_layer_count_tmp(target_hidden_layers: int) -> void:
	target_hidden_layers = max(target_hidden_layers, 0)

	var current_hidden_layers: int = _get_hidden_layer_count()

	while current_hidden_layers < target_hidden_layers:
		var new_hidden_layer_id: int = current_hidden_layers + 1
		var previous_layer_id: int = 0 if new_hidden_layer_id == 1 else new_hidden_layer_id - 1
		var previous_neurons: int = _get_layer_neuron_count(previous_layer_id)

		nn_tmp_dict[new_hidden_layer_id] = _resize_layer_matrix([], 1, previous_neurons)

		if nn_tmp_dict.has(-1):
			nn_tmp_dict[-1] = _resize_layer_matrix(nn_tmp_dict[-1], nn_tmp_dict[-1].size(), 1)

		current_hidden_layers += 1

	while current_hidden_layers > target_hidden_layers:
		var layer_id_to_remove: int = current_hidden_layers
		nn_tmp_dict.erase(layer_id_to_remove)
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
		return -9999

	if layer_id == 0:
		return 1 if nn_tmp_dict.has(1) else -1

	if nn_tmp_dict.has(layer_id + 1):
		return layer_id + 1

	if nn_tmp_dict.has(-1):
		return -1

	return -9999


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
				new_row[col_idx] = Constants.NN_FILL_VALUE

		resized_matrix[row_idx] = new_row

	return resized_matrix