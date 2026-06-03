extends Node


func compute_dot_product(inputs: Array, weights: Array) -> float:
	var result: float = 0.0
	for i in range(min(inputs.size(), weights.size())):
		result += float(inputs[i]) * float(weights[i])
	return result


func compute_weighted_sum(inputs: Array, weights: Array, bias: float) -> float:
	return compute_dot_product(inputs, weights) + bias


func random_connection_weight() -> float:
	return Constants.NN_CONNECTION_RANDOM_MULT * randfn(Constants.NN_CONNECTION_RANDOM_MEAN, sqrt(Constants.NN_CONNECTION_VARIANCE))


func relu(x: float) -> float:
	return max(0.0, x)


func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))


func apply_activation(x: float, activation_type: int) -> float:
	match activation_type:
		Constants.ACT_FUNCS.relu:
			return relu(x)
		Constants.ACT_FUNCS.sigmoid:
			return sigmoid(x)
		Constants.ACT_FUNCS.softmax:
			return x
		_:
			return x


func apply_activation_derivative(x: float, activation_type: int) -> float:
	match activation_type:
		Constants.ACT_FUNCS.relu:
			return 1.0 if x > 0.0 else 0.0
		Constants.ACT_FUNCS.sigmoid:
			var sigmoid_value: float = sigmoid(x)
			return sigmoid_value * (1.0 - sigmoid_value)
		Constants.ACT_FUNCS.softmax:
			return 1.0
		_:
			return 1.0


func is_softmax_activation(activation_type: int) -> bool:
	return activation_type == Constants.ACT_FUNCS.softmax


func apply_activation_values(z_values: Array, activation_type: int) -> Array:
	if is_softmax_activation(activation_type):
		return apply_softmax(z_values)

	var activated_values: Array = []
	for z in z_values:
		activated_values.append(apply_activation(float(z), activation_type))
	return activated_values


func apply_softmax(z_values: Array) -> Array:
	var softmax_values: Array = []
	softmax_values.resize(z_values.size())

	if z_values.is_empty():
		return softmax_values

	var max_z: float = float(z_values[0])
	for z in z_values:
		max_z = max(max_z, float(z))

	var exponent_sum: float = 0.0
	for z in z_values:
		exponent_sum += exp(float(z) - max_z)

	if exponent_sum == 0.0:
		return softmax_values

	for i in range(z_values.size()):
		softmax_values[i] = exp(float(z_values[i]) - max_z) / exponent_sum

	return softmax_values


func apply_softmax_backprop(activated_values: Array, upstream_gradients: Array) -> Array[float]:
	var deltas: Array[float] = []
	deltas.resize(activated_values.size())

	var dot_product: float = 0.0
	for i in range(min(activated_values.size(), upstream_gradients.size())):
		dot_product += float(upstream_gradients[i]) * float(activated_values[i])

	for i in range(activated_values.size()):
		var upstream_gradient: float = float(upstream_gradients[i]) if i < upstream_gradients.size() else 0.0
		deltas[i] = float(activated_values[i]) * (upstream_gradient - dot_product)

	return deltas


func compute_output_loss_error(output_values: Array, target_values: Array, loss_type: int) -> Array[float]:
	var output_error: Array[float] = []

	for i in range(output_values.size()):
		var output_value: float = float(output_values[i])
		var target_value: float = float(target_values[i]) if i < target_values.size() else 0.0
		match loss_type:
			Constants.LOSS_FUNCS.coss_entr:
				var safe_output: float = max(output_value, Constants.NN_LOSS_EPSILON)
				output_error.append(-target_value / safe_output)
			_:
				output_error.append(output_value - target_value)

	return output_error


func compute_loss_value(output_values: Array, target_values: Array, loss_type: int) -> float:
	var terms_count: int = min(output_values.size(), target_values.size())
	if terms_count <= 0:
		return 0.0

	match loss_type:
		Constants.LOSS_FUNCS.coss_entr:
			var loss_sum: float = 0.0
			for i in range(terms_count):
				loss_sum -= float(target_values[i]) * log(max(float(output_values[i]), Constants.NN_LOSS_EPSILON))
			return loss_sum
		_:
			var squared_error_sum: float = 0.0
			for i in range(terms_count):
				var error: float = float(output_values[i]) - float(target_values[i])
				squared_error_sum += error * error
			return squared_error_sum / float(terms_count)


func count_values(values: Array) -> Dictionary:
	var counts: Dictionary = {}
	for value in values:
		if not counts.has(value):
			counts[value] = 0
		counts[value] += 1
	return counts


func compute_entropy(labels: Array) -> float:
	if labels.is_empty():
		return 0.0

	var log_base: float = log(Constants.DTREE_ENTROPY_LOG_BASE)
	if is_zero_approx(log_base):
		return 0.0

	var total: int = labels.size()
	var entropy_value: float = 0.0
	for count in count_values(labels).values():
		var probability: float = float(count) / float(total)
		if probability > 0.0:
			entropy_value -= probability * log(probability) / log_base

	return entropy_value
