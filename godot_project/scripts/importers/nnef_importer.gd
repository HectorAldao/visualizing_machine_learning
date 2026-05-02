class_name NNEFImporter
extends RefCounted


const ACTIVATION_MAP: Dictionary = {
	"relu": Constants.ACT_FUNCS.relu,
	"sigmoid": Constants.ACT_FUNCS.sigmoid,
	"softmax": Constants.ACT_FUNCS.softmax,
	"identity": Constants.ACT_FUNCS.identity,
}


func import_network(file_path: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "No se pudo abrir el archivo NNEF: %d" % FileAccess.get_open_error()}

	var content := file.get_as_text()
	file.close()

	var metadata_result := _try_import_metadata(content)
	if metadata_result.get("ok", false):
		return metadata_result

	var graph_result := _import_from_graph_text(content)
	if graph_result.get("ok", false):
		return graph_result

	return {"ok": false, "message": "El NNEF no contiene una red fully connected importable."}


func _try_import_metadata(content: String) -> Dictionary:
	for line in content.split("\n"):
		var trimmed := line.strip_edges()
		if not trimmed.begins_with("# godot_nn_metadata = "):
			continue

		var json_text := trimmed.trim_prefix("# godot_nn_metadata = ")
		var parsed = JSON.parse_string(json_text)
		if not (parsed is Dictionary):
			return {"ok": false, "message": "Los metadatos NNEF no son JSON válido."}

		return {
			"ok": true,
			"weights": _dictionary_with_int_keys(parsed.get("weights", {}), true),
			"biases": _dictionary_with_int_keys(parsed.get("biases", {}), true),
			"activations": _dictionary_with_int_keys(parsed.get("activations", {}), false),
		}

	return {"ok": false}


func _import_from_graph_text(content: String) -> Dictionary:
	var statements := _split_statements(content)
	var constants: Dictionary = {}
	var pending_matmuls: Dictionary = {}
	var tensor_to_layer_index: Dictionary = {}
	var layer_entries: Array = []
	var input_size := _extract_graph_input_size(content)

	for statement in statements:
		var trimmed: String = str(statement).strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("#") or not trimmed.contains("="):
			continue

		if trimmed.contains("constant<"):
			var constant := _parse_constant_statement(trimmed)
			if not constant.is_empty():
				constants[constant.name] = constant
			continue

		var target: String = trimmed.get_slice("=", 0).strip_edges()
		var expression: String = trimmed.substr(trimmed.find("=") + 1).strip_edges()

		var inline_linear := _entry_from_inline_matmul_add(expression, constants)
		if not inline_linear.is_empty():
			layer_entries.append(inline_linear)
			tensor_to_layer_index[target] = layer_entries.size() - 1
			continue

		if expression.begins_with("matmul("):
			var pending := _pending_from_matmul_expression(expression, constants)
			if not pending.is_empty():
				pending_matmuls[target] = pending
			continue

		if expression.begins_with("add("):
			var add_entry := _entry_from_add_expression(expression, constants, pending_matmuls)
			if not add_entry.is_empty():
				layer_entries.append(add_entry)
				tensor_to_layer_index[target] = layer_entries.size() - 1
			continue

		var activation_name := _activation_from_expression(expression)
		if not activation_name.is_empty():
			var activation_input := _first_call_argument(expression)
			if tensor_to_layer_index.has(activation_input):
				var layer_idx := int(tensor_to_layer_index[activation_input])
				var existing: Dictionary = layer_entries[layer_idx]
				existing.activation = ACTIVATION_MAP[activation_name]
				layer_entries[layer_idx] = existing
				tensor_to_layer_index[target] = layer_idx
			continue

		if tensor_to_layer_index.has(expression):
			tensor_to_layer_index[target] = tensor_to_layer_index[expression]

	for matmul_tensor in pending_matmuls.keys():
		if tensor_to_layer_index.has(matmul_tensor):
			continue
		var pending_entry: Dictionary = pending_matmuls[matmul_tensor]
		pending_entry.bias = _zeros_vector((pending_entry.weights as Array).size())
		pending_entry.activation = Constants.ACT_FUNCS.identity
		layer_entries.append(pending_entry)

	if layer_entries.is_empty():
		return {"ok": false}

	if input_size <= 0:
		var first_weights: Array = layer_entries[0].weights
		if not first_weights.is_empty() and first_weights[0] is Array:
			input_size = (first_weights[0] as Array).size()

	return _layer_entries_to_network(layer_entries, input_size)


func _parse_constant_statement(statement: String) -> Dictionary:
	var name := statement.get_slice("=", 0).strip_edges()
	var shape_begin := statement.find("constant<")
	var shape_end := statement.find(">", shape_begin)
	if shape_begin == -1 or shape_end == -1:
		return {}

	var shape_text := statement.substr(shape_begin + "constant<".length(), shape_end - shape_begin - "constant<".length())
	var shape: Array = []
	for part in shape_text.split(","):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			shape.append(int(trimmed))

	var data: Array = []
	var data_begin := statement.find("[", shape_end)
	var data_end := statement.find("]", data_begin)
	if data_begin != -1 and data_end != -1:
		for part in statement.substr(data_begin + 1, data_end - data_begin - 1).split(","):
			var value_text := part.strip_edges()
			if not value_text.is_empty():
				data.append(float(value_text))

	return {"name": name, "shape": shape, "data": data}


func _entry_from_inline_matmul_add(expression: String, constants: Dictionary) -> Dictionary:
	var plus_index := expression.rfind("+")
	if plus_index == -1:
		return {}

	var matmul_expression := expression.substr(0, plus_index).strip_edges()
	var bias_name := expression.substr(plus_index + 1).strip_edges()
	if not matmul_expression.begins_with("matmul(") or not constants.has(bias_name):
		return {}

	var pending := _pending_from_matmul_expression(matmul_expression, constants)
	if pending.is_empty():
		return {}

	var weights: Array = pending.weights
	return {
		"weights": weights,
		"bias": _vector_from_constant(constants[bias_name], weights.size()),
		"activation": Constants.ACT_FUNCS.identity,
	}


func _pending_from_matmul_expression(expression: String, constants: Dictionary) -> Dictionary:
	var args := _call_arguments(expression)
	if args.size() < 2:
		return {}

	var right := str(args[1]).strip_edges()
	var is_transposed := right.begins_with("transpose(")
	var weight_name := _first_call_argument(right) if is_transposed else right
	if not constants.has(weight_name):
		return {}

	var weights := _matrix_from_constant(constants[weight_name], is_transposed)
	return {"weights": weights} if not weights.is_empty() else {}


func _entry_from_add_expression(expression: String, constants: Dictionary, pending_matmuls: Dictionary) -> Dictionary:
	var args := _call_arguments(expression)
	if args.size() < 2:
		return {}

	var left := str(args[0]).strip_edges()
	var right := str(args[1]).strip_edges()
	var matmul_tensor := ""
	var bias_name := ""

	if pending_matmuls.has(left) and constants.has(right):
		matmul_tensor = left
		bias_name = right
	elif pending_matmuls.has(right) and constants.has(left):
		matmul_tensor = right
		bias_name = left

	if matmul_tensor.is_empty():
		return {}

	var pending: Dictionary = pending_matmuls[matmul_tensor]
	pending_matmuls.erase(matmul_tensor)
	var weights: Array = pending.weights
	return {
		"weights": weights,
		"bias": _vector_from_constant(constants[bias_name], weights.size()),
		"activation": Constants.ACT_FUNCS.identity,
	}


func _matrix_from_constant(constant: Dictionary, is_transposed_in_expression: bool) -> Array:
	var shape: Array = constant.get("shape", [])
	if shape.size() < 2:
		return []

	var matrix := _unflatten_weights(constant.get("data", []), int(shape[0]), int(shape[1]))
	return matrix if is_transposed_in_expression else _transpose_matrix(matrix)


func _vector_from_constant(constant: Dictionary, size: int) -> Array:
	return _to_float_vector(constant.get("data", []), size)


func _layer_entries_to_network(layer_entries: Array, input_size: int) -> Dictionary:
	var weights: Dictionary[int, Array] = {}
	var biases: Dictionary[int, Array] = {}
	var activations: Dictionary[int, int] = {}

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


func _split_statements(content: String) -> Array:
	var statements: Array = []
	for raw_line in content.split("\n"):
		var line := str(raw_line).strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("version ") or line.begins_with("graph ") or line == "{" or line == "}":
			continue
		for part in line.split(";"):
			var statement := part.strip_edges()
			if not statement.is_empty():
				statements.append(statement)
	return statements


func _extract_graph_input_size(content: String) -> int:
	var tensor_index := content.find("input: tensor<")
	if tensor_index != -1:
		var begin := content.find("<", tensor_index)
		var end := content.find(">", begin)
		if begin != -1 and end != -1:
			var dims := _parse_int_list(content.substr(begin + 1, end - begin - 1), ",")
			if dims.size() >= 2:
				return int(dims[1])
			if dims.size() == 1:
				return int(dims[0])

	for statement in _split_statements(content):
		var line: String = str(statement)
		if line.begins_with("input = external"):
			var begin: int = line.find("[")
			var end: int = line.find("]", begin)
			if begin != -1 and end != -1:
				var dims := _parse_int_list(line.substr(begin + 1, end - begin - 1), ",")
				if dims.size() >= 2:
					return int(dims[1])
	return -1


func _parse_int_list(text: String, separator: String) -> Array:
	var values: Array = []
	for part in text.split(separator):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			values.append(int(trimmed))
	return values


func _activation_from_expression(expression: String) -> String:
	for activation_name in ACTIVATION_MAP.keys():
		if expression.begins_with("%s(" % activation_name):
			return activation_name
	return ""


func _first_call_argument(expression: String) -> String:
	var args := _call_arguments(expression)
	return str(args[0]).strip_edges() if not args.is_empty() else expression.strip_edges()


func _call_arguments(expression: String) -> Array:
	var begin := expression.find("(")
	var end := expression.rfind(")")
	if begin == -1 or end == -1 or end <= begin:
		return []

	var body := expression.substr(begin + 1, end - begin - 1)
	var args: Array = []
	var depth := 0
	var start := 0
	for idx in range(body.length()):
		var character := body[idx]
		if character == "(":
			depth += 1
		elif character == ")":
			depth -= 1
		elif character == "," and depth == 0:
			args.append(body.substr(start, idx - start).strip_edges())
			start = idx + 1
	args.append(body.substr(start).strip_edges())
	return args


func _dictionary_with_int_keys(source: Dictionary, keep_values_as_array: bool) -> Dictionary:
	var result: Dictionary = {}

	for key in source.keys():
		var int_key := int(str(key))
		if keep_values_as_array:
			result[int_key] = source[key]
		else:
			result[int_key] = int(source[key])

	return result


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
