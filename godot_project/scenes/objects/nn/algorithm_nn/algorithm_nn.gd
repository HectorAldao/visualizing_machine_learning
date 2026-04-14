class_name AlgorithmNn extends Node

# Intermediate states stored for backpropagation and visualization
var layer_outputs: Dictionary = {} # Store 'a' values (after activation)
var layer_weighted_sums: Dictionary = {} # Store 'z' values (before activation)


func train_step(
	weights: Dictionary, 
	activations: Dictionary, 
	input_data: Array, 
	target_data: Array, 
	learning_rate: float,
	loss_type: int = Constants.LOSS_FUNCS.mse
) -> void:
	# Forward Pass
	var output_data: Array = perform_forward_propagation(weights, activations, input_data)

	print("[LOG] the output for input data was %s" % output_data)
	
	# Backward
	perform_backward_propagation(weights, activations, target_data, learning_rate, loss_type)


# --- Forward methods ---

## Pass the output of each layer for the next one in order
func perform_forward_propagation(weights: Dictionary, activations: Dictionary, input_data: Array) -> Array:
	layer_outputs[0] = input_data
	
	# Get sorted hidden layers and ensure output layer (-1) is last
	# for the for_loop
	var layer_indices: Array[int] = _get_sorted_layer_indices(weights.keys())
	
	var current_input: Array[float] = input_data
	# Compute for each layer, the forward step
	# updating the "current" input variable
	for l_idx in layer_indices:
		var layer_results: Dictionary[String, Array] = compute_layer_forward(current_input, weights[l_idx], activations[l_idx], l_idx)
		layer_weighted_sums[l_idx] = layer_results["z"]
		layer_outputs[l_idx] = layer_results["a"]
		current_input = layer_results["a"]
		
	return current_input


## Pass a input of a layer
func compute_layer_forward(inputs: Array, layer_weights: Array, activation_type: int, layer_idx: int) -> Dictionary:
	
	# To save the raw output
	var z_values: Array = []
	# To save the activation function output 
	var a_values: Array = []
	
	# Compute the raw ouput
	for i in range(layer_weights.size()):
		var neuron_weights: Array[Array] = layer_weights[i]
		var z: float = compute_dot_product(inputs, neuron_weights)
		
		z_values.append(z)
	
	# Apply the activation function
	if _is_softmax_activation(activation_type):
		a_values = _apply_softmax(z_values)
	else:
		for i in range(z_values.size()):
			var neuron_output: float = apply_activation(z_values[i], activation_type)
			SignalsObserver.forward_step_completed.emit(layer_idx, i, neuron_output)
			a_values.append(neuron_output)

	return {"z": z_values, "a": a_values}



# --- Backward methods ---

## Update the weights basen on the error of the output
func perform_backward_propagation(
	weights: Dictionary,
	activations: Dictionary,
	target: Array,
	lr: float,
	loss_type: int = Constants.LOSS_FUNCS.mse
) -> void:

	# Save the gradient for each layer
	var deltas: Dictionary = {}
	var layer_indices: Array[int] = _get_sorted_layer_indices(weights.keys())
	layer_indices.reverse()  # Start from output layer
	
	# For each layer, compute its gradient, save it in the dictionary
	# and update de weights of the layer
	for l_idx in layer_indices:

		# Compute the gradient
		var next_layer_idx: int = _get_next_layer_index(l_idx, layer_indices)
		var next_deltas: Array[float] = deltas.get(next_layer_idx, [])  # If the layer is -1, returns []
		var next_weights: Array = weights.get(next_layer_idx, [])  # If the layer is -1, returns []

		var layer_deltas: Array[float] = compute_layer_deltas(
			l_idx,
			target,
			layer_outputs[l_idx],
			layer_weighted_sums[l_idx],
			activations[l_idx],
			loss_type,
			next_deltas,
			next_weights
		)
		
		# Save it
		deltas[l_idx] = layer_deltas
		
		# Immediately update weights after calculating deltas for this layer (stochastic approach)
		var prev_layer_idx = _get_previous_layer_index(l_idx, weights.keys())
		update_layer_weights(weights[l_idx], deltas[l_idx], layer_outputs[prev_layer_idx], lr, l_idx)


## Calculates deltas for both output and hidden layers.
## Output layer is handled as a special case internally.
func compute_layer_deltas(
	layer_idx: int,
	target: Array,
	output_values: Array,
	z_values: Array,
	act_type: int,
	loss_type: int,
	next_deltas: Array,
	next_weights: Array
) -> Array[float]:

	var num_neurons: int = z_values.size()
	var upstream_gradients: Array[float] = []
	upstream_gradients.resize(num_neurons)

	# Calculate gradient that reaches this layer
	if layer_idx == -1:
		# For softmax + cross entropy, gradient wrt logits is (output - target).
		if _is_softmax_activation(act_type) and loss_type == Constants.LOSS_FUNCS.coss_entr:
			var output_deltas: Array[float] = []
			for i in range(num_neurons):
				var output_delta: float = output_values[i] - target[i]
				output_deltas.append(output_delta)
				SignalsObserver.backward_step_completed.emit(layer_idx, i, output_delta)
			return output_deltas

		upstream_gradients = _compute_output_loss_error(output_values, target, loss_type)
	else:
		# Chain rule: d f(g(x)) / dx = d g(x) / dx * d f(g(x)) / dg(x) 
		for i in range(num_neurons):
			var error_sum: float = 0.0
			for j in range(next_deltas.size()):
				error_sum += next_weights[j][i] * next_deltas[j]
			upstream_gradients[i] = error_sum

	# Calculate softmax if is needed
	if _is_softmax_activation(act_type):
		var current_output = output_values if layer_idx == -1 else _apply_activation_values(z_values, act_type)
		return _apply_softmax_backprop(current_output, upstream_gradients, layer_idx)

	# Apply derivate neuron to neuron if is not softmax
	var deltas: Array[float] = []
	for i in range(num_neurons):
		var delta: float = upstream_gradients[i] * apply_activation_derivative(z_values[i], act_type)
		deltas.append(delta)
		SignalsObserver.backward_step_completed.emit(layer_idx, i, delta)

	return deltas


func _compute_output_loss_error(output_values: Array, target: Array, loss_type: int) -> Array[float]:
	var output_error: Array[float] = []
	var num_neurons: int = output_values.size()

	match loss_type:
		Constants.LOSS_FUNCS.mse:
			for i in range(num_neurons):
				output_error.append(output_values[i] - target[i])
		Constants.LOSS_FUNCS.coss_entr:
			var epsilon: float = 1e-8
			for i in range(num_neurons):
				var safe_output: float = max(output_values[i], epsilon)
				output_error.append(-target[i] / safe_output)
		_:
			for i in range(num_neurons):
				output_error.append(output_values[i] - target[i])

	return output_error


func update_layer_weights(layer_weights: Array, layer_deltas: Array, prev_outputs: Array, lr: float, l_idx: int) -> void:
	for i in range(layer_weights.size()):
		for j in range(layer_weights[i].size()):
			var gradient = layer_deltas[i] * prev_outputs[j]
			layer_weights[i][j] -= lr * gradient
			SignalsObserver.weight_updated.emit(l_idx, i, j, layer_weights[i][j])


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
		#"tanh":
		#	return (exp(x) - exp(-x)) / (exp(x) + exp(-x))
		_:
			return x # Identity

func apply_activation_derivative(x: float, type: int) -> float:
	match type:
		Constants.ACT_FUNCS.relu:
			return 1.0 if x > 0 else 0.0
		Constants.ACT_FUNCS.sigmoid:
			var s = apply_activation(x, Constants.ACT_FUNCS.sigmoid)
			return s * (1.0 - s)
		Constants.ACT_FUNCS.softmax:
			return 1.0
		#"tanh":
		#	var t = apply_activation(x, "tanh")
		#	return 1.0 - (t * t)
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


func _apply_softmax_backprop(activated_values: Array, upstream_gradients: Array, layer_idx: int) -> Array:
	var deltas: Array = []
	deltas.resize(activated_values.size())

	var dot_product: float = 0.0
	for i in range(activated_values.size()):
		dot_product += upstream_gradients[i] * activated_values[i]

	for i in range(activated_values.size()):
		var delta: float = activated_values[i] * (upstream_gradients[i] - dot_product)
		deltas[i] = delta
		SignalsObserver.backward_step_completed.emit(layer_idx, i, delta)

	return deltas



# --- Helpe logic for dictionary keys ---

func _get_sorted_layer_indices(keys: Array[int]) -> Array[int]:
	var hidden: Array[int] = []
	for k in keys:
		if k > 0: hidden.append(k)
	hidden.sort()
	if -1 in keys: hidden.append(-1)
	return hidden

func _get_previous_layer_index(current: int, all_keys: Array) -> int:
	if current == 1: return 0
	if current == -1:
		var max_hidden = 0
		for k in all_keys:
			if k > max_hidden: max_hidden = k
		return max_hidden
	return current - 1

func _get_next_layer_index(current: int, sorted_indices: Array) -> int:
	var idx = sorted_indices.find(current)
	if idx != -1 and idx + 1 < sorted_indices.size():
		return sorted_indices[idx + 1]
	return -1
