class_name NnEvalData extends VBoxContainer


# List of the names of the atributes
var atr_array: Array[String] = []

func _ready() -> void:

	SignalsObserver.add_change_eval_data.connect(_on_change_nn_eval_data)

# Constructor
static func newone(new_atr_array: Array[String]) -> NnEvalData:
	var evaldata: NnEvalData = preload(Constants.SCENES.nn_eval_data).instantiate()
	evaldata.atr_array = new_atr_array
	return evaldata


func _on_change_nn_eval_data(dict: Dictionary) -> void:
	pass
