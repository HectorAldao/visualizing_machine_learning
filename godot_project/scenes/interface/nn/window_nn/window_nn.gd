class_name WindowNn extends Window


@onready var text0: Label = %Label0
@onready var text_formula: Label = %LabelFormula
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
	}

func _ready() -> void:

	SignalsObserver.info_neuron.connect(set_neuron_info)
	SignalsObserver.nn_resalted_neuron_forward.connect(set_resalted_neuron_info_forward)
	SignalsObserver.nn_resalted_neuron_backward.connect(set_resalted_neuron_info_backward)


## Changes the text in the window when a neuron is pressed
func set_neuron_info(neuron_id: int, layer_id: int) -> void:

	text_formula.text = ""

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

	text_formula.text = ""

	var neuron_bias: float = 0.0

	# If there is bias for this layer,
	# the layer is not the in_layer (it has no bias),
	# and the neuron_id is in the layers dict of bias (just to be shure)
	if Variables.nn.nn_bias_dict.has(layer_id) and neuron_id >= 0 and neuron_id < Variables.nn.nn_bias_dict[layer_id].size():
		neuron_bias = float(Variables.nn.nn_bias_dict[layer_id][neuron_id])

	var neuron_weights: Array = []

	if Variables.nn.nn_dict.has(layer_id) and neuron_id < Variables.nn.nn_dict[layer_id].size():
		neuron_weights = Variables.nn.nn_dict[layer_id][neuron_id]

	var formula: String = _formula_forward_formatter(neuron_weights, input_array, neuron_bias, neuron_output, layer_id)


	var dic_of_info: Dictionary = {
		"output": "%0.3f" % neuron_output
	}

	text0.text = template_texts.neuron_resalted[0]
	text_formula.text = formula
	text1.text = template_texts.neuron_resalted[1].format(dic_of_info)


func set_resalted_neuron_info_backward(neuron_id: int, layer_id: int, delta_value: float) -> void:
	pass

# --- Helpers ---

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
func _latex_formatter(weights: Array, inputs: Array, bias: float, output: float, layer_id: int) -> String:

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
