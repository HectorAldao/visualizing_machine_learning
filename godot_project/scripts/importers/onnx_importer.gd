class_name ONNXImporter
extends RefCounted


const ACTIVATION_MAP: Dictionary = {
	"Relu": Constants.ACT_FUNCS.relu,
	"Sigmoid": Constants.ACT_FUNCS.sigmoid,
	"Softmax": Constants.ACT_FUNCS.softmax,
	"Identity": Constants.ACT_FUNCS.identity,
}

const TENSOR_FLOAT: int = 1


func import_network(file_path: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "No se pudo abrir el archivo ONNX: %d" % FileAccess.get_open_error()}

	var bytes := file.get_buffer(file.get_length())
	file.close()

	var legacy_result := _try_import_legacy_json(bytes)
	if legacy_result.get("ok", false):
		return legacy_result

	var model := _parse_message(bytes)
	if model.is_empty():
		return {"ok": false, "message": "El ONNX no es un protobuf válido."}

	var graph_bytes := _first_bytes(model, 7)
	if graph_bytes.is_empty():
		return {"ok": false, "message": "El ONNX no contiene un grafo."}

	var graph := _parse_graph(graph_bytes)
	var layer_entries := _extract_fully_connected_layers(graph)
	if layer_entries.is_empty():
		return {"ok": false, "message": "El ONNX no contiene capas fully connected importables."}

	return _layer_entries_to_network(layer_entries)


func _try_import_legacy_json(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes[0] != 123:
		return {"ok": false}

	var parsed = JSON.parse_string(bytes.get_string_from_utf8())
	if not (parsed is Dictionary):
		return {"ok": false}

	var graph: Dictionary = parsed.get("graph", {})
	var initializers: Array = graph.get("initializer", [])
	var nodes: Array = graph.get("node", [])
	var weights: Dictionary[int, Array] = {}
	var biases: Dictionary[int, Array] = {}
	var activations: Dictionary[int, int] = {}

	for initializer in initializers:
		if not (initializer is Dictionary):
			continue

		var name := str(initializer.get("name", ""))
		var dims: Array = initializer.get("dims", [])
		var float_data: Array = initializer.get("float_data", [])

		if name.begins_with("W"):
			var layer_id := int(name.substr(1))
			if dims.size() < 2:
				return {"ok": false, "message": "El tensor %s no tiene dimensiones suficientes." % name}
			weights[layer_id] = _unflatten_weights(float_data, int(dims[0]), int(dims[1]))
		elif name.begins_with("B"):
			var layer_id := int(name.substr(1))
			var bias_size := int(dims[0]) if not dims.is_empty() else float_data.size()
			biases[layer_id] = _to_float_vector(float_data, bias_size)

	for node in nodes:
		if not (node is Dictionary):
			continue

		var node_name := str(node.get("name", ""))
		if not node_name.begins_with("Activation_"):
			continue

		var layer_id := int(node_name.trim_prefix("Activation_"))
		var op_type := str(node.get("op_type", "Identity"))
		activations[layer_id] = ACTIVATION_MAP.get(op_type, Constants.ACT_FUNCS.identity)

	if weights.is_empty():
		return {"ok": false}

	return {
		"ok": true,
		"weights": weights,
		"biases": biases,
		"activations": activations,
	}


func _parse_graph(graph_bytes: PackedByteArray) -> Dictionary:
	var graph_msg := _parse_message(graph_bytes)
	var graph: Dictionary = {
		"nodes": [],
		"initializers": {},
		"inputs": [],
		"outputs": [],
	}

	for node_bytes in _bytes_values(graph_msg, 1):
		graph.nodes.append(_parse_node(node_bytes))

	for tensor_bytes in _bytes_values(graph_msg, 5):
		var tensor := _parse_tensor(tensor_bytes)
		if not str(tensor.get("name", "")).is_empty():
			graph.initializers[tensor.name] = tensor

	for value_info_bytes in _bytes_values(graph_msg, 11):
		graph.inputs.append(_parse_value_info(value_info_bytes))

	for value_info_bytes in _bytes_values(graph_msg, 12):
		graph.outputs.append(_parse_value_info(value_info_bytes))

	return graph


func _parse_node(node_bytes: PackedByteArray) -> Dictionary:
	var node_msg := _parse_message(node_bytes)
	var node: Dictionary = {
		"inputs": _string_values(node_msg, 1),
		"outputs": _string_values(node_msg, 2),
		"name": _first_string(node_msg, 3),
		"op_type": _first_string(node_msg, 4),
		"attributes": {},
	}

	for attr_bytes in _bytes_values(node_msg, 5):
		var attr := _parse_attribute(attr_bytes)
		if not str(attr.get("name", "")).is_empty():
			node.attributes[attr.name] = attr.value

	return node


func _parse_attribute(attr_bytes: PackedByteArray) -> Dictionary:
	var attr_msg := _parse_message(attr_bytes)
	var name := _first_string(attr_msg, 1)
	var type := _first_varint(attr_msg, 20, 0)
	var value = null

	match type:
		1:
			value = _first_fixed32_float(attr_msg, 2, 0.0)
		2:
			value = _first_varint(attr_msg, 3, 0)
		_:
			if _has_field(attr_msg, 3):
				value = _first_varint(attr_msg, 3, 0)
			elif _has_field(attr_msg, 2):
				value = _first_fixed32_float(attr_msg, 2, 0.0)

	return {"name": name, "value": value}


func _parse_tensor(tensor_bytes: PackedByteArray) -> Dictionary:
	var tensor_msg := _parse_message(tensor_bytes)
	var dims := _varint_values(tensor_msg, 1)
	var data_type := _first_varint(tensor_msg, 2, 0)
	var name := _first_string(tensor_msg, 8)
	var data: Array = []

	if data_type == TENSOR_FLOAT:
		for packed_float_data in _bytes_values(tensor_msg, 4):
			data.append_array(_raw_data_to_floats(packed_float_data))

		for fixed_float in _fixed32_float_values(tensor_msg, 4):
			data.append(fixed_float)

		var raw_data := _first_bytes(tensor_msg, 9)
		if not raw_data.is_empty():
			data = _raw_data_to_floats(raw_data)

	return {"name": name, "dims": dims, "data": data}


func _parse_value_info(value_info_bytes: PackedByteArray) -> Dictionary:
	var value_info_msg := _parse_message(value_info_bytes)
	return {
		"name": _first_string(value_info_msg, 1),
		"shape": _parse_type_shape(_first_bytes(value_info_msg, 2)),
	}


func _parse_type_shape(type_bytes: PackedByteArray) -> Array:
	if type_bytes.is_empty():
		return []

	var type_msg := _parse_message(type_bytes)
	var tensor_type_bytes := _first_bytes(type_msg, 1)
	if tensor_type_bytes.is_empty():
		return []

	var tensor_type_msg := _parse_message(tensor_type_bytes)
	var shape_bytes := _first_bytes(tensor_type_msg, 2)
	if shape_bytes.is_empty():
		return []

	var shape_msg := _parse_message(shape_bytes)
	var dims: Array = []
	for dim_bytes in _bytes_values(shape_msg, 1):
		var dim_msg := _parse_message(dim_bytes)
		dims.append(_first_varint(dim_msg, 1, 0))
	return dims


func _extract_fully_connected_layers(graph: Dictionary) -> Array:
	var initializers: Dictionary = graph.initializers
	var pending_matmuls: Dictionary = {}
	var tensor_to_layer_index: Dictionary = {}
	var layer_entries: Array = []

	for node in graph.nodes:
		var op_type := str(node.get("op_type", ""))
		var inputs: Array = node.get("inputs", [])
		var outputs: Array = node.get("outputs", [])
		if outputs.is_empty():
			continue

		match op_type:
			"Gemm":
				var entry := _entry_from_gemm(node, initializers)
				if not entry.is_empty():
					layer_entries.append(entry)
					tensor_to_layer_index[outputs[0]] = layer_entries.size() - 1
			"MatMul":
				var pending := _pending_from_matmul(inputs, initializers)
				if not pending.is_empty():
					pending_matmuls[outputs[0]] = pending
			"Add":
				var entry_from_add := _entry_from_add(inputs, initializers, pending_matmuls)
				if not entry_from_add.is_empty():
					layer_entries.append(entry_from_add)
					tensor_to_layer_index[outputs[0]] = layer_entries.size() - 1
			"Relu", "Sigmoid", "Softmax", "Identity":
				if inputs.is_empty() or not tensor_to_layer_index.has(inputs[0]):
					continue
				var layer_idx := int(tensor_to_layer_index[inputs[0]])
				var existing: Dictionary = layer_entries[layer_idx]
				existing.activation = ACTIVATION_MAP.get(op_type, Constants.ACT_FUNCS.identity)
				layer_entries[layer_idx] = existing
				tensor_to_layer_index[outputs[0]] = layer_idx

	for output_tensor in pending_matmuls.keys():
		if tensor_to_layer_index.has(output_tensor):
			continue
		var pending_entry: Dictionary = pending_matmuls[output_tensor]
		pending_entry.bias = _zeros_vector((pending_entry.weights as Array).size())
		pending_entry.activation = Constants.ACT_FUNCS.identity
		layer_entries.append(pending_entry)
		tensor_to_layer_index[output_tensor] = layer_entries.size() - 1

	return layer_entries


func _entry_from_gemm(node: Dictionary, initializers: Dictionary) -> Dictionary:
	var inputs: Array = node.get("inputs", [])
	if inputs.size() < 2 or not initializers.has(inputs[1]):
		return {}

	var attrs: Dictionary = node.get("attributes", {})
	if int(attrs.get("transA", 0)) != 0:
		return {}

	var weight_tensor: Dictionary = initializers[inputs[1]]
	var trans_b := int(attrs.get("transB", 0))
	var weights := _matrix_from_tensor_for_right_multiply(weight_tensor, trans_b == 1)
	if weights.is_empty():
		return {}

	var bias := _zeros_vector(weights.size())
	if inputs.size() >= 3 and initializers.has(inputs[2]):
		bias = _vector_from_tensor(initializers[inputs[2]], weights.size())

	var alpha := float(attrs.get("alpha", 1.0))
	var beta := float(attrs.get("beta", 1.0))
	if not is_equal_approx(alpha, 1.0):
		weights = _scale_matrix(weights, alpha)
	if not is_equal_approx(beta, 1.0):
		bias = _scale_vector(bias, beta)

	return {
		"weights": weights,
		"bias": bias,
		"activation": Constants.ACT_FUNCS.identity,
	}


func _pending_from_matmul(inputs: Array, initializers: Dictionary) -> Dictionary:
	if inputs.size() < 2:
		return {}

	if initializers.has(inputs[1]):
		var right_weights := _matrix_from_tensor_for_right_multiply(initializers[inputs[1]], false)
		return {"weights": right_weights} if not right_weights.is_empty() else {}

	if initializers.has(inputs[0]):
		var left_weights := _matrix_from_tensor_for_left_multiply(initializers[inputs[0]])
		return {"weights": left_weights} if not left_weights.is_empty() else {}

	return {}


func _entry_from_add(inputs: Array, initializers: Dictionary, pending_matmuls: Dictionary) -> Dictionary:
	if inputs.size() < 2:
		return {}

	var matmul_tensor := ""
	var bias_tensor := ""
	if pending_matmuls.has(inputs[0]) and initializers.has(inputs[1]):
		matmul_tensor = inputs[0]
		bias_tensor = inputs[1]
	elif pending_matmuls.has(inputs[1]) and initializers.has(inputs[0]):
		matmul_tensor = inputs[1]
		bias_tensor = inputs[0]

	if matmul_tensor.is_empty():
		return {}

	var pending: Dictionary = pending_matmuls[matmul_tensor]
	pending_matmuls.erase(matmul_tensor)
	var weights: Array = pending.weights
	return {
		"weights": weights,
		"bias": _vector_from_tensor(initializers[bias_tensor], weights.size()),
		"activation": Constants.ACT_FUNCS.identity,
	}


func _layer_entries_to_network(layer_entries: Array) -> Dictionary:
	var weights: Dictionary[int, Array] = {}
	var biases: Dictionary[int, Array] = {}
	var activations: Dictionary[int, int] = {}

	var first_weights: Array = layer_entries[0].weights
	var input_size := 1
	if not first_weights.is_empty() and first_weights[0] is Array:
		input_size = (first_weights[0] as Array).size()
	weights[0] = _ones_column(input_size)

	for idx in range(layer_entries.size()):
		var layer_id := -1 if idx == layer_entries.size() - 1 else idx + 1
		var entry: Dictionary = layer_entries[idx]
		weights[layer_id] = entry.weights
		biases[layer_id] = entry.bias
		activations[layer_id] = int(entry.get("activation", Constants.ACT_FUNCS.identity))

	return {
		"ok": true,
		"weights": weights,
		"biases": biases,
		"activations": activations,
	}


func _matrix_from_tensor_for_right_multiply(tensor: Dictionary, is_transposed_in_node: bool) -> Array:
	var dims: Array = tensor.get("dims", [])
	if dims.size() < 2:
		return []

	var rows := int(dims[0])
	var cols := int(dims[1])
	var matrix := _unflatten_weights(tensor.get("data", []), rows, cols)
	return matrix if is_transposed_in_node else _transpose_matrix(matrix)


func _matrix_from_tensor_for_left_multiply(tensor: Dictionary) -> Array:
	var dims: Array = tensor.get("dims", [])
	if dims.size() < 2:
		return []

	return _unflatten_weights(tensor.get("data", []), int(dims[0]), int(dims[1]))


func _vector_from_tensor(tensor: Dictionary, size: int) -> Array:
	return _to_float_vector(tensor.get("data", []), size)


func _unflatten_weights(flat_weights: Array, rows: int, cols: int) -> Array:
	var matrix: Array = []
	var cursor := 0

	for _row_idx in range(rows):
		var row: Array = []
		for _col_idx in range(cols):
			var value := 0.0
			if cursor < flat_weights.size():
				value = float(flat_weights[cursor])
			row.append(value)
			cursor += 1
		matrix.append(row)

	return matrix


func _transpose_matrix(matrix: Array) -> Array:
	if matrix.is_empty() or not (matrix[0] is Array):
		return []

	var rows := matrix.size()
	var cols := (matrix[0] as Array).size()
	var result: Array = []
	for col_idx in range(cols):
		var row: Array = []
		for row_idx in range(rows):
			row.append(float(matrix[row_idx][col_idx]))
		result.append(row)
	return result


func _scale_matrix(matrix: Array, factor: float) -> Array:
	var result: Array = []
	for row in matrix:
		var scaled_row: Array = []
		for value in row:
			scaled_row.append(float(value) * factor)
		result.append(scaled_row)
	return result


func _scale_vector(vector: Array, factor: float) -> Array:
	var result: Array = []
	for value in vector:
		result.append(float(value) * factor)
	return result


func _to_float_vector(source: Array, size: int) -> Array:
	var vector: Array = []
	vector.resize(max(size, 0))

	for idx in range(vector.size()):
		if idx < source.size():
			vector[idx] = float(source[idx])
		else:
			vector[idx] = 0.0

	return vector


func _ones_column(rows: int) -> Array:
	var matrix: Array = []
	for _i in range(max(rows, 1)):
		matrix.append([1.0])
	return matrix


func _zeros_vector(size: int) -> Array:
	var vector: Array = []
	for _idx in range(max(size, 0)):
		vector.append(0.0)
	return vector


func _raw_data_to_floats(raw: PackedByteArray) -> Array:
	var values: Array = []
	var count := raw.size() / 4
	for idx in range(count):
		values.append(raw.decode_float(idx * 4))
	return values


func _parse_message(bytes: PackedByteArray) -> Dictionary:
	var fields: Dictionary = {}
	var cursor := 0

	while cursor < bytes.size():
		var key_result := _read_varint(bytes, cursor)
		if key_result.is_empty():
			return {}
		var key := int(key_result[0])
		cursor = int(key_result[1])

		var field_number := key >> 3
		var wire_type := key & 0x07
		var entry := {"wire": wire_type, "value": null}

		match wire_type:
			0:
				var value_result := _read_varint(bytes, cursor)
				if value_result.is_empty():
					return {}
				entry.value = int(value_result[0])
				cursor = int(value_result[1])
			1:
				if cursor + 8 > bytes.size():
					return {}
				entry.value = bytes.slice(cursor, cursor + 8)
				cursor += 8
			2:
				var length_result := _read_varint(bytes, cursor)
				if length_result.is_empty():
					return {}
				var length := int(length_result[0])
				cursor = int(length_result[1])
				if cursor + length > bytes.size():
					return {}
				entry.value = bytes.slice(cursor, cursor + length)
				cursor += length
			5:
				if cursor + 4 > bytes.size():
					return {}
				entry.value = bytes.slice(cursor, cursor + 4)
				cursor += 4
			_:
				return {}

		if not fields.has(field_number):
			fields[field_number] = []
		fields[field_number].append(entry)

	return fields


func _read_varint(bytes: PackedByteArray, start: int) -> Array:
	var result := 0
	var shift := 0
	var cursor := start

	while cursor < bytes.size() and shift < 64:
		var byte := int(bytes[cursor])
		cursor += 1
		result = result | ((byte & 0x7f) << shift)
		if (byte & 0x80) == 0:
			return [result, cursor]
		shift += 7

	return []


func _has_field(message: Dictionary, field_number: int) -> bool:
	return message.has(field_number) and not (message[field_number] as Array).is_empty()


func _first_bytes(message: Dictionary, field_number: int) -> PackedByteArray:
	var values := _bytes_values(message, field_number)
	return values[0] if not values.is_empty() else PackedByteArray()


func _bytes_values(message: Dictionary, field_number: int) -> Array[PackedByteArray]:
	var values: Array[PackedByteArray] = []
	if not message.has(field_number):
		return values

	for entry in message[field_number]:
		if int(entry.wire) == 2:
			values.append(entry.value)
	return values


func _first_string(message: Dictionary, field_number: int) -> String:
	var values := _string_values(message, field_number)
	return values[0] if not values.is_empty() else ""


func _string_values(message: Dictionary, field_number: int) -> Array:
	var values: Array = []
	for raw in _bytes_values(message, field_number):
		values.append(raw.get_string_from_utf8())
	return values


func _first_varint(message: Dictionary, field_number: int, default_value: int) -> int:
	var values := _varint_values(message, field_number)
	return int(values[0]) if not values.is_empty() else default_value


func _varint_values(message: Dictionary, field_number: int) -> Array:
	var values: Array = []
	if not message.has(field_number):
		return values

	for entry in message[field_number]:
		if int(entry.wire) == 0:
			values.append(int(entry.value))
		elif int(entry.wire) == 2:
			var raw: PackedByteArray = entry.value
			var cursor := 0
			while cursor < raw.size():
				var decoded := _read_varint(raw, cursor)
				if decoded.is_empty():
					break
				values.append(int(decoded[0]))
				cursor = int(decoded[1])
	return values


func _first_fixed32_float(message: Dictionary, field_number: int, default_value: float) -> float:
	var values := _fixed32_float_values(message, field_number)
	return float(values[0]) if not values.is_empty() else default_value


func _fixed32_float_values(message: Dictionary, field_number: int) -> Array:
	var values: Array = []
	if not message.has(field_number):
		return values

	for entry in message[field_number]:
		if int(entry.wire) == 5:
			var raw: PackedByteArray = entry.value
			values.append(raw.decode_float(0))
	return values
