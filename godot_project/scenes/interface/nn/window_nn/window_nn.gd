class_name WindowNn extends Window


@onready var text0: Label = %Label0
@onready var text_formula: Label = %LabelFormula
@onready var latexformula: LatexFormula = %LatexFormula
@onready var text1: Label = %Label1


const template_texts: Dictionary[String, Array] = {
	"neuron_info": [
		"Pesos de esta neurona:
		{weights}
		Bias:
		{bias}"
		],
	"neuron_resalted": [
		"La operación que calcula la salida de la neurona es:",
		"Su salida es {output}"
		],
	"neuron_backward_resalted": [
		"La operación que calcula el error que vuelve por esta neurona es:",
		"Su delta es {delta}"
		],
	}

func _ready() -> void:

	SignalsObserver.info_neuron.connect(set_neuron_info)
	SignalsObserver.nn_resalted_neuron_forward.connect(set_resalted_neuron_info_forward)
	SignalsObserver.nn_resalted_neuron_backward.connect(set_resalted_neuron_info_backward)
	SignalsObserver.nn_resalted_layer_forward.connect(set_resalted_layer_info_forward)
	SignalsObserver.nn_resalted_data_step.connect(set_resalted_data_step_info)
	SignalsObserver.nn_train_finished.connect(set_training_finished_info)


## Changes the text in the window when a neuron is pressed
func set_neuron_info(neuron_id: int, layer_id: int) -> void:

	_reset_formula()

	var bias: float = 0.0

	# If there is bias for this layer,
	# the layer is not the in_layer (it has no bias),
	# and the neuron_id is in the layers dict of bias (just to be shure)
	if Variables.nn.nn_bias_dict.has(layer_id) and neuron_id >= 0 and neuron_id < Variables.nn.nn_bias_dict[layer_id].size():
		bias = float(Variables.nn.nn_bias_dict[layer_id][neuron_id])

	var dic_of_info: Dictionary = {
		"weights": Variables.nn.nn_dict[layer_id][neuron_id],
		"bias": "%0.3f" % bias
	}

	_clean_lists(dic_of_info)

	text0.text = template_texts.neuron_info[0].format(dic_of_info)
	text1.text = ""


func set_resalted_neuron_info_forward(neuron_id: int, layer_id: int, input_array: Array, neuron_output: float) -> void:


	_reset_formula()

	var neuron_bias: float = 0.0

	# If there is bias for this layer,
	# the layer is not the in_layer (it has no bias),
	# and the neuron_id is in the layers dict of bias (just to be shure)
	if Variables.nn.nn_bias_dict.has(layer_id) and neuron_id >= 0 and neuron_id < Variables.nn.nn_bias_dict[layer_id].size():
		neuron_bias = float(Variables.nn.nn_bias_dict[layer_id][neuron_id])

	var neuron_weights: Array = []

	if Variables.nn.nn_dict.has(layer_id) and neuron_id < Variables.nn.nn_dict[layer_id].size():
		neuron_weights = Variables.nn.nn_dict[layer_id][neuron_id]

	var formula: String

	if ConfigVariables.use_latex:
		formula = _latex_forward_formatter(neuron_weights, input_array, neuron_bias, neuron_output, layer_id)
		latexformula.request_formula(formula)

	else:
		formula = _formula_forward_formatter(neuron_weights, input_array, neuron_bias, neuron_output, layer_id)
		text_formula.text = formula

	var dic_of_info: Dictionary = {
		"output": "%0.3f" % neuron_output
	}

	text0.text = template_texts.neuron_resalted[0]
	text1.text = template_texts.neuron_resalted[1].format(dic_of_info)


func set_resalted_neuron_info_backward(_neuron_id: int, layer_id: int, backward_info: Dictionary) -> void:

	_reset_formula()

	var formula: String
	if ConfigVariables.use_latex:
		formula = _latex_backward_formatter(backward_info, layer_id)
		latexformula.request_formula(formula)
	else:
		formula = _formula_backward_formatter(backward_info, layer_id)
		text_formula.text = formula

	var dic_of_info: Dictionary = {
		"delta": "%0.3f" % float(backward_info.get("delta", 0.0))
	}

	text0.text = template_texts.neuron_backward_resalted[0]
	text1.text = template_texts.neuron_backward_resalted[1].format(dic_of_info)


func set_resalted_layer_info_forward(layer_info: Dictionary) -> void:
	_reset_formula()

	var layer_id: int = int(layer_info.get("layer_id", -9999))
	var input_values: Array = layer_info.get("input_values", [])
	var weights: Array = layer_info.get("weights", [])
	var biases: Array = layer_info.get("biases", [])
	var z_values: Array = layer_info.get("z_values", [])
	var output_values: Array = layer_info.get("output_values", [])
	var activation_type: int = int(layer_info.get("activation_type", Constants.ACT_FUNCS.identity))

	var formula: String
	if ConfigVariables.use_latex:
		formula = _latex_layer_forward_formatter(input_values, weights, biases, z_values, output_values, activation_type)
		latexformula.request_formula(formula)
	else:
		formula = _formula_layer_forward_formatter(input_values, weights, biases, z_values, output_values, activation_type)
		text_formula.text = formula

	text0.text = "Se ha ejecutado %s completa.\nLa operación agregada de la capa es:" % _layer_name_text(layer_id)
	text1.text = "Cada neurona de una misma capa recibe el mismo vector de entrada, pero usa su propia columna de pesos. Por eso podemos juntar todos esos pesos en una matriz W: la columna 1 calcula la neurona 1, la columna 2 calcula la neurona 2, y así sucesivamente.\n\nPrimero se calcula z = x · W + b, donde x es la entrada, W son los pesos y b son los sesgos. Después se aplica la función de activación %s para obtener la salida final a de la capa." % _activation_layer_explanation(activation_type)


func set_resalted_data_step_info(step_info: Dictionary) -> void:
	_reset_formula()

	var data_idx: int = int(step_info.get("data_idx", -1))
	var input_values: Array = step_info.get("input_values", [])
	var output_values: Array = step_info.get("output_values", [])
	var target_values: Array = step_info.get("target_values", [])
	var train_attributes: Array = step_info.get("train_attributes", [])
	var target_attributes: Array = step_info.get("target_attributes", [])
	var loss_type: int = int(step_info.get("loss_type", Constants.LOSS_FUNCS.mse))
	var loss_value: float = float(step_info.get("loss_value", _compute_loss_value(output_values, target_values, loss_type)))

	var formula: String
	if ConfigVariables.use_latex:
		formula = _latex_data_step_error_formatter(output_values, target_values, loss_type, loss_value)
		latexformula.request_formula(formula)
	else:
		formula = _formula_data_step_error_formatter(output_values, target_values, loss_type, loss_value)
		text_formula.text = formula

	var data_text: String = "Se ha completado un dato de entrenamiento."
	if data_idx >= 0:
		data_text = "Se ha completado el dato de entrenamiento %d." % (data_idx + 1)

	text0.text = "%s\nEntrada: %s\nSalida de la red: %s\nEtiqueta esperada: %s" % [
		data_text,
		_format_named_values(train_attributes, input_values),
		_format_output_result(output_values),
		_format_expected_label(target_values, target_attributes)
	]
	text1.text = "La red compara su salida con la etiqueta esperada usando la función de error. Ese valor resume cuánto se ha equivocado para este dato: si L es pequeño, la salida está cerca de lo esperado; si L es grande, la red todavía debe ajustar más sus pesos durante la retropropagación."


func set_training_finished_info() -> void:
	_reset_formula()
	text0.text = "El entrenamiento ha acabado."
	text1.text = "Pulse el botón 'Evaluar' para testear la red contra nuevos datos y comprobar si el entrenamiento ha funcionado."

# --- Helpers ---


func _layer_name_text(layer_id: int) -> String:
	if layer_id == -1:
		return "la capa de salida"
	if layer_id > 0:
		return "la capa oculta %d" % layer_id
	return "la capa %d" % layer_id


func _activation_layer_explanation(activation_type: int) -> String:
	match activation_type:
		Constants.ACT_FUNCS.softmax:
			return "softmax al vector completo z; así cada salida se interpreta como una probabilidad relativa frente a las demás"
		Constants.ACT_FUNCS.identity:
			return "identidad, que deja z tal cual"
		_:
			return "%s a cada componente de z" % _activation_latex_name(activation_type)


func _latex_layer_forward_formatter(input_values: Array, weights: Array, biases: Array, z_values: Array, output_values: Array, activation_type: int) -> String:
	var activation_text: String = "\\mathbf{z}"
	if activation_type != Constants.ACT_FUNCS.identity:
		activation_text = "\\operatorname{%s}(\\mathbf{z})" % _activation_latex_name(activation_type)

	var formula_lines: Array[String] = [
		"\\mathbf{x} &= %s" % _latex_row_vector(input_values),
		"W &= %s" % _latex_weight_matrix(weights, input_values.size()),
		"\\mathbf{b} &= %s" % _latex_row_vector(biases),
		"\\mathbf{z} &= \\mathbf{x}W + \\mathbf{b} = %s" % _latex_row_vector(z_values),
		"\\mathbf{a} &= %s = %s" % [activation_text, _latex_row_vector(output_values)]
	]
	return "\\begin{aligned} %s \\end{aligned}" % " \\\\ ".join(formula_lines)


func _formula_layer_forward_formatter(input_values: Array, weights: Array, biases: Array, z_values: Array, output_values: Array, activation_type: int) -> String:
	var activation_text: String = "z"
	if activation_type != Constants.ACT_FUNCS.identity:
		activation_text = "%s(z)" % _activation_latex_name(activation_type)

	return "x = %s\nW = %s\nb = %s\nz = x × W + b = %s\na = %s = %s" % [
		_format_vector(input_values),
		_format_weight_matrix(weights, input_values.size()),
		_format_vector(biases),
		_format_vector(z_values),
		activation_text,
		_format_vector(output_values)
	]


func _latex_data_step_error_formatter(output_values: Array, target_values: Array, loss_type: int, loss_value: float) -> String:
	var terms_count: int = min(output_values.size(), target_values.size())
	if terms_count <= 0:
		return "\\begin{aligned} L &= 0 \\end{aligned}"

	match loss_type:
		Constants.LOSS_FUNCS.coss_entr:
			var formula_lines: Array[String] = [
				"L &= -\\sum_{i=1}^{%d} y_i \\log(a_i)" % terms_count,
				"&= -(%s)" % _cross_entropy_terms_text(output_values, target_values, true),
				"&= %s" % _format_latex_number(loss_value)
			]
			return "\\begin{aligned} %s \\end{aligned}" % " \\\\ ".join(formula_lines)
		_:
			var formula_lines: Array[String] = [
				"L &= \\frac{1}{n}\\sum_{i=1}^{n}(a_i-y_i)^2,\\quad n=%d" % terms_count,
				"&= \\frac{%s}{%d}" % [_mse_terms_text(output_values, target_values), terms_count],
				"&= %s" % _format_latex_number(loss_value)
			]
			return "\\begin{aligned} %s \\end{aligned}" % " \\\\ ".join(formula_lines)


func _formula_data_step_error_formatter(output_values: Array, target_values: Array, loss_type: int, loss_value: float) -> String:
	var terms_count: int = min(output_values.size(), target_values.size())
	if terms_count <= 0:
		return "L = 0"

	match loss_type:
		Constants.LOSS_FUNCS.coss_entr:
			return "L = -Σ_i y_i × log(a_i)\n= -(%s)\n= %s" % [
				_cross_entropy_terms_text(output_values, target_values, false),
				_format_latex_number(loss_value)
			]
		_:
			return "L = (1 / n) × Σ_i (a_i - y_i)^2, n = %d\n= (%s) / %d\n= %s" % [
				terms_count,
				_mse_terms_text(output_values, target_values),
				terms_count,
				_format_latex_number(loss_value)
			]


func _format_vector(values: Array) -> String:
	var formatted_values: Array[String] = []
	for value in values:
		formatted_values.append(_format_latex_number(float(value)))
	return "[%s]" % ", ".join(formatted_values)


func _latex_row_vector(values: Array) -> String:
	var formatted_values: Array[String] = []
	for value in values:
		formatted_values.append(_format_latex_number(float(value)))
	if formatted_values.is_empty():
		formatted_values.append("0")
	return "\\begin{bmatrix}%s\\end{bmatrix}" % " & ".join(formatted_values)


func _format_weight_matrix(weights: Array, input_count: int) -> String:
	if weights.is_empty() or input_count <= 0:
		return "[]"

	var rows: Array[String] = []
	for input_idx in range(input_count):
		var row_values: Array[String] = []
		for neuron_idx in range(weights.size()):
			var neuron_weights: Array = weights[neuron_idx]
			row_values.append(_format_latex_number(_get_weight_value(neuron_weights, input_idx)))
		rows.append("[%s]" % ", ".join(row_values))

	return "[\n  %s\n]" % ",\n  ".join(rows)


func _latex_weight_matrix(weights: Array, input_count: int) -> String:
	if weights.is_empty() or input_count <= 0:
		return "\\begin{bmatrix}0\\end{bmatrix}"

	var rows: Array[String] = []
	for input_idx in range(input_count):
		var row_values: Array[String] = []
		for neuron_idx in range(weights.size()):
			var neuron_weights: Array = weights[neuron_idx]
			row_values.append(_format_latex_number(_get_weight_value(neuron_weights, input_idx)))
		rows.append(" & ".join(row_values))

	return "\\begin{bmatrix}%s\\end{bmatrix}" % " \\\\ ".join(rows)


func _get_weight_value(neuron_weights: Array, input_idx: int) -> float:
	if input_idx < 0 or input_idx >= neuron_weights.size():
		return 0.0
	return float(neuron_weights[input_idx])


func _format_named_values(names: Array, values: Array) -> String:
	if values.is_empty():
		return "[]"

	var parts: Array[String] = []
	for i in range(values.size()):
		var value_name: String = "x%d" % (i + 1)
		if i < names.size():
			value_name = str(names[i])
		parts.append("%s = %s" % [value_name, _format_latex_number(float(values[i]))])
	return ", ".join(parts)


func _format_output_result(output_values: Array) -> String:
	var output_text: String = _format_vector(output_values)
	if Variables.nn_output_class_decoder.is_empty() or output_values.size() <= 1:
		return output_text

	var predicted_idx: int = _get_max_value_index(output_values)
	var predicted_label: String = str(Variables.nn_output_class_decoder.get(predicted_idx, "clase %d" % predicted_idx))
	return "%s; predicción actual: '%s'" % [output_text, predicted_label]


func _format_expected_label(target_values: Array, target_attributes: Array) -> String:
	if target_values.is_empty():
		return "sin etiqueta esperada"

	if not Variables.nn_output_class_decoder.is_empty() and target_values.size() > 1:
		var expected_idx: int = _get_max_value_index(target_values)
		var expected_label: String = str(Variables.nn_output_class_decoder.get(expected_idx, "clase %d" % expected_idx))
		return "'%s' con vector objetivo %s" % [expected_label, _format_vector(target_values)]

	if target_attributes.size() == target_values.size():
		return _format_named_values(target_attributes, target_values)

	return _format_vector(target_values)


func _get_max_value_index(values: Array) -> int:
	if values.is_empty():
		return -1

	var max_idx: int = 0
	var max_value: float = float(values[0])
	for i in range(1, values.size()):
		var current_value: float = float(values[i])
		if current_value > max_value:
			max_value = current_value
			max_idx = i
	return max_idx


func _mse_terms_text(output_values: Array, target_values: Array) -> String:
	var terms: Array[String] = []
	for i in range(min(output_values.size(), target_values.size())):
		terms.append("(%s - %s)^2" % [_format_latex_number(float(output_values[i])), _format_latex_number(float(target_values[i]))])
	return " + ".join(terms)


func _cross_entropy_terms_text(output_values: Array, target_values: Array, latex: bool) -> String:
	var terms: Array[String] = []
	for i in range(min(output_values.size(), target_values.size())):
		if latex:
			terms.append("%s\\log(%s)" % [_format_latex_number(float(target_values[i])), _format_latex_number(float(output_values[i]))])
		else:
			terms.append("%s × log(%s)" % [_format_latex_number(float(target_values[i])), _format_latex_number(float(output_values[i]))])
	return " + ".join(terms)


func _compute_loss_value(output_values: Array, target_values: Array, loss_type: int) -> float:
	var terms_count: int = min(output_values.size(), target_values.size())
	if terms_count <= 0:
		return 0.0

	match loss_type:
		Constants.LOSS_FUNCS.coss_entr:
			var epsilon: float = 1e-8
			var loss_sum: float = 0.0
			for i in range(terms_count):
				loss_sum -= float(target_values[i]) * log(max(float(output_values[i]), epsilon))
			return loss_sum
		_:
			var squared_error_sum: float = 0.0
			for i in range(terms_count):
				var error: float = float(output_values[i]) - float(target_values[i])
				squared_error_sum += error * error
			return squared_error_sum / float(terms_count)

## For each value on the input Dictionary that is an Array[String], it will
## change that Array for a string that concatenates each string element on
## it, adding commas and the corresponding conjunction among elements  
func _clean_lists(dict: Dictionary) -> void:

	for key in dict:
		var value = dict[key]
		var concatenation: String = ""
		
		if typeof(value) == TYPE_ARRAY:
			var cont: int = 0
			var size_arr: int = value.size()
			for i in value:
				cont += 1
				if typeof(i) == TYPE_FLOAT:
					if concatenation == "":  # If its the first
						concatenation = "%0.3f" % i
					elif cont == size_arr:  # If its the last
						concatenation += ", y " + "%0.3f" % i
					else:  # If is nor the first or the last
						concatenation += ", " + "%0.3f" % i
			dict[key] = concatenation
						
		elif typeof(value) == TYPE_DICTIONARY:
			for key_v in value:  # If the value is a dict (as in "lista_ganancias"), change it to a string
				concatenation += str(key_v) + " = " + str(value[key_v]) + "\n"
			dict[key] = concatenation


## Takes all the info about how the neuron
## and transforms it into a latex-processable
## String to feed the text_formula
func _latex_forward_formatter(weights: Array, inputs: Array, bias: float, output: float, layer_id: int) -> String:

	var weighted_terms: Array[String] = []
	var weighted_sum: float = bias
	var term_count: int = min(weights.size(), inputs.size())

	for i in range(term_count):
		var weight: float = float(weights[i])
		var input: float = float(inputs[i])
		weighted_terms.append("(%s \\cdot %s)" % [_format_latex_number(weight), _format_latex_number(input)])
		weighted_sum += weight * input

	if weighted_terms.is_empty():
		weighted_terms.append("0")

	var z_expression: String = " + ".join(weighted_terms)
	if bias > 0.0:
		z_expression += " + %s" % _format_latex_number(bias)
	elif bias < 0.0:
		z_expression += " - %s" % _format_latex_number(absf(bias))

	var activation_type: int = Variables.nn.nn_func_dict.get(layer_id, Constants.ACT_FUNCS.identity)
	var activation_name: String = _activation_latex_name(activation_type)
	var activation_expression: String = "z"
	if activation_type != Constants.ACT_FUNCS.identity:
		activation_expression = "\\operatorname{%s}(z)" % activation_name
		if activation_type == Constants.ACT_FUNCS.softmax:
			activation_expression = "\\operatorname{%s}(\\mathbf{z})_i" % activation_name

	return "\\begin{aligned} z &= %s = %s \\\\ a &= %s = %s \\end{aligned}" % [
		z_expression,
		_format_latex_number(weighted_sum),
		activation_expression,
		_format_latex_number(output)
	]


func _formula_forward_formatter(weights: Array, inputs: Array, bias: float, output: float, layer_id: int) -> String:

	var weighted_terms: Array[String] = []
	var weighted_sum: float = bias
	var term_count: int = min(weights.size(), inputs.size())

	for i in range(term_count):
		var weight: float = float(weights[i])
		var input: float = float(inputs[i])
		weighted_terms.append("(%s × %s)" % [_format_latex_number(weight), _format_latex_number(input)])
		weighted_sum += weight * input

	if weighted_terms.is_empty():
		weighted_terms.append("0")

	var weighted_sum_text: String = " + ".join(weighted_terms)
	if bias > 0.0:
		weighted_sum_text += " + %s" % _format_latex_number(bias)
	elif bias < 0.0:
		weighted_sum_text += " - %s" % _format_latex_number(absf(bias))

	var activation_type: int = Variables.nn.nn_func_dict.get(layer_id, Constants.ACT_FUNCS.identity)
	var activation_name: String = _activation_latex_name(activation_type)
	var activation_text: String = "z"
	if activation_type != Constants.ACT_FUNCS.identity:
		activation_text = "%s(z)" % activation_name
		if activation_type == Constants.ACT_FUNCS.softmax:
			activation_text = "%s(z)_i" % activation_name

	return "z = %s = %s\na = %s = %s" % [
		weighted_sum_text,
		_format_latex_number(weighted_sum),
		activation_text,
		_format_latex_number(output)
	]


func _latex_backward_formatter(backward_info: Dictionary, _layer_id: int) -> String:
	var delta: float = float(backward_info.get("delta", 0.0))
	var z_value: float = float(backward_info.get("z", 0.0))
	var output_value: float = float(backward_info.get("output", 0.0))
	var target_value: float = float(backward_info.get("target", 0.0))
	var upstream_gradient: float = float(backward_info.get("upstream_gradient", 0.0))
	var activation_type: int = int(backward_info.get("activation_type", Constants.ACT_FUNCS.identity))
	var loss_type: int = int(backward_info.get("loss_type", Constants.LOSS_FUNCS.mse))
	var is_output_layer: bool = bool(backward_info.get("is_output_layer", false))

	if is_output_layer and activation_type == Constants.ACT_FUNCS.softmax and loss_type == Constants.LOSS_FUNCS.coss_entr:
		return "\\begin{aligned} \\delta_i &= \\frac{\\partial L}{\\partial z_i} = \\sum_k \\frac{\\partial L}{\\partial a_k}\\frac{\\partial a_k}{\\partial z_i} \\\\ &= \\sum_k \\left(-\\frac{y_k}{a_k}\\right)a_k(\\mathbf{1}_{k=i}-a_i) \\\\ &\\approx a_i - y_i = %s - %s = %s \\end{aligned}" % [
			_format_latex_number(output_value),
			_format_latex_number(target_value),
			_format_latex_number(delta)
		]

	var activation_derivative_value: float = _activation_derivative_value(z_value, activation_type)
	var activation_derivative_text: String = _activation_derivative_latex_text(activation_type, z_value, output_value)
	if is_output_layer:
		return "\\begin{aligned} \\delta &= \\frac{\\partial L}{\\partial a}\\frac{\\partial a}{\\partial z} \\\\ \\frac{\\partial L}{\\partial a} &= %s = %s \\\\ \\frac{\\partial a}{\\partial z} &= %s = %s \\\\ \\delta &\\approx %s \\cdot %s = %s \\end{aligned}" % [
			_loss_derivative_latex_text(loss_type, output_value, target_value),
			_format_latex_number(upstream_gradient),
			activation_derivative_text,
			_format_latex_number(activation_derivative_value),
			_format_latex_number(upstream_gradient),
			_format_latex_number(activation_derivative_value),
			_format_latex_number(delta)
		]

	return "\\begin{aligned} g &= %s = %s \\\\ \\delta &= g\\frac{\\partial a}{\\partial z} \\\\ \\frac{\\partial a}{\\partial z} &= %s = %s \\\\ \\delta &\\approx %s \\cdot %s = %s \\end{aligned}" % [
		_hidden_upstream_latex_text(backward_info),
		_format_latex_number(upstream_gradient),
		activation_derivative_text,
		_format_latex_number(activation_derivative_value),
		_format_latex_number(upstream_gradient),
		_format_latex_number(activation_derivative_value),
		_format_latex_number(delta)
	]


func _formula_backward_formatter(backward_info: Dictionary, _layer_id: int) -> String:
	var delta: float = float(backward_info.get("delta", 0.0))
	var z_value: float = float(backward_info.get("z", 0.0))
	var output_value: float = float(backward_info.get("output", 0.0))
	var target_value: float = float(backward_info.get("target", 0.0))
	var upstream_gradient: float = float(backward_info.get("upstream_gradient", 0.0))
	var activation_type: int = int(backward_info.get("activation_type", Constants.ACT_FUNCS.identity))
	var loss_type: int = int(backward_info.get("loss_type", Constants.LOSS_FUNCS.mse))
	var is_output_layer: bool = bool(backward_info.get("is_output_layer", false))

	if is_output_layer and activation_type == Constants.ACT_FUNCS.softmax and loss_type == Constants.LOSS_FUNCS.coss_entr:
		return "δ_i = ∂L/∂z_i = Σ_k(∂L/∂a_k × ∂a_k/∂z_i)\n= Σ_k((-y_k / a_k) × a_k(1 si k=i, si no 0 - a_i))\n≈ a_i - y_i = %s - %s = %s" % [
			_format_latex_number(output_value),
			_format_latex_number(target_value),
			_format_latex_number(delta)
		]

	var activation_derivative_value: float = _activation_derivative_value(z_value, activation_type)
	var activation_derivative_text: String = _activation_derivative_text(activation_type, z_value, output_value)
	if is_output_layer:
		return "δ = ∂L/∂a × ∂a/∂z\n∂L/∂a = %s = %s\n∂a/∂z = %s = %s\nδ ≈ %s × %s = %s" % [
			_loss_derivative_text(loss_type, output_value, target_value),
			_format_latex_number(upstream_gradient),
			activation_derivative_text,
			_format_latex_number(activation_derivative_value),
			_format_latex_number(upstream_gradient),
			_format_latex_number(activation_derivative_value),
			_format_latex_number(delta)
		]

	return "g = %s = %s\nδ = g × ∂a/∂z\n∂a/∂z = %s = %s\nδ ≈ %s × %s = %s" % [
		_hidden_upstream_text(backward_info),
		_format_latex_number(upstream_gradient),
		activation_derivative_text,
		_format_latex_number(activation_derivative_value),
		_format_latex_number(upstream_gradient),
		_format_latex_number(activation_derivative_value),
		_format_latex_number(delta)
	]


func _hidden_upstream_text(backward_info: Dictionary) -> String:
	var next_deltas: Array = backward_info.get("next_deltas", [])
	var next_weights: Array = backward_info.get("next_weights", [])
	var terms: Array[String] = []

	for next_neuron_idx in range(next_deltas.size()):
		if next_neuron_idx >= next_weights.size():
			continue
		var next_neuron_weights: Array = next_weights[next_neuron_idx]
		var neuron_id: int = int(backward_info.get("neuron_id", -1))
		if neuron_id < 0 or neuron_id >= next_neuron_weights.size():
			continue
		terms.append("(%s × %s)" % [_format_latex_number(float(next_neuron_weights[neuron_id])), _format_latex_number(float(next_deltas[next_neuron_idx]))])

	if terms.is_empty():
		return "0"
	return " + ".join(terms)


func _hidden_upstream_latex_text(backward_info: Dictionary) -> String:
	return _hidden_upstream_text(backward_info).replace("×", "\\cdot")


func _activation_derivative_value(z_value: float, activation_type: int) -> float:
	match activation_type:
		Constants.ACT_FUNCS.relu:
			return 1.0 if z_value > 0.0 else 0.0
		Constants.ACT_FUNCS.sigmoid:
			var sigmoid_value: float = 1.0 / (1.0 + exp(-z_value))
			return sigmoid_value * (1.0 - sigmoid_value)
		Constants.ACT_FUNCS.softmax:
			return 1.0
		_:
			return 1.0


func _activation_derivative_text(activation_type: int, z_value: float, output_value: float) -> String:
	match activation_type:
		Constants.ACT_FUNCS.relu:
			return "ReLU'(z) = 1 si z > 0, si no 0; z = %s" % _format_latex_number(z_value)
		Constants.ACT_FUNCS.sigmoid:
			return "sigmoid'(z) = sigmoid(z) × (1 - sigmoid(z)) = %s × (1 - %s)" % [_format_latex_number(output_value), _format_latex_number(output_value)]
		Constants.ACT_FUNCS.softmax:
			return "Jacobian(softmax): ∂a_i/∂z_j = a_i(1 si i=j, si no 0 - a_j)"
		_:
			return "identity'(z) = 1"


func _activation_derivative_latex_text(activation_type: int, z_value: float, output_value: float) -> String:
	match activation_type:
		Constants.ACT_FUNCS.relu:
			return "\\operatorname{ReLU}'(z)=\\begin{cases}1,&z>0\\\\0,&z\\le 0\\end{cases},\\ z=%s" % _format_latex_number(z_value)
		Constants.ACT_FUNCS.sigmoid:
			return "\\sigma'(z)=\\sigma(z)(1-\\sigma(z))=%s(1-%s)" % [_format_latex_number(output_value), _format_latex_number(output_value)]
		Constants.ACT_FUNCS.softmax:
			return "\\frac{\\partial a_i}{\\partial z_j}=a_i(\\mathbf{1}_{i=j}-a_j)"
		_:
			return "1"


func _loss_derivative_text(loss_type: int, output_value: float, target_value: float) -> String:
	match loss_type:
		Constants.LOSS_FUNCS.coss_entr:
			return "-y / a = -%s / %s" % [_format_latex_number(target_value), _format_latex_number(output_value)]
		_:
			return "a - y = %s - %s" % [_format_latex_number(output_value), _format_latex_number(target_value)]


func _loss_derivative_latex_text(loss_type: int, output_value: float, target_value: float) -> String:
	match loss_type:
		Constants.LOSS_FUNCS.coss_entr:
			return "-\\frac{y}{a}=-\\frac{%s}{%s}" % [_format_latex_number(target_value), _format_latex_number(output_value)]
		_:
			return "a-y=%s-%s" % [_format_latex_number(output_value), _format_latex_number(target_value)]


func _format_latex_number(value: float) -> String:
	return "%0.3f" % value


func _activation_latex_name(activation_type: int) -> String:

	match activation_type:
		Constants.ACT_FUNCS.relu:
			return "ReLU"
		Constants.ACT_FUNCS.sigmoid:
			return "sigmoid"
		Constants.ACT_FUNCS.softmax:
			return "softmax"
		_:
			return "identity"


func _reset_formula() -> void:

	if ConfigVariables.use_latex:
		latexformula.reset_sprite()
	else:
		text_formula.text = ""
