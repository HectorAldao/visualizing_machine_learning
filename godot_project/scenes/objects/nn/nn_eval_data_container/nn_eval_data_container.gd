extends Control

# Horizontal distance from each input neuron to its visible sample value.
const EVAL_DATA_GAP: float = 24.0

# Keeps one visual label per input attribute, keyed by the same attribute name
# used by AlgorithmNn when it emits the current sample values.
var _eval_data_by_attr: Dictionary = {}
# Sample values can arrive in the same frame as setup_nn_eval_data. They are
# cached here until the input layer has finished rebuilding and can be measured.
var _pending_values: Dictionary = {}
var _pending_animate: bool = false
var _is_configuring: bool = false


## Wires the container to the NN training signals. The container does not ask
## AlgorithmNn for data directly; it only reacts to setup, value-change and clear
## messages routed through SignalsObserver.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SignalsObserver.setup_nn_eval_data.connect(_on_setup_nn_eval_data)
	SignalsObserver.add_change_eval_data.connect(_on_change_eval_data)
	SignalsObserver.clear_nn_eval_data.connect(_on_clear_nn_eval_data)
	SignalsObserver.update_all_conections.connect(_refresh_positions_deferred)
	SignalsObserver.update_conections.connect(func(_layer_id: int, _num_of_neurons: int): _refresh_positions_deferred())
	resized.connect(_refresh_positions_deferred)


## Rebuilds the visual input values for the current network.
## AlgorithmNn sends the ordered input attributes, and this method pairs each
## attribute with the input neuron at the same index in layer 0.
func _on_setup_nn_eval_data(input_attributes: Array[String]) -> void:
	_is_configuring = true
	_clear_children()

	# The NN view may still be adding/removing neurons when training starts, so
	# setup waits for layout to settle before measuring global neuron positions.
	await get_tree().process_frame
	await get_tree().process_frame

	var input_layer: Layer = _get_input_layer()
	if input_layer == null:
		_is_configuring = false
		return

	for neuron_idx in range(min(input_attributes.size(), input_layer.get_child_count())):
		var attr_name: String = input_attributes[neuron_idx]
		var eval_data: NnEvalData = NnEvalData.newone(attr_name)
		eval_data.assign_neuron(input_layer.get_child(neuron_idx))
		add_child(eval_data)
		_eval_data_by_attr[attr_name] = eval_data

	_refresh_positions()
	_is_configuring = false

	if not _pending_values.is_empty():
		_apply_values(_pending_values, _pending_animate)
		_pending_values = {}
		_pending_animate = false


## Receives the sample values emitted by AlgorithmNn.
## If setup is still waiting for layout, the dictionary is stored and applied as
## soon as every NnEvalData has a target neuron.
func _on_change_eval_data(dict_of_data: Dictionary, animate_appear: bool) -> void:
	if _is_configuring or _eval_data_by_attr.is_empty():
		_pending_values = dict_of_data.duplicate(true)
		_pending_animate = animate_appear
		return

	_apply_values(dict_of_data, animate_appear)


## Clears visible values without deleting the labels, so the next training or
## inference run can reuse the same container setup.
func _on_clear_nn_eval_data() -> void:
	_pending_values = {}
	_pending_animate = false
	for eval_data in _eval_data_by_attr.values():
		if is_instance_valid(eval_data):
			eval_data.clear_value()


## Applies a new sample dictionary to the labels.
## Values are assigned once before positioning so each Label can report its real
## width; then the visible animation/value state is applied.
func _apply_values(dict_of_data: Dictionary, animate_appear: bool) -> void:
	for attr_name in _eval_data_by_attr.keys():
		var eval_data_to_measure: NnEvalData = _eval_data_by_attr[attr_name]
		if not is_instance_valid(eval_data_to_measure):
			continue

		eval_data_to_measure.text = str(dict_of_data.get(attr_name, ""))
		eval_data_to_measure.reset_size()

	_refresh_positions()
	for attr_name in _eval_data_by_attr.keys():
		var eval_data: NnEvalData = _eval_data_by_attr[attr_name]
		if not is_instance_valid(eval_data):
			continue

		if dict_of_data.has(attr_name):
			eval_data.set_value(str(dict_of_data[attr_name]), animate_appear)
		else:
			eval_data.clear_value()


## Schedules a position refresh after Godot has processed pending layout changes
## from layer/neuron additions, removals or container resizing.
func _refresh_positions_deferred() -> void:
	call_deferred("_refresh_positions")


## Places every visual value immediately to the left of the neuron that consumes
## the matching input attribute.
func _refresh_positions() -> void:
	for eval_data in _eval_data_by_attr.values():
		if not is_instance_valid(eval_data) or eval_data.target_neuron == null:
			continue

		var neuron_rect: Rect2 = eval_data.target_neuron.get_global_rect()
		var home_position: Vector2 = neuron_rect.position
		home_position.x -= eval_data.size.x + EVAL_DATA_GAP
		home_position.y += (neuron_rect.size.y - eval_data.size.y) / 2.0
		eval_data.global_position = home_position
		eval_data.set_home_position(eval_data.position)


## Finds the rendered input layer inside NeuralNetwork. This keeps the container
## independent from NnView and lets it follow the scene hierarchy it belongs to.
func _get_input_layer() -> Layer:
	var layers: HBoxContainer = get_node_or_null("../Layers")
	if layers == null:
		return null

	for child in layers.get_children():
		if child is Layer and child._id == 0:
			return child

	return null


## Removes labels from a previous training setup before pairing attributes with
## the current input layer again.
func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_eval_data_by_attr.clear()
