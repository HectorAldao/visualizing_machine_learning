class_name ONNXExporter
extends RefCounted

# Mapeo de activaciones según tu especificación
const ACTIVATION_MAP = {
	0: "Relu",
	1: "Sigmoid",
	2: "Softmax",
	3: "Identity"
}

func export_network(weights: Dictionary, biases: Dictionary, activations: Dictionary, file_path: String) -> void:
	var layer_ids = weights.keys()
	layer_ids.sort()
	
	# Reorganizar para que -1 (salida) esté al final
	if layer_ids.has(-1):
		layer_ids.erase(-1)
		layer_ids.append(-1)
	
	var onnx_graph = {
		"ir_version": 8, # Versión estándar de ONNX
		"producer_name": "Godot_NN_Trainer",
		"graph": {
			"node": [],
			"initializer": [],
			"input": [],
			"output": []
		}
	}
	
	# Iterar para construir el grafo
	for i in range(layer_ids.size()):
		var current_id = layer_ids[i]
		var next_id = layer_ids[i+1] if i + 1 < layer_ids.size() else null
		
		var current_weights = weights[current_id]
		var activation_id = activations.get(current_id, 3) # Default Identity
		
		# 1. Definir Initializers (Pesos y bias)
		# En ONNX, los pesos son tensores. Convertimos Array[Array] a Array plano.
		var flattened_weights = []
		var shape = [current_weights.size(), 0]
		if current_weights.size() > 0:
			shape[1] = current_weights[0].size()
			for row in current_weights:
				flattened_weights.append_array(row)
		
		var weight_name = "W" + str(current_id)
		onnx_graph.graph.initializer.append({
			"name": weight_name,
			"data_type": 1, # float32
			"dims": shape,
			"float_data": flattened_weights
		})

		var bias_name = "B" + str(current_id)
		var current_biases: Array = _get_layer_biases(biases, current_id, shape[0])
		onnx_graph.graph.initializer.append({
			"name": bias_name,
			"data_type": 1, # float32
			"dims": [shape[0]],
			"float_data": current_biases
		})
		
		# 2. Definir Nodos (Operación MatMul + Activación)
		var input_name = "input_" + str(current_id) if i == 0 else "act_" + str(layer_ids[i-1])
		var matmul_output = "matmul_" + str(current_id)
		var biased_output = "biased_" + str(current_id)
		var act_output = "act_" + str(current_id)
		
		# Nodo de multiplicación de matrices: Y = W \cdot X
		onnx_graph.graph.node.append({
			"input": [input_name, weight_name],
			"output": [matmul_output],
			"op_type": "MatMul",
			"name": "MatMul_" + str(current_id)
		})

		onnx_graph.graph.node.append({
			"input": [matmul_output, bias_name],
			"output": [biased_output],
			"op_type": "Add",
			"name": "AddBias_" + str(current_id)
		})
		
		# Nodo de activación
		onnx_graph.graph.node.append({
			"input": [biased_output],
			"output": [act_output],
			"op_type": ACTIVATION_MAP[activation_id],
			"name": "Activation_" + str(current_id)
		})
		
		# 3. Definir Entradas y Salidas globales
		if i == 0:
			onnx_graph.graph.input.append({
				"name": input_name,
				"type": { "tensor_type": { "elem_type": 1, "shape": { "dim": [{ "dim_value": shape[1] }] } } }
			})
		
		if next_id == null: # Es la última capa (-1)
			onnx_graph.graph.output.append({
				"name": act_output,
				"type": { "tensor_type": { "elem_type": 1, "shape": { "dim": [{ "dim_value": shape[0] }] } } }
			})

	# Guardar archivo
	_save_json(onnx_graph, file_path)


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


func _save_json(data: Dictionary, path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()
		print("Modelo exportado exitosamente a: ", path)
	else:
		printerr("Error al abrir el archivo para escritura.")
