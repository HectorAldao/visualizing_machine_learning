extends Control

@onready var nn: NeuralNetwork = get_parent()
@onready var layers: HBoxContainer = nn.get_node("Layers")

# "from_layer from_neuron to_layer to_neuron" -> Conection node
var _connections: Dictionary = {}


func _ready() -> void:
	SignalsObserver.update_conections.connect(update_conections)
	SignalsObserver.update_all_conections.connect(refresh_all_connections)
	refresh_all_connections()


func update_conections(layer_id: int, neuron_id: int) -> void:
	var _unused_neuron_id := neuron_id
	var layer_position: int = _get_layer_position_from_id(layer_id)
	_remove_non_adjacent_connections()

	_refresh_pair_connections(layer_position - 1)
	_refresh_pair_connections(layer_position)


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


func refresh_all_connections() -> void:
	_remove_non_adjacent_connections()
	for pair_start_layer in _get_layer_count() - 1:
		_refresh_pair_connections(pair_start_layer)


func _add_connection(from_neuron: Neuron, to_neuron: Neuron, key: String) -> void:

	var conection: Conection = Conection.newone(from_neuron, to_neuron, 1, Color.GREEN)

	add_child(conection)
	_connections[key] = conection


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
		if to_position - from_position != 1:
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
	if layer_id == -1:
		return _get_layer_count() - 1

	return layer_id
