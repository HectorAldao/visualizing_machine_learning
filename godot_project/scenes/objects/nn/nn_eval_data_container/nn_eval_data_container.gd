extends Control

# Keeps one visual label per role key, using input attribute names for the input
# column and stringified output neuron ids for output/expected columns.
var _eval_data_by_attr: Dictionary = {}
# Sample values can arrive in the same frame as setup_nn_eval_data. They are
# cached here until the target layer has finished rebuilding and can be measured.
var _pending_values: Dictionary = {}
var _pending_animate: bool = false
var _is_configuring: bool = false
var _container_role: String = "input"


## Wires the container to the NN training signals. The container does not ask
## AlgorithmNn for data directly; it only reacts to setup, value-change and clear
## messages routed through SignalsObserver.
func _ready() -> void:
	_container_role = _get_container_role()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SignalsObserver.setup_nn_eval_data.connect(_on_setup_nn_eval_data)
	SignalsObserver.add_change_eval_data.connect(_on_change_eval_data)
	SignalsObserver.clear_nn_eval_data.connect(_on_clear_nn_eval_data)
	SignalsObserver.nn_eval_data_enter_network.connect(_on_enter_network)
	SignalsObserver.nn_eval_data_output_leave.connect(_on_output_leave)
	SignalsObserver.nn_eval_data_expected_to_error.connect(_on_expected_to_error)
	SignalsObserver.nn_eval_data_error_return.connect(_on_error_return)
	SignalsObserver.update_all_conections.connect(_refresh_positions_deferred)
	SignalsObserver.update_conections.connect(func(_layer_id: int, _num_of_neurons: int): _refresh_positions_deferred())
	resized.connect(_refresh_positions_deferred)


## Rebuilds this visual column for the current network.
## AlgorithmNn sends ordered keys for this role, and this method pairs each key
## with the neuron at the same index in the layer consumed by the role.
func _on_setup_nn_eval_data(container_role: String, value_keys: Array[String]) -> void:
	if container_role != _container_role:
		return

	_is_configuring = true
	_clear_children()

	# The NN view may still be adding/removing neurons when training starts, so
	# setup waits for layout to settle before measuring global neuron positions.
	await get_tree().process_frame
	await get_tree().process_frame

	var target_layer: Layer = _get_target_layer()
	if target_layer == null:
		_is_configuring = false
		return

	for neuron_idx in range(min(value_keys.size(), target_layer.get_child_count())):
		var attr_name: String = value_keys[neuron_idx]
		var eval_data: NnEvalData = NnEvalData.newone(attr_name, _container_role)
		eval_data.assign_neuron(target_layer.get_child(neuron_idx))
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
## Expected also listens for output-width changes so it can remain to the right
## of the Out column while output values appear one by one.
func _on_change_eval_data(container_role: String, dict_of_data: Dictionary, animate_appear: bool) -> void:
	if container_role != _container_role:
		if _container_role == "expected" and container_role == "output":
			_refresh_positions_deferred()
		return

	if _is_configuring or _eval_data_by_attr.is_empty():
		_pending_values = dict_of_data.duplicate(true)
		_pending_animate = animate_appear
		return

	_apply_values(dict_of_data, animate_appear)
	if animate_appear:
		await get_tree().create_timer(Constants.NN_EVAL_DATA_APPEAR_TIME).timeout
		SignalsObserver.nn_eval_data_animation_finished.emit(_container_role, "appear")


## Clears visible values without deleting the labels, so the next training or
## inference run can reuse the same container setup.
func _on_clear_nn_eval_data(container_role: String) -> void:
	if container_role != _container_role:
		return

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

		eval_data_to_measure.text = NnEvalData.format_display_value(dict_of_data.get(attr_name, ""))
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


## Reports when the input values have finished moving into the network.
## The labels animate themselves from the shared signal; this container emits the
## completion event used only by automatic Next Step sequencing.
func _on_enter_network(container_role: String) -> void:
	if container_role != _container_role:
		return

	await get_tree().create_timer(Constants.NN_EVAL_DATA_MOVE_FADE_TIME).timeout
	SignalsObserver.nn_eval_data_animation_finished.emit(_container_role, "enter_network")


## Runs the output-side "leave the network" animation and reports completion
## once all labels have had enough time to finish their tweens.
func _on_output_leave(container_role: String) -> void:
	if container_role != _container_role:
		return

	for eval_data in _eval_data_by_attr.values():
		if is_instance_valid(eval_data):
			eval_data.animate_leave_right()

	await get_tree().create_timer(Constants.NN_EVAL_DATA_MOVE_FADE_TIME).timeout
	SignalsObserver.nn_eval_data_animation_finished.emit(_container_role, "output_leave")


## Replaces expected target values with the output error values computed by
## AlgorithmNn after forward propagation has completed.
func _on_expected_to_error(container_role: String, dict_of_data: Dictionary) -> void:
	if container_role != _container_role:
		return

	for attr_name in _eval_data_by_attr.keys():
		var eval_data: NnEvalData = _eval_data_by_attr[attr_name]
		if not is_instance_valid(eval_data):
			continue

		eval_data.animate_expected_to_error(str(dict_of_data.get(attr_name, "")))

	await get_tree().create_timer(Constants.NN_EVAL_DATA_MOVE_FADE_TIME).timeout
	SignalsObserver.nn_eval_data_animation_finished.emit(_container_role, "expected_to_error")


## Sends the currently displayed error values back toward the network before the
## first backward neuron is evaluated.
func _on_error_return(container_role: String) -> void:
	if container_role != _container_role:
		return

	for eval_data in _eval_data_by_attr.values():
		if is_instance_valid(eval_data):
			eval_data.animate_error_return_left()

	await get_tree().create_timer(Constants.NN_EVAL_DATA_MOVE_FADE_TIME).timeout
	SignalsObserver.nn_eval_data_animation_finished.emit(_container_role, "error_return")


## Schedules a position refresh after Godot has processed pending layout changes
## from layer/neuron additions, removals or container resizing.
func _refresh_positions_deferred() -> void:
	call_deferred("_refresh_positions")


## Places every visual value beside the neuron associated with its role.
## Input values live left of layer 0, output values right of the output layer,
## and expected/error values right of the output-value column.
func _refresh_positions() -> void:
	for eval_data in _eval_data_by_attr.values():
		if not is_instance_valid(eval_data) or eval_data.target_neuron == null:
			continue

		var neuron_rect: Rect2 = eval_data.target_neuron.get_global_rect()
		var home_position: Vector2 = neuron_rect.position
		match _container_role:
			"output":
				home_position.x += neuron_rect.size.x + Constants.NN_EVAL_DATA_GAP
			"expected":
				home_position.x = _get_expected_global_x(eval_data)
			_:
				home_position.x -= eval_data.size.x + Constants.NN_EVAL_DATA_GAP
		home_position.y += (neuron_rect.size.y - eval_data.size.y) / 2.0
		eval_data.global_position = home_position
		eval_data.set_home_position(eval_data.position)


## Maps scene node names to visual roles. This lets the same packed scene be
## reused for input, output and expected/error columns.
func _get_container_role() -> String:
	if name.ends_with("Out"):
		return "output"
	if name.ends_with("Expected"):
		return "expected"
	return "input"


## Finds the rendered layer this container is attached to inside NeuralNetwork.
## Input uses layer 0; output and expected/error use the output layer.
func _get_target_layer() -> Layer:
	var layers: HBoxContainer = get_node_or_null("../Layers")
	if layers == null:
		return null

	var target_layer_id: int = 0 if _container_role == "input" else -1
	for child in layers.get_children():
		if child is Layer and child._id == target_layer_id:
			return child

	return null


## Calculates the expected/error column x position from the output-value label
## with the same key when possible, keeping Expected visually to the right of Out.
func _get_expected_global_x(eval_data: NnEvalData) -> float:
	var output_container: Control = get_node_or_null("../NnEvalDataContainerOut")
	if output_container and output_container.has_method("get_eval_data_global_right"):
		var output_right: float = output_container.get_eval_data_global_right(eval_data.atr_name)
		if output_right > 0.0:
			return output_right + Constants.NN_EVAL_DATA_GAP

	var neuron_rect: Rect2 = eval_data.target_neuron.get_global_rect()
	return neuron_rect.position.x + neuron_rect.size.x + Constants.NN_EVAL_DATA_EXPECTED_GAP


## Returns the right edge of a label for sibling containers that need to align
## themselves relative to this column.
func get_eval_data_global_right(attr_name: String) -> float:
	if not _eval_data_by_attr.has(attr_name):
		return 0.0

	var eval_data: NnEvalData = _eval_data_by_attr[attr_name]
	if not is_instance_valid(eval_data):
		return 0.0

	return eval_data.get_global_rect().end.x


## Removes labels from a previous training setup before pairing role keys with
## the current target layer again.
func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_eval_data_by_attr.clear()
