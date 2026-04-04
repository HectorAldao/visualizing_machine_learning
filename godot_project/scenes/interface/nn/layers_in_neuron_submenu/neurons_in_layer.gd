class_name NeuronsInLayer extends VBoxContainer



@onready var label: Label = $Label
@onready var textedit: TextEdit = $TextEdit
@onready var plusbutton: Button = $HBoxContainer/PlusButton
@onready var minusbutton: Button = $HBoxContainer/MinusButton


var neuron_id: int



func _ready() -> void:
	plusbutton.pressed.connect(_on_plus_pressed)
	minusbutton.pressed.connect(_on_minus_pressed)


static func newone(new_neuron_id: int) -> NeuronsInLayer:
	var new_neurons_in_layer: NeuronsInLayer = preload(Constants.SCENES.neuronsinlayer).instantiate()
	new_neurons_in_layer.neuron_id = new_neuron_id
	return new_neurons_in_layer


func _on_plus_pressed() -> void:
	SignalsObserver.add_neuron.emit(neuron_id)


func _on_minus_pressed() -> void:
	SignalsObserver.remove_neuron.emit(neuron_id)
