class_name AlgorithmNn extends Node


# Nn related variables

# Weights of the network, its going to be updated on each 
var _weights: Dictionary = {}
# Activacion function for each layer
var _activations: Dictionary = {}
# The data used to train the nn
var _train_data: Array[Dictionary] = []
# The input atributes
var _train_attributes: Array[String] = []
# Tht names on the output neurons
var _target_attributes: Array[String] = []

# Learning rate
var _learning_rate: float = 0.01
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

var _cached_phase: String = ""
var _cached_layer_idx: int = 0
var _cached_z_values: Array = []
var _cached_a_values: Array = []
var _cached_deltas: Array = []


func _ready() -> void:
	# Connect the signals related to the buttons in panel_algorithm_nn
	SignalsObserver.train_nn_next_neuron.connect(train_next_neuron)
	SignalsObserver.train_nn_next_layer.connect(train_next_layer)
	SignalsObserver.train_nn_next_step.connect(train_next_step)
	SignalsObserver.train_nn_complete.connect(train_complete)


# func train_step(
# 	weights: Dictionary,
# 	activations: Dictionary,
# 	input_data: Array,
# 	target_data: Array,
# 	learning_rate: float,
# 	loss_type: int = Constants.LOSS_FUNCS.mse
# ) -> void:
# 	var output_data: Array = perform_forward_propagation(weights, activations, input_data)
# 	print("[LOG] the output for input data was %s" % output_data)
# 	perform_backward_propagation(weights, activations, target_data, learning_rate, loss_type)


## Prepares the variables for the training
func configure_training(
	train_data: Array[Dictionary],
	train_attributes: Array[String],
	target_attributes: Array[String],
	weights: Dictionary,
	activations: Dictionary,
	learning_rate: float,
	loss_type: int = Constants.LOSS_FUNCS.mse
) -> void:

	_train_data = train_data.duplicate(true)
	_train_attributes = train_attributes.duplicate()
	_target_attributes = target_attributes.duplicate()
	_weights = weights
	_activations = activations
	_learning_rate = learning_rate
	_loss_type = loss_type
	_sorted_layer_indices = _get_sorted_layer_indices(_weights.keys())
	_reversed_layer_indices = _sorted_layer_indices.duplicate()
	_reversed_layer_indices.reverse()
	_current_data_idx = 0
	_current_phase = "idle"
	_reset_runtime_state()

	if _train_data.is_empty() or _target_attributes.is_empty():
		_current_phase = "finished"
		return

	_prepare_current_sample()


func train_next_neuron(_neuron_id: int = -1, _layer_id: int = -9999) -> void:
	_advance_one_neuron()


func train_next_layer(_layer_id: int = -9999) -> void:
	if _is_training_finished():
		return

	var phase_before: String = _current_phase
	var layer_before: int = _get_current_layer_idx()

	while not _is_training_finished() and _current_phase == phase_before and _get_current_layer_idx() == layer_before:
		if not _advance_one_neuron():
			break


func train_next_step() -> void:
	if _is_training_finished():
		return

	var data_before: int = _current_data_idx

	while not _is_training_finished() and _current_data_idx == data_before:
		if not _advance_one_neuron():
			break


func train_complete() -> void:
	while not _is_training_finished():
		if not _advance_one_neuron():
			break


# --- Forward methods ---

## Pass the output of each layer for the next one in order
# func perform_forward_propagation(weights: Dictionary, activations: Dictionary, input_data: Array) -> Array:
# 	layer_outputs[0] = input_data
# 
# 	var layer_indices: Array[int] = _get_sorted_layer_indices(weights.keys())
# 	var current_input: Array[float] = input_data
# 
# 	for l_idx in layer_indices:
# 		var layer_results: Dictionary[String, Array] = compute_layer_forward(current_input, weights[l_idx], activations[l_idx], l_idx)
# 		layer_weighted_sums[l_idx] = layer_results["z"]
# 		layer_outputs[l_idx] = layer_results["a"]
# 		current_input = layer_results["a"]
# 
# 	return current_input


## Pass a input of a layer
# func compute_layer_forward(inputs: Array, layer_weights: Array, activation_type: int, layer_idx: int) -> Dictionary:
# 	var z_values: Array = []
# 	var a_values: Array = []
# 
# 	for i in range(layer_weights.size()):
# 		var neuron_weights: Array[Array] = layer_weights[i]
# 		var z: float = compute_dot_product(inputs, neuron_weights)
# 		z_values.append(z)
# 
# 	if _is_softmax_activation(activation_type):
# 		a_values = _apply_softmax(z_values)
# 		for i in range(a_values.size()):
# 			SignalsObserver.forward_step_completed.emit(layer_idx, i, a_values[i])
# 	else:
# 		for i in range(z_values.size()):
# 			var neuron_output: float = apply_activation(z_values[i], activation_type)
# 			SignalsObserver.forward_step_completed.emit(layer_idx, i, neuron_output)
# 			a_values.append(neuron_output)
# 
# 	return {"z": z_values, "a": a_values}


# --- Backward methods ---

## Update the weights basen on the error of the output
# func perform_backward_propagation(
# 	weights: Dictionary,
# 	activations: Dictionary,
# 	target: Array,
# 	lr: float,
# 	loss_type: int = Constants.LOSS_FUNCS.mse
# ) -> void:
# 	var deltas: Dictionary = {}
# 	var forward_layer_indices: Array[int] = _get_sorted_layer_indices(weights.keys())
# 	var backward_layer_indices: Array[int] = forward_layer_indices.duplicate()
# 	backward_layer_indices.reverse()
# 	var weights_snapshot: Dictionary = weights.duplicate(true)
# 
# 	for l_idx in backward_layer_indices:
# 		var next_layer_idx: int = _get_next_layer_index(l_idx, forward_layer_indices)
# 		var next_deltas: Array[float] = deltas.get(next_layer_idx, [])
# 		var next_weights: Array = weights_snapshot.get(next_layer_idx, [])
# 
# 		var current_layer_deltas: Array[float] = compute_layer_deltas(
# 			l_idx,
# 			target,
# 			layer_outputs[l_idx],
# 			layer_weighted_sums[l_idx],
# 			activations[l_idx],
# 			loss_type,
# 			next_deltas,
# 			next_weights
# 		)
# 
# 		deltas[l_idx] = current_layer_deltas
# 		var prev_layer_idx = _get_previous_layer_index(l_idx, weights.keys())
# 		update_layer_weights(weights[l_idx], current_layer_deltas, layer_outputs[prev_layer_idx], lr, l_idx)


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
		if _is_softmax_activation(act_type) and loss_type == Constants.LOSS_FUNCS.coss_entr:
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
		upstream_gradients = _compute_output_loss_error(output_values, target, loss_type)

	# If its not the last layer
	else:
		for i in range(num_neurons):
			var error_sum: float = 0.0
			for j in range(next_deltas.size()):
				error_sum += next_weights[j][i] * next_deltas[j]
			upstream_gradients[i] = error_sum

	if _is_softmax_activation(act_type):
		var current_output = output_values if layer_idx == -1 else _apply_activation_values(z_values, act_type)
		return _apply_softmax_backprop(current_output, upstream_gradients, layer_idx, emit_signals)

	var deltas: Array[float] = []
	for i in range(num_neurons):
		var delta: float = upstream_gradients[i] * apply_activation_derivative(z_values[i], act_type)
		deltas.append(delta)
		if emit_signals:
			SignalsObserver.backward_step_completed.emit(layer_idx, i, delta)

	return deltas


## Computes the loss based on the specified loss function
##
## Returns an Array of the error of each neuron
func _compute_output_loss_error(output_values: Array, target: Array, loss_type: int) -> Array[float]:

	var output_error: Array[float] = []
	var num_neurons: int = output_values.size()

	# Each loss_func calculates the loss in a different way
	match loss_type:

		# MSE
		Constants.LOSS_FUNCS.mse:
			for i in range(num_neurons):
				output_error.append(output_values[i] - target[i])

		# Cross entropy
		Constants.LOSS_FUNCS.coss_entr:
			var epsilon: float = 1e-8
			for i in range(num_neurons):
				var safe_output: float = max(output_values[i], epsilon)
				output_error.append(-target[i] / safe_output)
		_:
			for i in range(num_neurons):
				output_error.append(output_values[i] - target[i])

	return output_error


# func update_layer_weights(layer_weights: Array, current_layer_deltas: Array, prev_outputs: Array, lr: float, l_idx: int) -> void:
# 	for i in range(layer_weights.size()):
# 		for j in range(layer_weights[i].size()):
# 			var gradient = current_layer_deltas[i] * prev_outputs[j]
# 			layer_weights[i][j] -= lr * gradient
# 			SignalsObserver.weight_updated.emit(l_idx, i, j, layer_weights[i][j])


# --- Incremental training flow ---

func _advance_one_neuron() -> bool:
	if _is_training_finished():
		return false

	match _current_phase:
		"forward":
			return _advance_forward_neuron()
		"backward":
			return _advance_backward_neuron()
		_:
			return false


func _advance_forward_neuron() -> bool:
	var layer_idx: int = _get_current_layer_idx()
	if layer_idx == -9999:
		return false

	_prepare_forward_cache(layer_idx)

	var neuron_output: float = _cached_a_values[_current_neuron_cursor]
	SignalsObserver.forward_step_completed.emit(layer_idx, _current_neuron_cursor, neuron_output)

	_current_neuron_cursor += 1
	if _current_neuron_cursor >= _cached_a_values.size():
		layer_weighted_sums[layer_idx] = _cached_z_values.duplicate(true)
		layer_outputs[layer_idx] = _cached_a_values.duplicate(true)
		_current_input_data = _cached_a_values.duplicate(true)
		_current_layer_cursor += 1
		_current_neuron_cursor = 0
		_clear_layer_cache()

		if _current_layer_cursor >= _sorted_layer_indices.size():
			_current_phase = "backward"
			_current_layer_cursor = 0
			_backprop_weights_snapshot = _weights.duplicate(true)

	return true


func _advance_backward_neuron() -> bool:
	var layer_idx: int = _get_current_layer_idx()
	if layer_idx == -9999:
		return false

	_prepare_backward_cache(layer_idx)

	var delta: float = _cached_deltas[_current_neuron_cursor]
	SignalsObserver.backward_step_completed.emit(layer_idx, _current_neuron_cursor, delta)
	_store_current_delta(layer_idx, _current_neuron_cursor, delta)
	_update_neuron_weights(layer_idx, _current_neuron_cursor, delta)

	_current_neuron_cursor += 1
	if _current_neuron_cursor >= _cached_deltas.size():
		_current_layer_cursor += 1
		_current_neuron_cursor = 0
		_clear_layer_cache()

		if _current_layer_cursor >= _reversed_layer_indices.size():
			_finish_current_sample()

	return true


func _prepare_current_sample() -> void:
	_reset_runtime_state()

	if _current_data_idx < 0 or _current_data_idx >= _train_data.size():
		_current_phase = "finished"
		return

	var row: Dictionary = _train_data[_current_data_idx]
	_current_input_data = _extract_input_data(row)
	_current_target_data = _extract_target_data(row)
	layer_outputs[0] = _current_input_data.duplicate(true)
	_current_phase = "forward"


func _finish_current_sample() -> void:
	_sync_weights_with_variables()
	_current_data_idx += 1

	if _current_data_idx >= _train_data.size():
		_current_phase = "finished"
		print("[LOG] NN training completed")
		return

	_prepare_current_sample()


func _extract_input_data(row: Dictionary) -> Array:
	var input_data: Array = []
	for attr in _train_attributes:
		input_data.append(float(row.get(attr, 0.0)))
	return input_data


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


func _prepare_forward_cache(layer_idx: int) -> void:
	if _cached_phase == "forward" and _cached_layer_idx == layer_idx:
		return

	var z_values: Array = []
	var layer_weights: Array = _weights[layer_idx]
	for neuron_weights in layer_weights:
		z_values.append(compute_dot_product(_current_input_data, neuron_weights))

	var a_values: Array = []
	if _is_softmax_activation(_activations[layer_idx]):
		a_values = _apply_softmax(z_values)
	else:
		for z in z_values:
			a_values.append(apply_activation(z, _activations[layer_idx]))

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

	Variables.nn.nn_tmp_dict = _weights
	Variables.nn.nn_dict = _weights.duplicate(true)


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
	_clear_layer_cache()


func _sync_weights_with_variables() -> void:
	Variables.nn.nn_tmp_dict = _weights
	Variables.nn.nn_dict = _weights.duplicate(true)


func _is_training_finished() -> bool:
	return _current_phase == "finished" or _train_data.is_empty()


func _get_current_layer_idx() -> int:
	match _current_phase:
		"forward":
			if _current_layer_cursor >= 0 and _current_layer_cursor < _sorted_layer_indices.size():
				return _sorted_layer_indices[_current_layer_cursor]
		"backward":
			if _current_layer_cursor >= 0 and _current_layer_cursor < _reversed_layer_indices.size():
				return _reversed_layer_indices[_current_layer_cursor]
	return -9999


# --- Math utilities ---

## [x, y, z] * [a, b, c] = x*a + y*b + z*c
## Interior product
func compute_dot_product(inputs: Array, neuron_weights: Array) -> float:
	var activation_sum: float = 0.0
	for i in range(inputs.size()):
		activation_sum += inputs[i] * neuron_weights[i]
	return activation_sum


func apply_activation(x: float, type: int) -> float:
	match type:
		Constants.ACT_FUNCS.relu:
			return max(0.0, x)
		Constants.ACT_FUNCS.sigmoid:
			return 1.0 / (1.0 + exp(-x))
		Constants.ACT_FUNCS.softmax:
			return x
		_:
			return x


func apply_activation_derivative(x: float, type: int) -> float:
	match type:
		Constants.ACT_FUNCS.relu:
			return 1.0 if x > 0 else 0.0
		Constants.ACT_FUNCS.sigmoid:
			var s = apply_activation(x, Constants.ACT_FUNCS.sigmoid)
			return s * (1.0 - s)
		Constants.ACT_FUNCS.softmax:
			return 1.0
		_:
			return 1.0


## True if the type is softmax
func _is_softmax_activation(type: int) -> bool:
	return type == Constants.ACT_FUNCS.softmax


## Processes the output of a layer based on its activation function
func _apply_activation_values(z_values: Array, activation_type: int) -> Array:
	if activation_type == Constants.ACT_FUNCS.softmax:
		return _apply_softmax(z_values)

	var activated_values: Array = []
	for z in z_values:
		activated_values.append(apply_activation(z, activation_type))
	return activated_values


## Separated calculation of softmax because its complex enough
## to warrant its own function
func _apply_softmax(z_values: Array) -> Array:
	var softmax_values: Array = []
	softmax_values.resize(z_values.size())

	if z_values.is_empty():
		return softmax_values

	var max_z: float = z_values[0]
	for z in z_values:
		if z > max_z:
			max_z = z

	var exponent_sum: float = 0.0
	for z in z_values:
		exponent_sum += exp(z - max_z)

	if exponent_sum == 0.0:
		return softmax_values

	for i in range(z_values.size()):
		softmax_values[i] = exp(z_values[i] - max_z) / exponent_sum

	return softmax_values


func _apply_softmax_backprop(activated_values: Array, upstream_gradients: Array, layer_idx: int, emit_signals: bool = true) -> Array:
	var deltas: Array = []
	deltas.resize(activated_values.size())

	var dot_product: float = 0.0
	for i in range(activated_values.size()):
		dot_product += upstream_gradients[i] * activated_values[i]

	for i in range(activated_values.size()):
		var delta: float = activated_values[i] * (upstream_gradients[i] - dot_product)
		deltas[i] = delta
		if emit_signals:
			SignalsObserver.backward_step_completed.emit(layer_idx, i, delta)

	return deltas


# --- Helpe logic for dictionary keys ---

func _get_sorted_layer_indices(keys: Array[int]) -> Array[int]:
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
