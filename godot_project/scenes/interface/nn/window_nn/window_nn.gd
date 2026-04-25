class_name WindowNn extends Window


@onready var text0: Label = $ScrollContainer/VBoxContainer/Label0


const template_texts: Dictionary[String, Array] = {
	"neuron_info": [
		"Valores de entrada:
		{weight_in}
		Pesos d"
		],
	}

func _ready() -> void:

	SignalsObserver.info_neuron.connect(set_neuron_info)


func set_neuron_info(neuron_id: int, layer_id: int) -> void:
	pass
