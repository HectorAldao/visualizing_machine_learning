class_name BarsChart extends Control

@export var scale_mult: float = 100.0

var data_to_plot: Dictionary[String, float]
var title_text: String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var text_container: VBoxContainer = $HBoxContainer/TextLabelsVBoxContainer
	var numbers: VBoxContainer = $HBoxContainer/NumbersVBoxContainer
	var title_label: Label = $Title
	
	title_label.text = title_text
	
	for key in data_to_plot:
		var text_label: Label = Label.new()
		var hbox: HBoxContainer = HBoxContainer.new()
		var rect: ColorRect = ColorRect.new()
		var number_label: Label = Label.new()
		
		text_label.text = key
		
		rect.custom_minimum_size.x = data_to_plot[key] * scale_mult
		number_label.text = "%.2f" % data_to_plot[key]
		
		text_container.add_child(text_label)
		hbox.add_child(rect)
		hbox.add_child(number_label)
		numbers.add_child(hbox)

static func newone(title_txt: String, data_dict: Dictionary[String, float]) -> BarsChart:
	var new_barschart: BarsChart = preload(Constants.SCENES.barschart).instantiate()
	new_barschart.title_text = title_txt
	new_barschart.data_to_plot = data_dict
	return new_barschart
