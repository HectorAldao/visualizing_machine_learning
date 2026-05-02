class_name NNEFExporter
extends RefCounted


const ACTIVATIONS: Dictionary = {
	0: "relu",
	1: "sigmoid",
	2: "softmax",
	3: "identity",
}


func export_to_nnef(path: String, weights: Dictionary, biases: Dictionary, activations: Dictionary) -> void:
	var layer_ids := _get_computational_layer_ids(weights.keys())
	if layer_ids.is_empty():
		push_error("No hay capas exportables en la red.")
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo crear el archivo NNEF")
		return

	var input_size := _get_input_size(weights, layer_ids)
	var output_weights: Array = weights[layer_ids[-1]]
	var output_size := output_weights.size()

	file.store_line("version 1.0;")
	file.store_line("# godot_nn_metadata = %s" % JSON.stringify({
		"weights": weights,
		"biases": biases,
		"activations": activations,
	}))
	file.store_line("")
	file.store_line("graph network(input: tensor<1, %d>) -> (output: tensor<1, %d>)" % [input_size, output_size])
	file.store_line("{")

	var last_tensor_name := "input"
	for layer_id in layer_ids:
		var layer_weights: Array = weights[layer_id]
		if layer_weights.is_empty() or not (layer_weights[0] is Array):
			continue

		var rows := layer_weights.size()
		var cols := (layer_weights[0] as Array).size()
		var suffix := "out" if layer_id == -1 else str(layer_id)
		var weight_name := "w_%s" % suffix
		var bias_name := "b_%s" % suffix
		var matmul_output := "m_%s" % suffix
		var linear_output := "z_%s" % suffix
		var activation_output := "output" if layer_id == layer_ids[-1] else "a_%s" % suffix

		file.store_line("\t%s = constant<%d, %d>(data = [%s]);" % [
			weight_name,
			rows,
			cols,
			_join_float_array(_flatten_matrix(layer_weights)),
		])
		file.store_line("\t%s = constant<%d>(data = [%s]);" % [
			bias_name,
			rows,
			_join_float_array(_get_layer_biases(biases, layer_id, rows)),
		])
		file.store_line("\t%s = matmul(%s, transpose(%s));" % [matmul_output, last_tensor_name, weight_name])
		file.store_line("\t%s = add(%s, %s);" % [linear_output, matmul_output, bias_name])

		var act_func: String = ACTIVATIONS.get(int(activations.get(layer_id, Constants.ACT_FUNCS.identity)), "identity")
		if act_func == "identity":
			file.store_line("\t%s = %s;" % [activation_output, linear_output])
		else:
			file.store_line("\t%s = %s(%s);" % [activation_output, act_func, linear_output])

		last_tensor_name = activation_output

	file.store_line("}")
	file.close()
	print("Archivo NNEF exportado exitosamente en: ", path)


func _get_computational_layer_ids(keys: Array) -> Array[int]:
	var hidden_layers: Array[int] = []
	var has_output := false

	for key in keys:
		var layer_id := int(key)
		if layer_id == 0:
			continue
		if layer_id == -1:
			has_output = true
		elif layer_id > 0:
			hidden_layers.append(layer_id)

	hidden_layers.sort()
	if has_output:
		hidden_layers.append(-1)
	return hidden_layers


func _get_input_size(weights: Dictionary, layer_ids: Array[int]) -> int:
	if weights.has(0):
		var input_layer: Array = weights[0]
		if not input_layer.is_empty():
			return input_layer.size()

	if not layer_ids.is_empty() and weights.has(layer_ids[0]):
		var first_weights: Array = weights[layer_ids[0]]
		if not first_weights.is_empty() and first_weights[0] is Array:
			return (first_weights[0] as Array).size()

	return 1


func _get_layer_biases(biases: Dictionary, layer_id: int, target_size: int) -> Array:
	var layer_biases: Array = biases.get(layer_id, [])
	var result: Array = []
	result.resize(max(target_size, 0))

	for bias_idx in range(result.size()):
		if bias_idx < layer_biases.size():
			result[bias_idx] = float(layer_biases[bias_idx])
		else:
			result[bias_idx] = 0.0

	return result


func _flatten_matrix(matrix: Array) -> Array:
	var flat: Array = []
	for row in matrix:
		if row is Array:
			for value in row:
				flat.append(float(value))
	return flat


func _join_float_array(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(float(value)))
	return ", ".join(parts)
