class_name ONNXExporter
extends RefCounted


const ACTIVATION_MAP: Dictionary = {
	0: "Relu",
	1: "Sigmoid",
	2: "Softmax",
	3: "Identity",
}

const TENSOR_FLOAT: int = 1
const ONNX_OPSET_VERSION: int = 13


func export_network(weights: Dictionary, biases: Dictionary, activations: Dictionary, file_path: String) -> void:
	var layer_ids := _get_computational_layer_ids(weights.keys())
	if layer_ids.is_empty():
		push_error("No hay capas exportables en la red.")
		return

	var input_size := _get_input_size(weights, layer_ids)
	var nodes: Array[Dictionary] = []
	var initializers: Array[Dictionary] = []
	var previous_tensor := "input"

	for layer_id in layer_ids:
		var layer_weights: Array = weights[layer_id]
		if layer_weights.is_empty() or not (layer_weights[0] is Array):
			continue

		var rows := layer_weights.size()
		var cols := (layer_weights[0] as Array).size()
		var weight_name := _tensor_name("W", layer_id)
		var bias_name := _tensor_name("B", layer_id)
		var linear_output := _tensor_name("linear", layer_id)
		var layer_output := "output" if layer_id == layer_ids[-1] else _tensor_name("act", layer_id)

		initializers.append({
			"name": weight_name,
			"dims": [rows, cols],
			"data": _flatten_matrix(layer_weights),
		})
		initializers.append({
			"name": bias_name,
			"dims": [rows],
			"data": _get_layer_biases(biases, layer_id, rows),
		})

		nodes.append({
			"name": _tensor_name("Gemm", layer_id),
			"op_type": "Gemm",
			"inputs": [previous_tensor, weight_name, bias_name],
			"outputs": [linear_output],
			"attributes": {
				"alpha": 1.0,
				"beta": 1.0,
				"transA": 0,
				"transB": 1,
			},
		})

		var activation_id: int = int(activations.get(layer_id, Constants.ACT_FUNCS.identity))
		var activation_op: String = ACTIVATION_MAP.get(activation_id, "Identity")
		if activation_op == "Identity":
			if layer_output == "output":
				nodes.append({
					"name": _tensor_name("Identity", layer_id),
					"op_type": "Identity",
					"inputs": [linear_output],
					"outputs": [layer_output],
					"attributes": {},
				})
			else:
				layer_output = linear_output
		else:
			nodes.append({
				"name": _tensor_name("Activation", layer_id),
				"op_type": activation_op,
				"inputs": [linear_output],
				"outputs": [layer_output],
				"attributes": {},
			})

		previous_tensor = layer_output

	var output_size := 1
	var output_weights: Array = weights[layer_ids[-1]]
	if not output_weights.is_empty():
		output_size = output_weights.size()

	var model := _make_model_proto(nodes, initializers, input_size, output_size)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		printerr("Error al abrir el archivo para escritura: %d" % FileAccess.get_open_error())
		return

	file.store_buffer(model)
	file.close()
	print("Modelo ONNX exportado exitosamente a: ", file_path)


func _make_model_proto(nodes: Array, initializers: Array, input_size: int, output_size: int) -> PackedByteArray:
	var graph := PackedByteArray()
	for node in nodes:
		_write_message_field(graph, 1, _make_node_proto(node))
	_write_string_field(graph, 2, "godot_nn_graph")
	for initializer in initializers:
		_write_message_field(graph, 5, _make_tensor_proto(initializer))
	_write_message_field(graph, 11, _make_value_info_proto("input", [1, input_size]))
	_write_message_field(graph, 12, _make_value_info_proto("output", [1, output_size]))

	var model := PackedByteArray()
	_write_varint_field(model, 1, 8)
	_write_string_field(model, 2, "Godot_NN_Trainer")
	_write_message_field(model, 7, graph)
	_write_message_field(model, 8, _make_opset_proto(ONNX_OPSET_VERSION))
	return model


func _make_node_proto(node: Dictionary) -> PackedByteArray:
	var result := PackedByteArray()
	for input_name in node.get("inputs", []):
		_write_string_field(result, 1, str(input_name))
	for output_name in node.get("outputs", []):
		_write_string_field(result, 2, str(output_name))
	_write_string_field(result, 3, str(node.get("name", "")))
	_write_string_field(result, 4, str(node.get("op_type", "")))

	var attributes: Dictionary = node.get("attributes", {})
	for attr_name in attributes.keys():
		var attr_value = attributes[attr_name]
		if attr_value is float:
			_write_message_field(result, 5, _make_float_attribute(str(attr_name), float(attr_value)))
		else:
			_write_message_field(result, 5, _make_int_attribute(str(attr_name), int(attr_value)))

	return result


func _make_tensor_proto(tensor: Dictionary) -> PackedByteArray:
	var result := PackedByteArray()
	for dim in tensor.get("dims", []):
		_write_varint_field(result, 1, int(dim))
	_write_varint_field(result, 2, TENSOR_FLOAT)
	_write_string_field(result, 8, str(tensor.get("name", "")))
	_write_bytes_field(result, 9, _floats_to_raw_data(tensor.get("data", [])))
	return result


func _make_value_info_proto(name: String, shape: Array) -> PackedByteArray:
	var tensor_shape := PackedByteArray()
	for dim_value in shape:
		var dim := PackedByteArray()
		_write_varint_field(dim, 1, int(dim_value))
		_write_message_field(tensor_shape, 1, dim)

	var tensor_type := PackedByteArray()
	_write_varint_field(tensor_type, 1, TENSOR_FLOAT)
	_write_message_field(tensor_type, 2, tensor_shape)

	var type_proto := PackedByteArray()
	_write_message_field(type_proto, 1, tensor_type)

	var value_info := PackedByteArray()
	_write_string_field(value_info, 1, name)
	_write_message_field(value_info, 2, type_proto)
	return value_info


func _make_opset_proto(version: int) -> PackedByteArray:
	var result := PackedByteArray()
	_write_varint_field(result, 2, version)
	return result


func _make_float_attribute(name: String, value: float) -> PackedByteArray:
	var result := PackedByteArray()
	_write_string_field(result, 1, name)
	_write_fixed32_float_field(result, 2, value)
	_write_varint_field(result, 20, 1)
	return result


func _make_int_attribute(name: String, value: int) -> PackedByteArray:
	var result := PackedByteArray()
	_write_string_field(result, 1, name)
	_write_varint_field(result, 3, value)
	_write_varint_field(result, 20, 2)
	return result


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


func _tensor_name(prefix: String, layer_id: int) -> String:
	return "%s_%s" % [prefix, "out" if layer_id == -1 else str(layer_id)]


func _floats_to_raw_data(values: Array) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(values.size() * 4)
	var offset := 0
	for value in values:
		result.encode_float(offset, float(value))
		offset += 4
	return result


func _write_varint_field(target: PackedByteArray, field_number: int, value: int) -> void:
	_write_varint(target, (field_number << 3) | 0)
	_write_varint(target, value)


func _write_fixed32_float_field(target: PackedByteArray, field_number: int, value: float) -> void:
	_write_varint(target, (field_number << 3) | 5)
	var raw := PackedByteArray()
	raw.resize(4)
	raw.encode_float(0, value)
	target.append_array(raw)


func _write_string_field(target: PackedByteArray, field_number: int, value: String) -> void:
	_write_bytes_field(target, field_number, value.to_utf8_buffer())


func _write_message_field(target: PackedByteArray, field_number: int, value: PackedByteArray) -> void:
	_write_bytes_field(target, field_number, value)


func _write_bytes_field(target: PackedByteArray, field_number: int, value: PackedByteArray) -> void:
	_write_varint(target, (field_number << 3) | 2)
	_write_varint(target, value.size())
	target.append_array(value)


func _write_varint(target: PackedByteArray, value: int) -> void:
	var remaining := value
	while remaining >= 128:
		target.append((remaining & 0x7f) | 0x80)
		remaining = remaining >> 7
	target.append(remaining & 0x7f)
