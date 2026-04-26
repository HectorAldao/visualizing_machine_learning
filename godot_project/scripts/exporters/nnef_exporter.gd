class_name NNEFExporter extends RefCounted


# Mapeo de activaciones según tu especificación
const ACTIVATIONS = {
	0: "relu",
	1: "sigmoid",
	2: "softmax",
	3: "identity"
}

func export_to_nnef(path: String, weights: Dictionary, activations: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("No se pudo crear el archivo NNEF")
		return

	# Standart header
	file.store_line("version 1.0;")
	file.store_line("")
	
	# Get sorted ids
	var layer_ids = _get_sorted_layer_ids(weights.keys())
	
	# Graph definition
	# Asume that input s name is input and output s output
	file.store_line("graph network(input) -> (output)")
	file.store_line("{")
	
	# Define input
	# Asume that the input size is the input of the first array of weights
	var input_size = weights[1].size() # Filas de la primera capa oculta = neuronas entrada
	file.store_line("\tinput = external(shape = [1, %d]);" % input_size)
	
	var last_tensor_name = "input"
	
	# Iterate over the layers to generate operations
	for i in range(1, layer_ids.size()):
		var id = layer_ids[i]
		var layer_weights = weights[id]
		var activation_id = activations[id]
		
		var rows = layer_weights.size()
		var cols = layer_weights[0].size()
		
		# NNEF requieres to define the weight as variables
		var weight_var = "w_" + str(id).replace("-", "out")
		file.store_line("\t%s = variable(shape = [%d, %d], label = '%s');" % [weight_var, rows, cols, weight_var])
		
		# Matmul
		var linear_output = "z_" + str(id).replace("-", "out")
		file.store_line("\t%s = matmul(%s, %s);" % [linear_output, last_tensor_name, weight_var])
		
		# Activation operation
		var act_func = ACTIVATIONS.get(activation_id, "identity")
		var act_output = "a_" + str(id).replace("-", "out")
		
		if id == -1: act_output = "output" # Las layer is the final output
		
		if act_func == "identity":
			file.store_line("\t%s = %s;" % [act_output, linear_output])
		else:
			file.store_line("\t%s = %s(%s);" % [act_output, act_func, linear_output])
		
		last_tensor_name = act_output

	file.store_line("}")
	file.close()
	print("Archivo NNEF exportado exitosamente en: ", path)

## Sorts the layers
func _get_sorted_layer_ids(keys: Array) -> Array:
	var sorted_keys = []
	var hidden_and_in = []
	
	for k in keys:
		if k >= 0:
			hidden_and_in.append(k)
	
	hidden_and_in.sort()
	sorted_keys.append_array(hidden_and_in)
	
	if -1 in keys:
		sorted_keys.append(-1)
		
	return sorted_keys
