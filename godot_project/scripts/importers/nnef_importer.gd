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

	var fallback_result := _import_from_graph_text(content)
	if fallback_result.get("ok", false):
		return fallback_result

	return {"ok": false, "message": "El NNEF no contiene una red importable."}


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
			"activations": _dictionary_with_int_keys(parsed.get("activations", {}), false),
		}

	return {"ok": false}


func _import_from_graph_text(content: String) -> Dictionary:
	var weights: Dictionary[int, Array] = {}
	var activations: Dictionary[int, int] = {}

	for line in content.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("input = external"):
			var input_shape := _extract_shape(trimmed)
			if input_shape.size() >= 2:
				weights[0] = _ones_column(int(input_shape[1]))
			continue

		if trimmed.begins_with("w_") and trimmed.contains("variable"):
			var variable_name := trimmed.get_slice(" ", 0)
			var layer_id := _layer_id_from_nnef_name(variable_name.trim_prefix("w_"))
			var shape := _extract_shape(trimmed)
			if shape.size() >= 2:
				weights[layer_id] = _zeros_matrix(int(shape[0]), int(shape[1]))
			continue

		for activation_name in ACTIVATION_MAP.keys():
			if trimmed.contains("= %s(" % activation_name):
				var layer_id := _layer_id_from_assignment(trimmed)
				activations[layer_id] = ACTIVATION_MAP[activation_name]
				break

		if trimmed.begins_with("output = z_") or trimmed.contains("= z_"):
			var layer_id := _layer_id_from_assignment(trimmed)
			activations[layer_id] = Constants.ACT_FUNCS.identity

	if not weights.has(0) and not weights.is_empty():
		var first_layer := _get_sorted_layer_ids(weights.keys())[0]
		var first_weights: Array = weights[first_layer]
		var input_size := 1
		if not first_weights.is_empty() and first_weights[0] is Array:
			input_size = first_weights[0].size()
		weights[0] = _ones_column(input_size)

	if weights.is_empty():
		return {"ok": false}

	return {
		"ok": true,
		"weights": weights,
		"activations": activations,
	}


func _dictionary_with_int_keys(source: Dictionary, keep_values_as_array: bool) -> Dictionary:
	var result: Dictionary = {}

	for key in source.keys():
		var int_key := int(str(key))
		if keep_values_as_array:
			result[int_key] = source[key]
		else:
			result[int_key] = int(source[key])

	return result


func _extract_shape(line: String) -> Array:
	var begin := line.find("[")
	var end := line.find("]", begin)
	if begin == -1 or end == -1:
		return []

	var shape: Array = []
	for part in line.substr(begin + 1, end - begin - 1).split(","):
		shape.append(int(part.strip_edges()))

	return shape


func _layer_id_from_nnef_name(name: String) -> int:
	if name == "out":
		return -1
	return int(name)


func _layer_id_from_assignment(line: String) -> int:
	var target := line.get_slice("=", 0).strip_edges()
	if target == "output":
		return -1
	return _layer_id_from_nnef_name(target.get_slice("_", 1))


func _ones_column(rows: int) -> Array:
	var matrix: Array = []
	for _i in range(max(rows, 1)):
		matrix.append([1.0])
	return matrix


func _zeros_matrix(rows: int, cols: int) -> Array:
	var matrix: Array = []
	for _row_idx in range(max(rows, 1)):
		var row: Array = []
		for _col_idx in range(max(cols, 1)):
			row.append(0.0)
		matrix.append(row)
	return matrix


func _get_sorted_layer_ids(keys: Array) -> Array[int]:
	var sorted_keys := []
	var hidden_and_in := []

	for key in keys:
		if int(key) >= 0:
			hidden_and_in.append(int(key))

	hidden_and_in.sort()
	sorted_keys.append_array(hidden_and_in)

	if keys.has(-1):
		sorted_keys.append(-1)

	return sorted_keys
