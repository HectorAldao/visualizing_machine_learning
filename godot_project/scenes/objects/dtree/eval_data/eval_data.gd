class_name EvalData extends Button


var data_dict: Dictionary


static func newone(data_dictionary: Dictionary) -> EvalData:
	var evaldata: EvalData = preload(Constants.SCENES.eval_data).instantiate()
	evaldata.data_dict = data_dictionary
	return evaldata
