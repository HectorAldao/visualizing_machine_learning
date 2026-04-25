class_name Neuron extends Button

var _id: int = -2
var _layer_id: int = -2


func _ready() -> void:
	pressed.connect(_on_pressed)
	#mouse_exited.connect(_on_mouse_exited)


static func newone(new_id: int, new_layer_id) -> Neuron:
	var new_neuron: Neuron = preload(Constants.SCENES.neuron).instantiate()
	new_neuron._id = new_id
	new_neuron._layer_id = new_layer_id
	return new_neuron


func _on_pressed() -> void:
	SignalsObserver.info_neuron.emit(_id, _layer_id)
	pass
