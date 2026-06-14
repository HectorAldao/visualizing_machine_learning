class_name NeuronsInLayer extends VBoxContainer



@onready var label: Label = $Label
@onready var textedit: TextEdit = $TextEdit
@onready var plusbutton: Button = $HBoxContainer/PlusButton
@onready var minusbutton: Button = $HBoxContainer/MinusButton
@onready var activation_option_button: OptionButton = $VBoxContainer2/OptionButton


var neuron_id: int



func _ready() -> void:
	label.text = "Neuronas\nCapa %s" % neuron_id

	# Connect all the signals
	plusbutton.pressed.connect(_on_plus_pressed)
	minusbutton.pressed.connect(_on_minus_pressed)
	textedit.text_changed.connect(_on_text_changed)
	activation_option_button.item_selected.connect(_on_activation_selected)

	var nn_logic = Variables.get("nn")
	if nn_logic.nn_func_tmp_dict.has(neuron_id):
		_select_activation_by_id(nn_logic.nn_func_tmp_dict[neuron_id])
	else:
		nn_logic.set_layer_activation_tmp(neuron_id, activation_option_button.get_selected_id())


## Constructor of the class
static func newone(new_neuron_id: int) -> NeuronsInLayer:
	var new_neurons_in_layer: NeuronsInLayer = preload(Constants.SCENES.neuronsinlayer).instantiate()
	new_neurons_in_layer.neuron_id = new_neuron_id
	return new_neurons_in_layer


## Called when the pluss button is pressed
func _on_plus_pressed() -> void:
	var nn_logic = Variables.get("nn")
	# The nn dictionary must have the key (just yo be sure)
	if nn_logic.nn_tmp_dict.has(neuron_id):
		# And then check if its going to exceed the limits
		if nn_logic.nn_tmp_dict[neuron_id].size() < Constants.NN_LIMITS.max_neurons:
			# If not, all its okey
			textedit.text = str(int(textedit.text) + 1)
			textedit.text_changed.emit()


func _on_minus_pressed() -> void:
	var nn_logic = Variables.get("nn")
	# The nn dictionary must have the key (just yo be sure)
	if nn_logic.nn_tmp_dict.has(neuron_id):
		# And then check if its going to exceed the limits
		if nn_logic.nn_tmp_dict[neuron_id].size() > 1:
			# If not, all its okey
			textedit.text = str(int(textedit.text) - 1)
			textedit.text_changed.emit()


func _on_text_changed() -> void:
	var nn_logic = Variables.get("nn")

	var num_of_wanted_neurons: int = int(textedit.text)
	if textedit.text == "":
		return
	num_of_wanted_neurons = _check_wanted(num_of_wanted_neurons, textedit, 1)

	if nn_logic.nn_tmp_dict.has(neuron_id):
		nn_logic.set_layer_neuron_count_tmp(neuron_id, num_of_wanted_neurons)
		_update_nn()


func _check_wanted(wanted: int, txtedt: TextEdit, minimum: int) -> int:

	# There can't be less than a neuron, and less than 0 layers
	if wanted < minimum:
		txtedt.text = str(minimum)
		return minimum

	# There can't be more than Constants.NN_LIMITS.max_neurons neurons, and more than Constants.NN_LIMITS.max_layers layers
	if wanted > Constants.NN_LIMITS.max_neurons:
		txtedt.text = str(Constants.NN_LIMITS.max_neurons)
		return Constants.NN_LIMITS.max_neurons
	
	return wanted


func _on_activation_selected(activation_index: int) -> void:
	var activation_func_id: int = activation_option_button.get_item_id(activation_index)
	Variables.nn.set_layer_activation_tmp(neuron_id, activation_func_id)
	_update_nn()


func _select_activation_by_id(activation_func_id: int) -> void:
	var activation_index: int = activation_option_button.get_item_index(activation_func_id)
	if activation_index >= 0:
		activation_option_button.select(activation_index)


func _update_nn() -> void:
	SignalsObserver.reload_nn.emit.call_deferred()
