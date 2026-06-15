extends Control

@onready var nn: NeuralNetwork = get_parent()
@onready var layers: HBoxContainer = nn.get_node("Layers")

# "from_layer from_neuron to_layer to_neuron" -> Conection node
var _connections: Dictionary = {}


var _pending_updates: Array[int] = []
var _is_update_queued: bool = false


func _ready() -> void:
	SignalsObserver.update_conections.connect(update_conections)
	SignalsObserver.update_all_conections.connect(refresh_all_connections)
	SignalsObserver.weight_updated.connect(update_connection_weight)
	SignalsObserver.nn_resalted_neuron_forward.connect(show_forward_input_flow)


func update_conections(layer_id: int, _neuron_id: int) -> void:
	if not _pending_updates.has(layer_id):
		_pending_updates.append(layer_id)
	_queue_update()


func refresh_all_connections() -> void:
	_pending_updates = [-2] # Special value to indicate full refresh
	_queue_update()


func update_connection_weight(layer_idx: int, neuron_idx: int, weight_idx: int, new_value: float) -> void:
	var to_layer_position: int = _get_layer_position_from_id(layer_idx)
	if to_layer_position <= 0:
		return

	var from_layer: Layer = _get_layer_by_position(to_layer_position - 1)
	var to_layer: Layer = _get_layer_by_position(to_layer_position)
	if from_layer == null or to_layer == null:
		return

	var from_neuron: Neuron = _get_neuron(from_layer, weight_idx)
	var to_neuron: Neuron = _get_neuron(to_layer, neuron_idx)
	if from_neuron == null or to_neuron == null:
		return

	var key: String = _make_connection_key(from_layer._id, weight_idx, layer_idx, neuron_idx)
	_update_connection_weight(from_neuron, to_neuron, key, new_value)


func show_forward_input_flow(neuron_idx: int, layer_idx: int, input_values: Array, _output_value: float) -> void:
	var to_layer_position: int = _get_layer_position_from_id(layer_idx)
	if to_layer_position <= 0:
		return

	var from_layer: Layer = _get_layer_by_position(to_layer_position - 1)
	var to_layer: Layer = _get_layer_by_position(to_layer_position)
	if from_layer == null or to_layer == null:
		return

	var to_neuron: Neuron = _get_neuron(to_layer, neuron_idx)
	if to_neuron == null:
		return

	for from_neuron_idx in range(input_values.size()):
		var from_neuron: Neuron = _get_neuron(from_layer, from_neuron_idx)
		if from_neuron == null:
			continue

		var key: String = _make_connection_key(from_layer._id, from_neuron_idx, layer_idx, neuron_idx)
		if not _connections.has(key) or not is_instance_valid(_connections[key]):
			continue

		var connection: Conection = _connections[key]
		connection.show_forward_flow_indicator(float(input_values[from_neuron_idx]), from_neuron, to_neuron)


func _queue_update() -> void:
	if _is_update_queued or not is_inside_tree():
		return
	_is_update_queued = true
	_do_updates.call_deferred()


func _do_updates() -> void:
	_is_update_queued = false
	if _pending_updates.has(-2):
		_actual_refresh_all_connections()
	else:
		for layer_id in _pending_updates:
			_actual_update_conections(layer_id)
	_pending_updates.clear()


func _actual_update_conections(layer_id: int) -> void:
	var layer_position: int = _get_layer_position_from_id(layer_id)
	if layer_position == -1:
		_actual_refresh_all_connections()
		return

	_remove_non_adjacent_connections()
	_refresh_pair_connections(layer_position - 1)
	_refresh_pair_connections(layer_position)


func _actual_refresh_all_connections() -> void:
	_remove_non_adjacent_connections()
	for pair_start_layer in _get_layer_count() - 1:
		_refresh_pair_connections(pair_start_layer)


func _refresh_pair_connections(pair_start_position: int) -> void:
	if pair_start_position < 0 or pair_start_position >= _get_layer_count() - 1:
		return

	var from_layer: Layer = _get_layer_by_position(pair_start_position)
	var to_layer: Layer = _get_layer_by_position(pair_start_position + 1)
	if from_layer == null or to_layer == null:
		return

	var from_layer_id: int = from_layer._id
	var to_layer_id: int = to_layer._id

	var desired_connections: Dictionary = {}

	for from_neuron_id in from_layer.get_child_count():
		for to_neuron_id in to_layer.get_child_count():
			var from_neuron: Neuron = from_layer.get_child(from_neuron_id) as Neuron
			var to_neuron: Neuron = to_layer.get_child(to_neuron_id) as Neuron
			if from_neuron == null or to_neuron == null:
				continue

			var weight: Variant = _get_connection_weight(to_layer_id, to_neuron._id, from_neuron._id)
			if weight == null:
				continue

			var key: String = _make_connection_key(from_layer_id, from_neuron._id, to_layer_id, to_neuron._id)
			desired_connections[key] = [from_neuron, to_neuron, float(weight)]

	_remove_obsolete_connections_between_layers(from_layer_id, to_layer_id, desired_connections)

	for key in desired_connections:
		var connection_data: Array = desired_connections[key]
		var from_neuron: Neuron = connection_data[0]
		var to_neuron: Neuron = connection_data[1]
		var weight: float = connection_data[2]

		if _connections.has(key) and is_instance_valid(_connections[key]):
			var connection: Conection = _connections[key]
			connection.from_node = from_neuron
			connection.to_node = to_neuron
			connection.set_line_style(_get_connection_width(weight), _get_connection_color(weight))
		else:
			_add_connection(from_neuron, to_neuron, key, weight)


func _add_connection(from_neuron: Neuron, to_neuron: Neuron, key: String, weight_override: Variant = null, show_update_indicator: bool = false) -> void:
	var from_neuron_index: int = from_neuron._id
	var to_layer_id: int = to_neuron._layer_id
	
	var weight: float
	if weight_override == null:
		var found_weight: Variant = _get_connection_weight(to_layer_id, to_neuron._id, from_neuron_index)
		if found_weight == null:
			return
		weight = found_weight
	else:
		weight = weight_override

	var connection_color: Color = _get_connection_color(weight)
	var connection_width: float = _get_connection_width(weight)

	var connection: Conection = Conection.newone(to_neuron, from_neuron, connection_width, connection_color)
	if show_update_indicator:
		connection.show_update_indicator_for_value(weight)

	add_child(connection)
	_connections[key] = connection


func _update_connection_weight(from_neuron: Neuron, to_neuron: Neuron, key: String, weight: float) -> void:
	if Constants.NN_REDRAW_CONECTIONS:
		_redraw_connection(from_neuron, to_neuron, key, weight)
		return

	if not _connections.has(key) or not is_instance_valid(_connections[key]):
		_add_connection(from_neuron, to_neuron, key, weight)
		return

	var conection: Conection = _connections[key]
	conection.set_line_style(_get_connection_width(weight), _get_connection_color(weight))


func _redraw_connection(from_neuron: Neuron, to_neuron: Neuron, key: String, weight: float) -> void:
	_remove_connection(key, true)
	_add_connection(from_neuron, to_neuron, key, weight, true)


func _get_connection_weight(to_layer_id: int, to_neuron_id: int, from_neuron_index: int) -> Variant:
	# Safety checks to prevent "Out of bounds" errors during rapid structural changes
	if not Variables.nn.nn_tmp_dict.has(to_layer_id):
		return null
		
	var layer_matrix: Array = Variables.nn.nn_tmp_dict[to_layer_id]
	if to_neuron_id < 0 or to_neuron_id >= layer_matrix.size():
		return null
		
	var neuron_weights: Array = layer_matrix[to_neuron_id]
	if from_neuron_index < 0 or from_neuron_index >= neuron_weights.size():
		return null

	return float(neuron_weights[from_neuron_index])


func _get_connection_width(weight: float) -> float:
	var connection_width: float
	if weight > 0:
		connection_width = (weight + Constants.NN_CONECTION_BIAS) * Constants.NN_CONECTION_SCALE
	else: 
		connection_width = (-weight + Constants.NN_CONECTION_BIAS) * Constants.NN_CONECTION_SCALE
	
	return clamp(connection_width, Constants.NN_CONECTION_MIN_WIDTH, Constants.NN_CONECTION_MAX_WIDTH)


func _get_connection_color(weight: float) -> Color:
	if weight == 0:
		return Color.BLACK

	if weight > 0:
		return Color.GREEN

	return Color.RED


func _remove_connection(key: String, animated: bool = false) -> void:
	if not _connections.has(key):
		return

	var conection: Conection = _connections[key]
	if is_instance_valid(conection):
		if animated:
			_prepare_connection_for_output_to_input_destroy(conection, key)
			conection.destroy_animated()
		else:
			conection.queue_free()
	_connections.erase(key)


func _prepare_connection_for_output_to_input_destroy(conection: Conection, key: String) -> void:
	var ids: PackedInt32Array = _get_key_values(key)
	if ids.size() != 4:
		return

	var from_layer: Layer = _get_layer_by_position(_get_layer_position_from_id(ids[0]))
	var to_layer: Layer = _get_layer_by_position(_get_layer_position_from_id(ids[2]))
	if from_layer == null or to_layer == null:
		return

	var from_neuron: Neuron = _get_neuron(from_layer, ids[1])
	var to_neuron: Neuron = _get_neuron(to_layer, ids[3])
	if from_neuron == null or to_neuron == null:
		return

	conection.from_node = from_neuron
	conection.to_node = to_neuron


func _remove_obsolete_connections_between_layers(from_layer_id: int, to_layer_id: int, desired_connections: Dictionary) -> void:
	var keys_to_remove: Array[String] = []
	for key in _connections:
		var ids: PackedInt32Array = _get_key_values(key)
		if ids.size() == 4 and ids[0] == from_layer_id and ids[2] == to_layer_id and not desired_connections.has(key):
			keys_to_remove.append(key)

	for key in keys_to_remove:
		_remove_connection(key)


func _remove_non_adjacent_connections() -> void:
	var keys_to_remove: Array[String] = []
	for key in _connections:
		var ids: PackedInt32Array = _get_key_values(key)
		if ids.size() != 4:
			keys_to_remove.append(key)
			continue

		var from_position: int = _get_layer_position_from_id(ids[0])
		var to_position: int = _get_layer_position_from_id(ids[2])
		
		# If either layer is not found or they are not adjacent, remove the connection
		if from_position == -1 or to_position == -1 or to_position - from_position != 1:
			keys_to_remove.append(key)

	for key in keys_to_remove:
		_remove_connection(key)


func _make_connection_key(from_layer_id: int, from_neuron_id: int, to_layer_id: int, to_neuron_id: int) -> String:
	return "%s %s %s %s" % [from_layer_id, from_neuron_id, to_layer_id, to_neuron_id]


func _get_key_values(key: String) -> PackedInt32Array:
	var parts: PackedStringArray = key.split(" ")
	if parts.size() != 4:
		return PackedInt32Array()

	return PackedInt32Array([
		int(parts[0]),
		int(parts[1]),
		int(parts[2]),
		int(parts[3])
	])


func _get_layer_count() -> int:
	return layers.get_child_count()


func _get_layer_by_position(layer_position: int) -> Layer:
	if layer_position < 0 or layer_position >= _get_layer_count():
		return null
	return layers.get_child(layer_position) as Layer


func _get_neuron(layer: Layer, neuron_id: int) -> Neuron:
	if neuron_id < 0 or neuron_id >= layer.get_child_count():
		return null
	return layer.get_child(neuron_id) as Neuron


func _get_layer_position_from_id(layer_id: int) -> int:
	for i in range(layers.get_child_count()):
		var layer = layers.get_child(i)
		if layer is Layer and layer._id == layer_id:
			return i

	return -1
