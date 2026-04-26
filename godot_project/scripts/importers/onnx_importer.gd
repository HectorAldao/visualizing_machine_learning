class_name ONNXImporter
extends RefCounted


const ACTIVATION_MAP: Dictionary = {
	"Relu": Constants.ACT_FUNCS.relu,
	"Sigmoid": Constants.ACT_FUNCS.sigmoid,
	"Softmax": Constants.ACT_FUNCS.softmax,
	"Identity": Constants.ACT_FUNCS.identity,
}


func import_network(file_path: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "No se pudo abrir el archivo ONNX: %d" % FileAccess.get_open_error()}

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if not (parsed is Dictionary):
		return {"ok": false, "message": "El ONNX no contiene JSON válido."}

	var graph: Dictionary = parsed.get("graph", {})
	var initializers: Array = graph.get("initializer", [])
	var nodes: Array = graph.get("node", [])
	var weights: Dictionary[int, Array] = {}
	var activations: Dictionary[int, int] = {}

	for initializer in initializers:
		if not (initializer is Dictionary):
			continue

		var name := str(initializer.get("name", ""))
		if not name.begins_with("W"):
			continue

		var layer_id := int(name.substr(1))
		var dims: Array = initializer.get("dims", [])
		var flat_weights: Array = initializer.get("float_data", [])
		if dims.size() < 2:
			return {"ok": false, "message": "El tensor %s no tiene dimensiones suficientes." % name}

		weights[layer_id] = _unflatten_weights(flat_weights, int(dims[0]), int(dims[1]))

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
		return {"ok": false, "message": "El ONNX no contiene pesos importables."}

	return {
		"ok": true,
		"weights": weights,
		"activations": activations,
	}


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
