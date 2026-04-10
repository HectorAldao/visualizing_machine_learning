class_name AlgorithmNn extends Node

# Signals to hook into Godot's UI/Nodes for visualization
signal forward_step_completed(layer_idx, neuron_idx, output_value)
signal backward_step_completed(layer_idx, neuron_idx, delta_value)
signal weight_updated(layer_idx, neuron_idx, weight_idx, new_value)

# Intermediate states stored for backpropagation and visualization
var layer_outputs: Dictionary = {} # Store 'a' values (after activation)
var layer_weighted_sums: Dictionary = {} # Store 'z' values (before activation)

func train_step(
	weights: Dictionary, 
	activations: Dictionary, 
	input_data: Array, 
	target_data: Array, 
	learning_rate: float
) -> void:
	# 1. Forward Pass
	var final_output = perform_forward_propagation(weights, activations, input_data)
	
	# 2. Backward Pass (Gradient Descent)
	perform_backward_propagation(weights, activations, target_data, learning_rate)

# --- FORWARD PROPAGATION METHODS ---

func perform_forward_propagation(weights: Dictionary, activations: Dictionary, input_data: Array) -> Array:
	layer_outputs[0] = input_data
	
	# Get sorted hidden layers and ensure output layer (-1) is last
	var layer_indices = _get_sorted_layer_indices(weights.keys())
	
	var current_input = input_data
	for l_idx in layer_indices:
		var layer_results = compute_layer_forward(current_input, weights[l_idx], activations[l_idx], l_idx)
		layer_weighted_sums[l_idx] = layer_results["z"]
		layer_outputs[l_idx] = layer_results["a"]
		current_input = layer_results["a"]
		
	return current_input

func compute_layer_forward(inputs: Array, layer_weights: Array, activation_type: String, layer_idx: int) -> Dictionary:
	var z_values = []
	var a_values = []
	
	for i in range(layer_weights.size()):
		var neuron_weights = layer_weights[i]
		var z = compute_dot_product(inputs, neuron_weights)
		var a = apply_activation(z, activation_type)
		
		z_values.append(z)
		a_values.append(a)
		
		emit_signal("forward_step_completed", layer_idx, i, a)
		
	return {"z": z_values, "a": a_values}

func compute_dot_product(inputs: Array, neuron_weights: Array) -> float:
	var activation_sum = 0.0
	for i in range(inputs.size()):
		activation_sum += inputs[i] * neuron_weights[i]
	return activation_sum

# --- BACKWARD PROPAGATION METHODS ---

func perform_backward_propagation(weights: Dictionary, activations: Dictionary, target: Array, lr: float) -> void:
	var deltas = {}
	var layer_indices = _get_sorted_layer_indices(weights.keys())
	layer_indices.reverse() # Start from output layer
	
	for l_idx in layer_indices:
		var layer_deltas = []
		if l_idx == -1: # Output layer error
			layer_deltas = compute_output_layer_deltas(target, layer_outputs[-1], layer_weighted_sums[-1], activations[-1])
		else: # Hidden layer error
			var next_layer_idx = _get_next_layer_index(l_idx, layer_indices)
			layer_deltas = compute_hidden_layer_deltas(deltas[next_layer_idx], weights[next_layer_idx], layer_weighted_sums[l_idx], activations[l_idx])
		
		deltas[l_idx] = layer_deltas
		
		# Immediately update weights after calculating deltas for this layer (Stochastic approach)
		var prev_layer_idx = _get_previous_layer_index(l_idx, weights.keys())
		update_layer_weights(weights[l_idx], deltas[l_idx], layer_outputs[prev_layer_idx], lr, l_idx)

func compute_output_layer_deltas(target: Array, output: Array, z_values: Array, act_type: String) -> Array:
	var deltas = []
	for i in range(output.size()):
		# Partial derivative of MSE Loss: (output - target)
		var error_deriv = output[i] - target[i]
		var delta = error_deriv * apply_activation_derivative(z_values[i], act_type)
		deltas.append(delta)
		emit_signal("backward_step_completed", -1, i, delta)
	return deltas

func compute_hidden_layer_deltas(next_deltas: Array, next_weights: Array, z_values: Array, act_type: String) -> Array:
	var deltas = []
	var num_neurons = z_values.size()
	
	for i in range(num_neurons):
		var error_sum = 0.0
		for j in range(next_deltas.size()):
			# Weight of connection between current neuron i and next layer neuron j
			error_sum += next_weights[j][i] * next_deltas[j]
			
		var delta = error_sum * apply_activation_derivative(z_values[i], act_type)
		deltas.append(delta)
		emit_signal("backward_step_completed", 0, i, delta) # Simplified index for example
	return deltas

func update_layer_weights(layer_weights: Array, layer_deltas: Array, prev_outputs: Array, lr: float, l_idx: int) -> void:
	for i in range(layer_weights.size()):
		for j in range(layer_weights[i].size()):
			var gradient = layer_deltas[i] * prev_outputs[j]
			layer_weights[i][j] -= lr * gradient
			emit_signal("weight_updated", l_idx, i, j, layer_weights[i][j])

# --- MATH UTILITIES ---

func apply_activation(x: float, type: String) -> float:
	match type.to_lower():
		"sigmoid":
			return 1.0 / (1.0 + exp(-x))
		"relu":
			return max(0.0, x)
		"tanh":
			return (exp(x) - exp(-x)) / (exp(x) + exp(-x))
		_:
			return x # Identity

func apply_activation_derivative(x: float, type: String) -> float:
	match type.to_lower():
		"sigmoid":
			var s = apply_activation(x, "sigmoid")
			return s * (1.0 - s)
		"relu":
			return 1.0 if x > 0 else 0.0
		"tanh":
			var t = apply_activation(x, "tanh")
			return 1.0 - (t * t)
		_:
			return 1.0

# --- HELPER LOGIC FOR DICTIONARY KEYS ---

func _get_sorted_layer_indices(keys: Array) -> Array:
	var hidden = []
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
	return -1 # Should not happen during backprop reverse loop
