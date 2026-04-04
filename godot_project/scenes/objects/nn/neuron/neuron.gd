class_name Neuron extends Button

var _id: int = 0

static func newone(new_id: int) -> Neuron:
	var new_neuron: Neuron = preload(Constants.SCENES.neuron).instantiate()
	new_neuron._id = new_id
	return new_neuron
