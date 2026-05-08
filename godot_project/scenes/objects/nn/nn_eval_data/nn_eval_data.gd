class_name NnEvalData extends Label


# List of the names of the atributes
var atr_name: String

func _ready() -> void:

	SignalsObserver.add_change_eval_data.connect(_on_change_nn_eval_data)

## Constructor
static func newone(new_atr_name: String) -> NnEvalData:
	var evaldata: NnEvalData = preload(Constants.SCENES.nn_eval_data).instantiate()
	evaldata.atr_name = new_atr_name
	return evaldata


## To change the value due to a new data to be processed
func _on_change_nn_eval_data(dict_of_values: Dictionary[String, String]) -> void:
	text = dict_of_values[atr_name]
