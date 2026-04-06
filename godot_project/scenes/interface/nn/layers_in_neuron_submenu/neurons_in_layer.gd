class_name NeuronsInLayer extends VBoxContainer



@onready var label: Label = $Label
@onready var textedit: TextEdit = $TextEdit
@onready var plusbutton: Button = $HBoxContainer/PlusButton
@onready var minusbutton: Button = $HBoxContainer/MinusButton


var neuron_id: int



func _ready() -> void:

	# Connect all the signals
	plusbutton.pressed.connect(_on_plus_pressed)
	minusbutton.pressed.connect(_on_minus_pressed)
	textedit.text_changed.connect(_on_text_changed)


## Constructor of the class
static func newone(new_neuron_id: int) -> NeuronsInLayer:
	var new_neurons_in_layer: NeuronsInLayer = preload(Constants.SCENES.neuronsinlayer).instantiate()
	new_neurons_in_layer.neuron_id = new_neuron_id
	return new_neurons_in_layer


## Called when the pluss button is pressed
func _on_plus_pressed() -> void:
	# The nn dictionary must have the key (just yo be sure)
	if Variables.nn_tmp.has(neuron_id):
		# And then check if its going to exceed the limits
		if Variables.nn_tmp[neuron_id] < Constants.NN_LIMITS.max_neurons:
			# If not, all its okey
			textedit.text = str(int(textedit.text) + 1)
			textedit.text_changed.emit()


func _on_minus_pressed() -> void:
	# The nn dictionary must have the key (just yo be sure)
	if Variables.nn_tmp.has(neuron_id):
		# And then check if its going to exceed the limits
		if Variables.nn_tmp[neuron_id] > 1:
			# If not, all its okey
			textedit.text = str(int(textedit.text) - 1)
			textedit.text_changed.emit()


func _on_text_changed() -> void:

	var num_of_wanted_neurons: int = int(textedit.text)
	if textedit.text == "":
		return
	num_of_wanted_neurons = _check_wanted(num_of_wanted_neurons, textedit, 1)

	if Variables.nn_tmp.has(neuron_id):
		Variables.nn_tmp[neuron_id] = num_of_wanted_neurons


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
