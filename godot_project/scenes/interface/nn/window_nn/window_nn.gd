class_name WindowNn extends Window


@onready var text0: Label = $ScrollContainer/VBoxContainer/Label0
@onready var latexformula: LatexFormula = $ScrollContainer/VBoxContainer/Control/LatexFormula
@onready var text1: Label = $ScrollContainer/VBoxContainer/Label1


const template_texts: Dictionary[String, Array] = {
	"neuron_info": [
		"Pesos de esta neurona:
		{weights}"
		],
	}

func _ready() -> void:

	SignalsObserver.info_neuron.connect(set_neuron_info)


func set_neuron_info(neuron_id: int, layer_id: int) -> void:


	var dic_of_info: Dictionary = {"weights": Variables.nn.nn_dict[layer_id][neuron_id]}

	text0.text = template_texts.neuron_info[0].format(dic_of_info)
	text1.text = ""
