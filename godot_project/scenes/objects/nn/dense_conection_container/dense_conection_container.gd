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


func update_conections(layer_id: int, _neuron_id: int) -> void:
	if not _pending_updates.has(layer_id):
		_pending_updates.append(layer_id)
	_queue_update()


func refresh_all_connections() -> void:
	_pending_updates = [-2] # Special value to indicate full refresh
	_queue_update()


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

	_remove_connections_between_layers(from_layer_id, to_layer_id)

	for from_neuron_id in from_layer.get_child_count():
		for to_neuron_id in to_layer.get_child_count():
			var key: String = _make_connection_key(from_layer_id, from_neuron_id, to_layer_id, to_neuron_id)
			var from_neuron: Neuron = from_layer.get_child(from_neuron_id) as Neuron
			var to_neuron: Neuron = to_layer.get_child(to_neuron_id) as Neuron
			_add_connection(from_neuron, to_neuron, key)


func _add_connection(from_neuron: Neuron, to_neuron: Neuron, key: String) -> void:
	var from_neuron_index: int = from_neuron._id
	var to_layer_id: int = to_neuron._layer_id
	
	# Safety checks to prevent "Out of bounds" errors during rapid structural changes
	if not Variables.nn.nn_tmp_dict.has(to_layer_id):
		return
		
	var layer_matrix: Array = Variables.nn.nn_tmp_dict[to_layer_id]
	if to_neuron._id < 0 or to_neuron._id >= layer_matrix.size():
		return
		
	var neuron_weights: Array = layer_matrix[to_neuron._id]
	if from_neuron_index < 0 or from_neuron_index >= neuron_weights.size():
		return

	var weight: float = neuron_weights[from_neuron_index]
	#var weight: float = 3

	var connection_color: Color = _get_connection_color(weight)

	# If the value is too low, the conection is going to disapear,
	# something that may not be desired.
	# If NN_CONECTION_BIAS = 0, it will disapear
	var width: float
	if weight > 0:
		width = (weight + Constants.NN_CONECTION_BIAS) * Constants.NN_CONECTION_SCALE
	else: 
		width = (-weight + Constants.NN_CONECTION_BIAS) * Constants.NN_CONECTION_SCALE

	var connection: Conection = Conection.newone(from_neuron, to_neuron, width, connection_color)

	add_child(connection)
	_connections[key] = connection


func _get_connection_color(weight: float) -> Color:
	if weight == 0:
		return Color.BLACK
	elif weight > 0:
		if weight <= 1:
			return Color.CYAN
		else:
			return Color.GREEN
	else:  # weight < 0
		if weight >= -1:
			return Color.YELLOW
		else:
			return Color.RED


func _remove_connection(key: String) -> void:
	if not _connections.has(key):
		return

	var conection: Conection = _connections[key]
	if is_instance_valid(conection):
		conection.queue_free()
	_connections.erase(key)


func _remove_connections_between_layers(from_layer_id: int, to_layer_id: int) -> void:
	var keys_to_remove: Array[String] = []
	for key in _connections:
		var ids: PackedInt32Array = _get_key_values(key)
		if ids.size() == 4 and ids[0] == from_layer_id and ids[2] == to_layer_id:
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


func _get_layer_position_from_id(layer_id: int) -> int:
	for i in range(layers.get_child_count()):
		var layer = layers.get_child(i)
		if layer is Layer and layer._id == layer_id:
			return i

	return -1
