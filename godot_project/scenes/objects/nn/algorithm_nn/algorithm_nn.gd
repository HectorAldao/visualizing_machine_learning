class_name AlgorithmNn extends Node


# Nn related variables

# Weights of the network, its going to be updated on each 
var _weights: Dictionary = {}
# Biases of each trainable neuron, parallel to _weights by layer and neuron.
var _biases: Dictionary = {}
# Activacion function for each layer
var _activations: Dictionary = {}
# The data used to train the nn
var _train_data: Array[Dictionary] = []
# The input atributes
var _train_attributes: Array[String] = []
# Tht names on the output neurons
var _target_attributes: Array[String] = []

# Learning rate
var _learning_rate: float = Constants.NN_LEARNINGRATE
# Function to which compute the error
var _loss_type: int = Constants.LOSS_FUNCS.mse


# Logistic variables

# Arrays used to iterate over the layers
var _sorted_layer_indices: Array[int] = []
var _reversed_layer_indices: Array[int] = []

# Intermediate states stored for backpropagation and visualization
var layer_outputs: Dictionary = {} # Store 'a' values (after activation)
var layer_weighted_sums: Dictionary = {} # Store 'z' values (before activation)
var layer_deltas: Dictionary = {}


# State machine related variables

# Current item in traning data
var _current_data_idx: int = 0
# State of the nn
var _current_phase: String = "idle"
# Index of the current layer
var _current_layer_cursor: int = 0
# Index of the current neuron in the current laer
var _current_neuron_cursor: int = 0
# The array of current input data
var _current_input_data: Array = []
var _current_target_data: Array = []
var _backprop_weights_snapshot: Dictionary = {}
# True only while "Complete training" drains all remaining samples. Visual
# sample-loading steps are skipped while this flag is active.
var _is_completing_training: bool = false
var _is_inference_mode: bool = false
# Prevents the input-value labels from playing the "enter network" animation more
# than once for the same sample.
var _input_values_entered_for_current_sample: bool = false
# Output values already emitted for the current sample, keyed by output neuron id.
# It lets the output column update one neuron at a time without clearing older
# output labels.
var _current_output_values: Dictionary = {}

var _cached_phase: String = ""
var _cached_layer_idx: int = 0
var _cached_z_values: Array = []
var _cached_a_values: Array = []
var _cached_deltas: Array = []
var _last_completed_forward_layer_info: Dictionary = {}
var _last_completed_backward_layer_id: int = -9999
var _last_completed_backward_layer_info: Dictionary = {}
var _last_completed_sample_info: Dictionary = {}


func _ready() -> void:
	# Connect the signals related to the buttons in panel_algorithm_nn
	SignalsObserver.train_nn_next_neuron.connect(train_next_neuron)
	SignalsObserver.train_nn_next_layer.connect(train_next_layer)
	SignalsObserver.train_nn_next_step.connect(train_next_step)
	SignalsObserver.train_nn_complete.connect(train_complete)


## Prepares the variables for the training.
## This is also the entry point for the visual eval-data flow: it asks the three
## NnEvalDataContainer roles to create labels, prepares sample 0, and emits input
## plus expected values without the "appear from left" animation.
func configure_training(
	train_data: Array[Dictionary],
	train_attributes: Array[String],
	target_attributes: Array[String],
	weights: Dictionary,
	biases: Dictionary,
	activations: Dictionary,
	learning_rate: float,
	loss_type: int = Constants.LOSS_FUNCS.mse,
	inference_mode: bool = false
) -> void:

	_train_data = train_data.duplicate(true)
	_train_attributes = train_attributes.duplicate()
	_target_attributes = target_attributes.duplicate()
	_weights = weights
	_biases = _ensure_biases_match_weights(biases, _weights)
	_activations = activations
	_learning_rate = learning_rate
	_loss_type = loss_type
	_is_inference_mode = inference_mode
	_sorted_layer_indices = _get_sorted_layer_indices(_weights.keys())
	_reversed_layer_indices = _sorted_layer_indices.duplicate()
	_reversed_layer_indices.reverse()
	_current_data_idx = 0
	_current_phase = "idle"
	_is_completing_training = false
	_last_completed_forward_layer_info = {}
	_last_completed_backward_layer_id = -9999
	_last_completed_backward_layer_info = {}
	_last_completed_sample_info = {}
	_reset_runtime_state()

	if _train_data.is_empty() or (not _is_inference_mode and _target_attributes.is_empty()):
		_current_phase = "finished"
		_clear_all_eval_data()
		return

	SignalsObserver.setup_nn_eval_data.emit("input", _train_attributes)
	SignalsObserver.setup_nn_eval_data.emit("output", _get_output_value_keys())
	SignalsObserver.setup_nn_eval_data.emit("expected", _get_output_value_keys())
	_prepare_current_sample()
	_emit_current_eval_data(false)
	_emit_current_expected_data(false)
	SignalsObserver.clear_nn_eval_data.emit("output")
	SignalsObserver.nn_resalted_data_loaded.emit(_get_data_loaded_info(false))


func configure_inference(
	inference_data: Array[Dictionary],
	inference_attributes: Array[String],
	target_attributes: Array[String],
	weights: Dictionary,
	biases: Dictionary,
	activations: Dictionary
) -> void:
	configure_training(
		inference_data,
		inference_attributes,
		target_attributes,
		weights,
		biases,
		activations,
		0.0,
		Constants.LOSS_FUNCS.mse,
		true
	)


## Advances exactly one neuron-sized operation in the current phase.
## Visual phases count as one operation too, so this button can step through
## load_sample, compare_outputs and return_errors one click at a time.
func train_next_neuron(_neuron_id: int = -1, _layer_id: int = -9999) -> void:
	_advance_one_neuron()


## Advances until the current layer changes.
## Visual transition phases are treated as their own stops, so layer-level
## navigation pauses on input loading, output comparison and error return.
func train_next_layer(_layer_id: int = -9999) -> void:
	if _is_training_finished():
		return

	if _is_visual_transition_phase():
		_advance_one_neuron()
		return

	var phase_before: String = _current_phase
	var layer_before: int = _get_current_layer_idx()
	_last_completed_forward_layer_info = {}
	_last_completed_backward_layer_id = -9999
	_last_completed_backward_layer_info = {}

	while not _is_training_finished() and _current_phase == phase_before and _get_current_layer_idx() == layer_before:
		if not _advance_one_neuron():
			break

	if phase_before == "forward" and int(_last_completed_forward_layer_info.get("layer_id", -9999)) == layer_before:
		SignalsObserver.nn_layer_resalted.emit(layer_before)
		SignalsObserver.nn_resalted_layer_forward.emit(_last_completed_forward_layer_info.duplicate(true))
	elif phase_before == "backward" and _last_completed_backward_layer_id == layer_before:
		SignalsObserver.nn_layer_resalted.emit(layer_before)
		SignalsObserver.nn_resalted_layer_backward.emit(_last_completed_backward_layer_info.duplicate(true))


## Advances one full training row.
## Unlike neuron/layer navigation, this waits for the output/error animations so
## the row reads as input -> output -> comparison -> error return.
func train_next_step() -> void:
	if _is_training_finished():
		return

	var data_before: int = _current_data_idx
	_last_completed_sample_info = {}

	while not _is_training_finished() and _current_data_idx == data_before:
		var phase_before: String = _current_phase
		var should_wait_for_input_enter: bool = _should_wait_for_input_enter_on_next_advance()
		if not _advance_one_neuron():
			break
		await _wait_for_visual_transition_if_needed(phase_before, should_wait_for_input_enter)

	if not _is_inference_mode and not _is_training_finished() and int(_last_completed_sample_info.get("data_idx", -1)) == data_before:
		SignalsObserver.nn_resalted_data_step.emit(_last_completed_sample_info.duplicate(true))


## Finishes all remaining training work without emitting intermediate
## visual transition animations. The visual labels are cleared when the final row
## ends.
func train_complete() -> void:
	_is_completing_training = true
	while not _is_training_finished():
		if not _advance_one_neuron():
			break
	_is_completing_training = false


# --- Forward methods ---


## Calculates deltas for both output and hidden layers.
## Output layer is handled as a special case internally.
## It outputs an Array of the 
func compute_layer_deltas(
	layer_idx: int,
	target: Array,
	output_values: Array,
	z_values: Array,
	act_type: int,
	loss_type: int,
	next_deltas: Array,
	next_weights: Array,
	emit_signals: bool = true
) -> Array[float]:

	# Get the number of neurons
	var num_neurons: int = z_values.size()
	var upstream_gradients: Array[float] = []
	upstream_gradients.resize(num_neurons)

	# If its the las layer
	if layer_idx == -1:
		# and softmax function with coross_entropy
		if Functions.is_softmax_activation(act_type) and loss_type == Constants.LOSS_FUNCS.coss_entr:
			# Initialize the array of deltas
			var output_deltas: Array[float] = []
			# For each neuron
			for i in range(num_neurons):
				# Compute the delta
				# SOFTMAX + CROSS-ENTROPY OPTIMIZATION:
				# Mathematically, the output delta is calculated via the chain rule by multiplying the 
				# derivative of the loss function (-target / output) by the derivative (Jacobian) of 
				# the Softmax activation function.
				#
				# THE PROBLEM: This approach is computationally expensive and numerically unstable, as 
				# it involves divisions by very small values that can lead to gradient explosion or NaN errors.
				#
				# THE SOLUTION: When combined, the derivative of the loss with respect to the net input 
				# (logits) simplifies elegantly to (output - target). This is the industry standard 
				# because it is exact, computationally efficient, and provides perfect numerical stability.
				var output_delta: float = output_values[i] - target[i]
				output_deltas.append(output_delta)
				if emit_signals:
					SignalsObserver.backward_step_completed.emit(layer_idx, i, output_delta)
			return output_deltas

		# if its not softmax with coross_entropy
		# just compute the difference between output and target
		# with the corresponding loss type
		upstream_gradients = Functions.compute_output_loss_error(output_values, target, loss_type)

	# If its not the last layer
	else:
		# For a hidden layer there is no direct target value to compare against.
		# Its error comes from every neuron in the next layer that used this
		# neuron's output as an input. Each next-layer delta says "how much the
		# loss changes with that next neuron's weighted sum", and next_weights[j][i]
		# says how strongly this current neuron contributed to next neuron j.
		#
		# The weighted sum below is therefore the chain rule term:
		# dLoss / dCurrentActivation[i] =
		#     sum_j(next_weights[j][i] * next_deltas[j])
		#
		# We store it in upstream_gradients because it is the gradient arriving
		# from the layer upstream in backpropagation. It is not this layer's delta
		# yet: it is still with respect to the current neuron's activated output.
		for i in range(num_neurons):
			var error_sum: float = 0.0
			for j in range(next_deltas.size()):
				error_sum += next_weights[j][i] * next_deltas[j]
			upstream_gradients[i] = error_sum

	# Probably never its going to be needed
	# If the act funct is softmax but the error is not coross entropy
	if Functions.is_softmax_activation(act_type):
		var current_output = output_values if layer_idx == -1 else Functions.apply_activation_values(z_values, act_type)
		var softmax_deltas: Array[float] = Functions.apply_softmax_backprop(current_output, upstream_gradients)
		if emit_signals:
			for i in range(softmax_deltas.size()):
				SignalsObserver.backward_step_completed.emit(layer_idx, i, softmax_deltas[i])
		return softmax_deltas

	var deltas: Array[float] = []
	for i in range(num_neurons):
		# Convert the upstream gradient from "with respect to this neuron's
		# activation" (a) into "with respect to this neuron's weighted sum z".
		# This multiplication is the local activation part of the chain rule:
		# delta_i = dLoss/dActivation_i * dActivation_i/dZ_i.
		# Those deltas are the values used later to compute weight gradients:
		# dLoss/dWeight_i_k = delta_i * previous_layer_output_k.
		var delta: float = upstream_gradients[i] * Functions.apply_activation_derivative(z_values[i], act_type)
		deltas.append(delta)
		if emit_signals:
			SignalsObserver.backward_step_completed.emit(layer_idx, i, delta)

	return deltas


# func update_layer_weights(layer_weights: Array, current_layer_deltas: Array, prev_outputs: Array, lr: float, l_idx: int) -> void:
# 	for i in range(layer_weights.size()):
# 		for j in range(layer_weights[i].size()):
# 			var gradient = current_layer_deltas[i] * prev_outputs[j]
# 			layer_weights[i][j] -= lr * gradient
# 			SignalsObserver.weight_updated.emit(l_idx, i, j, layer_weights[i][j])


# --- Incremental training flow ---

## Dispatches the smallest unit of incremental training for the current phase.
## Visual phases exist only to let the UI swap input labels, compare outputs with
## targets, and send errors back before real backward computation starts.
func _advance_one_neuron() -> bool:
	if _is_training_finished():
		return false

	match _current_phase:
		"load_sample":
			return _advance_load_sample()
		"forward":
			return _advance_forward_neuron()
		"compare_outputs":
			return _advance_compare_outputs()
		"return_errors":
			return _advance_return_errors()
		"backward":
			return _advance_backward_neuron()
		_:
			return false


## Computes and emits one forward neuron result.
## On the first forward neuron of a row, it also tells NnEvalData labels to move
## right and fade, representing the sample entering the network.
func _advance_forward_neuron() -> bool:
	var layer_idx: int = _get_current_layer_idx()
	if layer_idx == -9999:
		return false

	if not _is_completing_training and not _input_values_entered_for_current_sample:
		SignalsObserver.nn_eval_data_enter_network.emit("input")
		_input_values_entered_for_current_sample = true

	_prepare_forward_cache(layer_idx)

	var neuron_output: float = _cached_a_values[_current_neuron_cursor]
	SignalsObserver.forward_step_completed.emit(layer_idx, _current_neuron_cursor, neuron_output)
	SignalsObserver.nn_resalted_neuron_forward.emit(_current_neuron_cursor, layer_idx, _current_input_data.duplicate(true), neuron_output)
	if layer_idx == -1:
		_emit_output_eval_data(_current_neuron_cursor, neuron_output)

	_current_neuron_cursor += 1
	if _current_neuron_cursor >= _cached_a_values.size():
		_last_completed_forward_layer_info = _get_forward_layer_info(layer_idx, _current_input_data, _cached_z_values, _cached_a_values)
		layer_weighted_sums[layer_idx] = _cached_z_values.duplicate(true)
		layer_outputs[layer_idx] = _cached_a_values.duplicate(true)
		_current_input_data = _cached_a_values.duplicate(true)
		_current_layer_cursor += 1
		_current_neuron_cursor = 0
		_clear_layer_cache()

		if _current_layer_cursor >= _sorted_layer_indices.size():
			if _is_inference_mode:
				_finish_current_sample()
				return true
			_current_phase = "compare_outputs"
			_current_layer_cursor = 0

	return true


## Computes and applies one backward neuron update, then finishes the sample when
## all reversed layers have been processed.
func _advance_backward_neuron() -> bool:
	var layer_idx: int = _get_current_layer_idx()
	if layer_idx == -9999:
		return false

	_prepare_backward_cache(layer_idx)

	var delta: float = _cached_deltas[_current_neuron_cursor]
	var backward_info: Dictionary = _get_backward_neuron_info(layer_idx, _current_neuron_cursor, delta)
	SignalsObserver.backward_step_completed.emit(layer_idx, _current_neuron_cursor, delta)
	SignalsObserver.nn_resalted_neuron_backward.emit(_current_neuron_cursor, layer_idx, backward_info)
	_store_current_delta(layer_idx, _current_neuron_cursor, delta)
	_update_neuron_weights(layer_idx, _current_neuron_cursor, delta)

	_current_neuron_cursor += 1
	if _current_neuron_cursor >= _cached_deltas.size():
		_last_completed_backward_layer_id = layer_idx
		_last_completed_backward_layer_info = _get_backward_layer_info(layer_idx)
		_current_layer_cursor += 1
		_current_neuron_cursor = 0
		_clear_layer_cache()

		if _current_layer_cursor >= _reversed_layer_indices.size():
			_finish_current_sample()

	return true


func _get_backward_neuron_info(layer_idx: int, neuron_idx: int, delta: float) -> Dictionary:
	var z_values: Array = layer_weighted_sums.get(layer_idx, [])
	var output_values: Array = layer_outputs.get(layer_idx, [])
	var next_layer_idx: int = _get_next_layer_index(layer_idx, _sorted_layer_indices)
	var next_deltas: Array = layer_deltas.get(next_layer_idx, [])
	var next_weights: Array = _backprop_weights_snapshot.get(next_layer_idx, [])
	var activation_type: int = _activations.get(layer_idx, Constants.ACT_FUNCS.identity)
	var output_value: float = 0.0
	var z_value: float = 0.0
	var target_value: float = 0.0
	var upstream_gradient: float = 0.0

	if neuron_idx >= 0 and neuron_idx < output_values.size():
		output_value = float(output_values[neuron_idx])
	if neuron_idx >= 0 and neuron_idx < z_values.size():
		z_value = float(z_values[neuron_idx])
	if neuron_idx >= 0 and neuron_idx < _current_target_data.size():
		target_value = float(_current_target_data[neuron_idx])

	if layer_idx == -1:
		var output_errors: Array[float] = Functions.compute_output_loss_error(output_values, _current_target_data, _loss_type)
		if neuron_idx >= 0 and neuron_idx < output_errors.size():
			upstream_gradient = output_errors[neuron_idx]
	else:
		for next_neuron_idx in range(next_deltas.size()):
			if next_neuron_idx < next_weights.size() and neuron_idx < next_weights[next_neuron_idx].size():
				upstream_gradient += float(next_weights[next_neuron_idx][neuron_idx]) * float(next_deltas[next_neuron_idx])

	return {
		"neuron_id": neuron_idx,
		"delta": delta,
		"z": z_value,
		"output": output_value,
		"outputs": output_values.duplicate(true),
		"target": target_value,
		"targets": _current_target_data.duplicate(true),
		"upstream_gradient": upstream_gradient,
		"activation_type": activation_type,
		"loss_type": _loss_type,
		"is_output_layer": layer_idx == -1,
		"next_deltas": next_deltas.duplicate(true),
		"next_weights": next_weights.duplicate(true),
	}


func _get_forward_layer_info(layer_idx: int, input_values: Array, z_values: Array, output_values: Array) -> Dictionary:
	return {
		"layer_id": layer_idx,
		"input_values": input_values.duplicate(true),
		"weights": _weights.get(layer_idx, []).duplicate(true),
		"biases": _biases.get(layer_idx, []).duplicate(true),
		"z_values": z_values.duplicate(true),
		"output_values": output_values.duplicate(true),
		"activation_type": _activations.get(layer_idx, Constants.ACT_FUNCS.identity),
	}


func _get_current_sample_info() -> Dictionary:
	var output_values: Array = layer_outputs.get(-1, []).duplicate(true)
	var target_values: Array = _current_target_data.duplicate(true)
	return {
		"data_idx": _current_data_idx,
		"input_values": layer_outputs.get(0, []).duplicate(true),
		"output_values": output_values,
		"target_values": target_values,
		"loss_type": _loss_type,
		"loss_value": Functions.compute_loss_value(output_values, target_values, _loss_type),
		"output_activation_type": _activations.get(-1, Constants.ACT_FUNCS.identity),
		"train_attributes": _train_attributes.duplicate(),
		"target_attributes": _target_attributes.duplicate(),
	}


func _get_data_loaded_info(animate_appear: bool) -> Dictionary:
	return {
		"data_idx": _current_data_idx,
		"input_values": _current_input_data.duplicate(true),
		"target_values": _current_target_data.duplicate(true),
		"train_attributes": _train_attributes.duplicate(),
		"target_attributes": _target_attributes.duplicate(),
		"animate_appear": animate_appear,
	}


func _get_error_calculation_info() -> Dictionary:
	var output_values: Array = layer_outputs.get(-1, []).duplicate(true)
	var target_values: Array = _current_target_data.duplicate(true)
	return {
		"data_idx": _current_data_idx,
		"output_values": output_values,
		"output_z_values": layer_weighted_sums.get(-1, []).duplicate(true),
		"target_values": target_values,
		"output_deltas": _get_output_delta_values(),
		"loss_gradients": Functions.compute_output_loss_error(output_values, target_values, _loss_type),
		"loss_type": _loss_type,
		"loss_value": Functions.compute_loss_value(output_values, target_values, _loss_type),
		"output_activation_type": _activations.get(-1, Constants.ACT_FUNCS.identity),
		"target_attributes": _target_attributes.duplicate(),
	}


func _get_error_return_info() -> Dictionary:
	var error_info: Dictionary = _get_error_calculation_info()
	error_info["first_backprop_layer"] = -1
	if not _reversed_layer_indices.is_empty():
		error_info["first_backprop_layer"] = _reversed_layer_indices[0]
	return error_info


func _get_backward_layer_info(layer_idx: int) -> Dictionary:
	var previous_layer_idx: int = _get_previous_layer_index(layer_idx, _weights.keys())
	var next_layer_idx: int = _get_next_layer_index(layer_idx, _sorted_layer_indices)
	return {
		"layer_id": layer_idx,
		"deltas": layer_deltas.get(layer_idx, []).duplicate(true),
		"upstream_gradients": _get_layer_upstream_gradients(layer_idx),
		"z_values": layer_weighted_sums.get(layer_idx, []).duplicate(true),
		"output_values": layer_outputs.get(layer_idx, []).duplicate(true),
		"previous_outputs": layer_outputs.get(previous_layer_idx, []).duplicate(true),
		"weights": _backprop_weights_snapshot.get(layer_idx, _weights.get(layer_idx, [])).duplicate(true),
		"biases": _biases.get(layer_idx, []).duplicate(true),
		"activation_type": _activations.get(layer_idx, Constants.ACT_FUNCS.identity),
		"loss_type": _loss_type,
		"is_output_layer": layer_idx == -1,
		"target_values": _current_target_data.duplicate(true),
		"next_layer_id": next_layer_idx,
		"next_deltas": layer_deltas.get(next_layer_idx, []).duplicate(true),
		"next_weights": _backprop_weights_snapshot.get(next_layer_idx, []).duplicate(true),
		"learning_rate": _learning_rate,
	}


func _get_layer_upstream_gradients(layer_idx: int) -> Array:
	if layer_idx == -1:
		return Functions.compute_output_loss_error(layer_outputs.get(layer_idx, []), _current_target_data, _loss_type)

	var output_values: Array = layer_outputs.get(layer_idx, [])
	var next_layer_idx: int = _get_next_layer_index(layer_idx, _sorted_layer_indices)
	var next_deltas: Array = layer_deltas.get(next_layer_idx, [])
	var next_weights: Array = _backprop_weights_snapshot.get(next_layer_idx, [])
	var upstream_gradients: Array = []
	upstream_gradients.resize(output_values.size())
	upstream_gradients.fill(0.0)

	for neuron_idx in range(output_values.size()):
		var error_sum: float = 0.0
		for next_neuron_idx in range(next_deltas.size()):
			if next_neuron_idx < next_weights.size() and neuron_idx < next_weights[next_neuron_idx].size():
				error_sum += float(next_weights[next_neuron_idx][neuron_idx]) * float(next_deltas[next_neuron_idx])
		upstream_gradients[neuron_idx] = error_sum

	return upstream_gradients


## Loads _current_data_idx into the runtime caches used by forward/backward.
## layer_outputs[0] is where later weight updates read the original input values.
func _prepare_current_sample() -> void:
	_reset_runtime_state()

	if _current_data_idx < 0 or _current_data_idx >= _train_data.size():
		_current_phase = "finished"
		return

	var row: Dictionary = _train_data[_current_data_idx]
	_current_input_data = _extract_input_data(row)
	_current_target_data = _extract_target_data(row)
	layer_outputs[0] = _current_input_data.duplicate(true)
	_input_values_entered_for_current_sample = false
	_current_phase = "forward"


## Moves the state machine from the completed row to either finished,
## load_sample, or the next row directly when Complete training is draining.
func _finish_current_sample() -> void:
	_last_completed_sample_info = _get_current_sample_info()

	if not _is_inference_mode:
		_sync_weights_with_variables()
	_current_data_idx += 1

	if _current_data_idx >= _train_data.size():
		_current_phase = "finished"
		_clear_all_eval_data()
		if _is_inference_mode:
			SignalsObserver.nn_inference_finished.emit()
			print("[LOG] NN inference completed")
		else:
			SignalsObserver.nn_train_finished.emit()
			print("[LOG] NN training completed")
		return

	if _is_completing_training:
		_prepare_current_sample()
	else:
		_current_phase = "load_sample"
		_reset_runtime_state()


## Consumes the visual-only gap between rows.
## It prepares the next sample for computation and emits its input values with
## the "appear from left" animation before any forward neuron is evaluated.
func _advance_load_sample() -> bool:
	if _current_data_idx < 0 or _current_data_idx >= _train_data.size():
		_current_phase = "finished"
		_clear_all_eval_data()
		return false

	_prepare_current_sample()
	if not _is_completing_training:
		_emit_current_eval_data(true)
		_emit_current_expected_data(false)
		SignalsObserver.clear_nn_eval_data.emit("output")
		SignalsObserver.nn_resalted_data_loaded.emit(_get_data_loaded_info(true))

	return true


## Starts the visual comparison step between forward and backward.
## Output labels leave to the right, while expected labels become the error
## values that the backward pass will consume.
func _advance_compare_outputs() -> bool:
	if _is_completing_training:
		_current_phase = "return_errors"
		return true

	SignalsObserver.nn_resalted_error_calculated.emit(_get_error_calculation_info())
	SignalsObserver.nn_eval_data_output_leave.emit("output")
	SignalsObserver.nn_eval_data_expected_to_error.emit("expected", _get_output_error_values())
	_current_phase = "return_errors"
	return true


## Starts the visual error-return step and then arms the real backward phase.
## Backpropagation still computes its cache normally when the first backward
## neuron is reached.
func _advance_return_errors() -> bool:
	if not _is_completing_training:
		SignalsObserver.nn_resalted_error_returned.emit(_get_error_return_info())
		SignalsObserver.nn_eval_data_error_return.emit("expected")

	_current_phase = "backward"
	_current_layer_cursor = 0
	_current_neuron_cursor = 0
	_backprop_weights_snapshot = _weights.duplicate(true)
	return true


## Extracts the ordered numeric inputs from a raw dataset row.
## The same _train_attributes order is used by _emit_current_eval_data, which
## keeps computation values and visual labels aligned.
func _extract_input_data(row: Dictionary) -> Array:
	var input_data: Array = []
	for attr in _train_attributes:
		input_data.append(float(row.get(attr, 0.0)))
	return input_data


## Extracts the expected output for the current row.
## Regression targets are read directly; classification targets are converted to
## one-hot vectors matching the output layer size.
func _extract_target_data(row: Dictionary) -> Array:
	var output_neurons: int = 1
	if _weights.has(-1):
		output_neurons = _weights[-1].size()

	if output_neurons <= 1 or _target_attributes.size() > 1:
		var regression_targets: Array = []
		for target_attribute in _target_attributes:
			regression_targets.append(float(row.get(target_attribute, 0.0)))
		return regression_targets

	var target_data: Array = []
	target_data.resize(output_neurons)
	target_data.fill(0.0)

	var target_value = row.get(_target_attributes[0], 0)
	var class_idx: int = int(target_value)
	if class_idx >= 0 and class_idx < output_neurons:
		target_data[class_idx] = 1.0

	return target_data


## Converts the current raw row into the dictionary consumed by NnEvalData.
## The keys are the input attribute names, matching the labels created during
## setup_nn_eval_data.
func _emit_current_eval_data(animate_appear: bool) -> void:
	if _current_data_idx < 0 or _current_data_idx >= _train_data.size():
		_clear_all_eval_data()
		return

	var row: Dictionary = _train_data[_current_data_idx]
	var eval_values: Dictionary = {}
	for attr in _train_attributes:
		eval_values[attr] = row.get(attr, "")

	SignalsObserver.add_change_eval_data.emit("input", eval_values, animate_appear)


## Emits the target values for the current sample into the Expected column.
## These are the values the output layer is compared against after forward.
func _emit_current_expected_data(animate_appear: bool) -> void:
	var eval_values: Dictionary = {}
	for output_idx in range(_current_target_data.size()):
		eval_values[str(output_idx)] = _current_target_data[output_idx]

	SignalsObserver.add_change_eval_data.emit("expected", eval_values, animate_appear)


## Emits one output neuron value and keeps previously emitted output values
## visible, matching the one-neuron-at-a-time stepping behavior.
func _emit_output_eval_data(output_neuron_idx: int, output_value: float) -> void:
	if _is_completing_training:
		return

	_current_output_values[str(output_neuron_idx)] = output_value
	SignalsObserver.add_change_eval_data.emit("output", _current_output_values, false)


## Computes the visible error values shown between forward and backward.
## The same delta calculation as backpropagation is used so the displayed values
## match what is about to travel backward through the network.
func _get_output_error_values() -> Dictionary:
	var output_errors: Dictionary = {}
	var deltas: Array = _get_output_delta_values()

	for output_idx in range(deltas.size()):
		output_errors[str(output_idx)] = deltas[output_idx]

	return output_errors


func _get_output_delta_values() -> Array:
	if not layer_outputs.has(-1) or not layer_weighted_sums.has(-1):
		return []

	return compute_layer_deltas(
		-1,
		_current_target_data,
		layer_outputs[-1],
		layer_weighted_sums[-1],
		_activations.get(-1, Constants.ACT_FUNCS.identity),
		_loss_type,
		[],
		[],
		false
	)


func _prepare_forward_cache(layer_idx: int) -> void:
	if _cached_phase == "forward" and _cached_layer_idx == layer_idx:
		return

	var z_values: Array = []
	var layer_weights: Array = _weights[layer_idx]
	for neuron_idx in range(layer_weights.size()):
		var neuron_weights: Array = layer_weights[neuron_idx]
		var neuron_bias: float = _get_neuron_bias(layer_idx, neuron_idx)
		z_values.append(Functions.compute_weighted_sum(_current_input_data, neuron_weights, neuron_bias))

	var a_values: Array = Functions.apply_activation_values(z_values, _activations[layer_idx])

	_cached_phase = "forward"
	_cached_layer_idx = layer_idx
	_cached_z_values = z_values
	_cached_a_values = a_values
	_cached_deltas = []


func _prepare_backward_cache(layer_idx: int) -> void:
	if _cached_phase == "backward" and _cached_layer_idx == layer_idx:
		return

	var next_layer_idx: int = _get_next_layer_index(layer_idx, _sorted_layer_indices)
	var next_deltas: Array = layer_deltas.get(next_layer_idx, [])
	var next_weights: Array = _backprop_weights_snapshot.get(next_layer_idx, [])
	var deltas: Array = compute_layer_deltas(
		layer_idx,
		_current_target_data,
		layer_outputs[layer_idx],
		layer_weighted_sums[layer_idx],
		_activations[layer_idx],
		_loss_type,
		next_deltas,
		next_weights,
		false
	)

	_cached_phase = "backward"
	_cached_layer_idx = layer_idx
	_cached_z_values = []
	_cached_a_values = []
	_cached_deltas = deltas


func _store_current_delta(layer_idx: int, neuron_idx: int, delta: float) -> void:
	if not layer_deltas.has(layer_idx):
		var deltas: Array = []
		deltas.resize(_cached_deltas.size())
		deltas.fill(0.0)
		layer_deltas[layer_idx] = deltas

	layer_deltas[layer_idx][neuron_idx] = delta


func _update_neuron_weights(layer_idx: int, neuron_idx: int, neuron_delta: float) -> void:
	var previous_layer_idx: int = _get_previous_layer_index(layer_idx, _weights.keys())
	var prev_outputs: Array = layer_outputs.get(previous_layer_idx, [])
	var layer_weights: Array = _weights.get(layer_idx, [])
	if neuron_idx < 0 or neuron_idx >= layer_weights.size():
		return

	var neuron_weights: Array = layer_weights[neuron_idx]
	for weight_idx in range(neuron_weights.size()):
		if weight_idx >= prev_outputs.size():
			break

		var gradient: float = neuron_delta * prev_outputs[weight_idx]
		neuron_weights[weight_idx] -= _learning_rate * gradient
		SignalsObserver.weight_updated.emit(layer_idx, neuron_idx, weight_idx, neuron_weights[weight_idx])

	_update_neuron_bias(layer_idx, neuron_idx, neuron_delta)
	_sync_weights_with_variables()


func _clear_layer_cache() -> void:
	_cached_phase = ""
	_cached_layer_idx = 0
	_cached_z_values = []
	_cached_a_values = []
	_cached_deltas = []


func _reset_runtime_state() -> void:
	layer_outputs.clear()
	layer_weighted_sums.clear()
	layer_deltas.clear()
	_backprop_weights_snapshot.clear()
	_current_layer_cursor = 0
	_current_neuron_cursor = 0
	_current_input_data = []
	_current_target_data = []
	_input_values_entered_for_current_sample = false
	_current_output_values.clear()
	_clear_layer_cache()


## Builds stable keys for output/expected visual labels. They are stringified
## neuron indices so regression and classification outputs share the same path.
func _get_output_value_keys() -> Array[String]:
	var output_keys: Array[String] = []
	var output_neurons: int = 0
	if _weights.has(-1):
		output_neurons = _weights[-1].size()

	for output_idx in range(output_neurons):
		output_keys.append(str(output_idx))

	return output_keys


## Clears every visual data column used by the network.
func _clear_all_eval_data() -> void:
	SignalsObserver.clear_nn_eval_data.emit("input")
	SignalsObserver.clear_nn_eval_data.emit("output")
	SignalsObserver.clear_nn_eval_data.emit("expected")


## True for state-machine phases that exist only to drive eval-data animations.
func _is_visual_transition_phase() -> bool:
	return _current_phase == "load_sample" or _current_phase == "compare_outputs" or _current_phase == "return_errors"


## True when the next forward advance will trigger the input-value "enter
## network" animation. Only Next Step waits for it; manual buttons still advance
## one operation per click.
func _should_wait_for_input_enter_on_next_advance() -> bool:
	return _current_phase == "forward" and not _input_values_entered_for_current_sample and not _is_completing_training


## Makes Next Step wait for visual animations, while Next Neuron and Next Layer
## can continue to advance one visual phase per click.
func _wait_for_visual_transition_if_needed(phase_before: String, should_wait_for_input_enter: bool) -> void:
	if phase_before == "load_sample":
		await _wait_for_eval_animation("input", "appear")
		await _wait_between_next_step_animations()
		return

	if should_wait_for_input_enter:
		await _wait_for_eval_animation("input", "enter_network")
		await _wait_between_next_step_animations()
		return

	match phase_before:
		"compare_outputs":
			await _wait_for_eval_animation("expected", "expected_to_error")
			await _wait_between_next_step_animations()
		"return_errors":
			await _wait_for_eval_animation("expected", "error_return")
			await _wait_between_next_step_animations()


## Waits for a role-specific animation-complete signal emitted by the visual
## container. Signals for other roles or animation names are ignored.
func _wait_for_eval_animation(container_role: String, animation_name: String) -> void:
	while true:
		var finished_info: Array = await SignalsObserver.nn_eval_data_animation_finished
		if finished_info.size() >= 2 and finished_info[0] == container_role and finished_info[1] == animation_name:
			return


## Adds breathing room between automatic Next Step animations. This delay is not
## used by Next Neuron or Next Layer, keeping manual stepping responsive.
func _wait_between_next_step_animations() -> void:
	if Constants.NN_EVAL_DATA_NEXT_STEP_DELAY <= 0.0:
		return

	await get_tree().create_timer(Constants.NN_EVAL_DATA_NEXT_STEP_DELAY).timeout


## Pushes trained weights and biases back into Variables.nn after each update.
## NeuralNetworkLogial stores typed dictionaries, so the generic training
## dictionaries are converted before assignment.
func _sync_weights_with_variables() -> void:
	Variables.nn.nn_tmp_dict = _to_typed_layer_array_dict(_weights)
	Variables.nn.nn_dict = _to_typed_layer_array_dict(_weights)
	Variables.nn.nn_bias_tmp_dict = _to_typed_layer_array_dict(_biases)
	Variables.nn.nn_bias_dict = _to_typed_layer_array_dict(_biases)


## Rebuilds a Dictionary[int, Array] from the untyped dictionaries used inside
## AlgorithmNn, keeping Godot 4.6 typed assignments valid.
func _to_typed_layer_array_dict(source: Dictionary) -> Dictionary[int, Array]:
	var typed_dict: Dictionary[int, Array] = {}
	for layer_idx in source.keys():
		var layer_value: Array = source[layer_idx]
		typed_dict[int(layer_idx)] = layer_value.duplicate(true)

	return typed_dict


func _is_training_finished() -> bool:
	return _current_phase == "finished" or _train_data.is_empty()


## Returns the active layer id for computational phases.
## Visual phases report the layer they conceptually belong to: load_sample to the
## input layer, and comparison/error-return to the output layer.
func _get_current_layer_idx() -> int:
	match _current_phase:
		"load_sample":
			return 0
		"compare_outputs", "return_errors":
			return -1
		"forward":
			if _current_layer_cursor >= 0 and _current_layer_cursor < _sorted_layer_indices.size():
				return _sorted_layer_indices[_current_layer_cursor]
		"backward":
			if _current_layer_cursor >= 0 and _current_layer_cursor < _reversed_layer_indices.size():
				return _reversed_layer_indices[_current_layer_cursor]
	return -9999


func _get_neuron_bias(layer_idx: int, neuron_idx: int) -> float:
	if not _biases.has(layer_idx):
		return 0.0

	var layer_biases: Array = _biases[layer_idx]
	if neuron_idx < 0 or neuron_idx >= layer_biases.size():
		return 0.0

	return float(layer_biases[neuron_idx])


func _update_neuron_bias(layer_idx: int, neuron_idx: int, neuron_delta: float) -> void:
	if not _biases.has(layer_idx):
		_biases[layer_idx] = _create_bias_vector(_weights.get(layer_idx, []).size())

	var layer_biases: Array = _biases[layer_idx]
	if neuron_idx < 0:
		return

	while neuron_idx >= layer_biases.size():
		layer_biases.append(Functions.random_connection_weight())

	var bias_gradient: float = neuron_delta
	layer_biases[neuron_idx] -= _learning_rate * bias_gradient


func _ensure_biases_match_weights(biases: Dictionary, weights: Dictionary) -> Dictionary:
	var synced_biases: Dictionary = biases

	for layer_idx in weights.keys():
		if layer_idx == 0:
			synced_biases.erase(layer_idx)
			continue

		var layer_weights: Array = weights[layer_idx]
		var layer_biases: Array = synced_biases.get(layer_idx, [])
		var synced_layer_biases: Array = []
		synced_layer_biases.resize(layer_weights.size())

		for neuron_idx in range(layer_weights.size()):
			if neuron_idx < layer_biases.size():
				synced_layer_biases[neuron_idx] = float(layer_biases[neuron_idx])
			else:
				synced_layer_biases[neuron_idx] = Functions.random_connection_weight()

		synced_biases[layer_idx] = synced_layer_biases

	var layers_to_remove: Array = []
	for layer_idx in synced_biases.keys():
		if layer_idx == 0 or not weights.has(layer_idx):
			layers_to_remove.append(layer_idx)

	for layer_idx in layers_to_remove:
		synced_biases.erase(layer_idx)

	return synced_biases


func _create_bias_vector(size: int) -> Array:
	var biases: Array = []
	biases.resize(max(size, 0))
	for i in range(biases.size()):
		biases[i] = Functions.random_connection_weight()
	return biases


# --- Helpe logic for dictionary keys ---

func _get_sorted_layer_indices(keys: Array) -> Array[int]:
	var hidden: Array[int] = []
	for k in keys:
		if k > 0:
			hidden.append(k)
	hidden.sort()
	if -1 in keys:
		hidden.append(-1)
	return hidden


func _get_previous_layer_index(current: int, all_keys: Array) -> int:
	if current == 1:
		return 0
	if current == -1:
		var max_hidden = 0
		for k in all_keys:
			if k > max_hidden:
				max_hidden = k
		return max_hidden
	return current - 1


func _get_next_layer_index(current: int, sorted_indices: Array) -> int:
	var idx = sorted_indices.find(current)
	if idx != -1 and idx + 1 < sorted_indices.size():
		return sorted_indices[idx + 1]
	return -1
