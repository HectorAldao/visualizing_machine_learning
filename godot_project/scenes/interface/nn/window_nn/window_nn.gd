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
