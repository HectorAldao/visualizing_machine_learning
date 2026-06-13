extends PanelContainer


@export var color_good: Color
@export var color_error: Color


@onready var hboxcontainer: HBoxContainer = %DatasetsNnHBoxContainer
@onready var entrenar_button: Button = %SelectDatasetNnButton
@onready var informative_text: Label = %InformativeTextNn
@onready var target_selector: VBoxContainer = %TargetSelectorNn
@onready var target_scroll_container: ScrollContainerV2 = %TargetScrollContainerNn


const DICT_OF_DATASETS: Dictionary = {
	"Iris": [
		[
			{"SepalLengthCm": 5.1, "SepalWidthCm": 3.5, "PetalLengthCm": 1.4, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.9, "SepalWidthCm": 3.0, "PetalLengthCm": 1.4, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.7, "SepalWidthCm": 3.2, "PetalLengthCm": 1.3, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.6, "SepalWidthCm": 3.1, "PetalLengthCm": 1.5, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 3.6, "PetalLengthCm": 1.4, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.4, "SepalWidthCm": 3.9, "PetalLengthCm": 1.7, "PetalWidthCm": 0.4, "class": "setosa"},
			{"SepalLengthCm": 4.6, "SepalWidthCm": 3.4, "PetalLengthCm": 1.4, "PetalWidthCm": 0.3, "class": "setosa"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 3.4, "PetalLengthCm": 1.5, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.4, "SepalWidthCm": 2.9, "PetalLengthCm": 1.4, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.9, "SepalWidthCm": 3.1, "PetalLengthCm": 1.5, "PetalWidthCm": 0.1, "class": "setosa"},
			{"SepalLengthCm": 5.4, "SepalWidthCm": 3.7, "PetalLengthCm": 1.5, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.8, "SepalWidthCm": 3.4, "PetalLengthCm": 1.6, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.8, "SepalWidthCm": 3.0, "PetalLengthCm": 1.4, "PetalWidthCm": 0.1, "class": "setosa"},
			{"SepalLengthCm": 4.3, "SepalWidthCm": 3.0, "PetalLengthCm": 1.1, "PetalWidthCm": 0.1, "class": "setosa"},
			{"SepalLengthCm": 5.8, "SepalWidthCm": 4.0, "PetalLengthCm": 1.2, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.7, "SepalWidthCm": 4.4, "PetalLengthCm": 1.5, "PetalWidthCm": 0.4, "class": "setosa"},
			{"SepalLengthCm": 5.4, "SepalWidthCm": 3.9, "PetalLengthCm": 1.3, "PetalWidthCm": 0.4, "class": "setosa"},
			{"SepalLengthCm": 5.1, "SepalWidthCm": 3.5, "PetalLengthCm": 1.4, "PetalWidthCm": 0.3, "class": "setosa"},
			{"SepalLengthCm": 5.7, "SepalWidthCm": 3.8, "PetalLengthCm": 1.7, "PetalWidthCm": 0.3, "class": "setosa"},
			{"SepalLengthCm": 5.1, "SepalWidthCm": 3.8, "PetalLengthCm": 1.5, "PetalWidthCm": 0.3, "class": "setosa"},
			{"SepalLengthCm": 5.4, "SepalWidthCm": 3.4, "PetalLengthCm": 1.7, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.1, "SepalWidthCm": 3.7, "PetalLengthCm": 1.5, "PetalWidthCm": 0.4, "class": "setosa"},
			{"SepalLengthCm": 4.6, "SepalWidthCm": 3.6, "PetalLengthCm": 1.0, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.1, "SepalWidthCm": 3.3, "PetalLengthCm": 1.7, "PetalWidthCm": 0.5, "class": "setosa"},
			{"SepalLengthCm": 4.8, "SepalWidthCm": 3.4, "PetalLengthCm": 1.9, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 3.0, "PetalLengthCm": 1.6, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 3.4, "PetalLengthCm": 1.6, "PetalWidthCm": 0.4, "class": "setosa"},
			{"SepalLengthCm": 5.2, "SepalWidthCm": 3.5, "PetalLengthCm": 1.5, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.2, "SepalWidthCm": 3.4, "PetalLengthCm": 1.4, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.7, "SepalWidthCm": 3.2, "PetalLengthCm": 1.6, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.8, "SepalWidthCm": 3.1, "PetalLengthCm": 1.6, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.4, "SepalWidthCm": 3.4, "PetalLengthCm": 1.5, "PetalWidthCm": 0.4, "class": "setosa"},
			{"SepalLengthCm": 5.2, "SepalWidthCm": 4.1, "PetalLengthCm": 1.5, "PetalWidthCm": 0.1, "class": "setosa"},
			{"SepalLengthCm": 5.5, "SepalWidthCm": 4.2, "PetalLengthCm": 1.4, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.9, "SepalWidthCm": 3.1, "PetalLengthCm": 1.5, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 3.2, "PetalLengthCm": 1.2, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.5, "SepalWidthCm": 3.5, "PetalLengthCm": 1.3, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.9, "SepalWidthCm": 3.6, "PetalLengthCm": 1.4, "PetalWidthCm": 0.1, "class": "setosa"},
			{"SepalLengthCm": 4.4, "SepalWidthCm": 3.0, "PetalLengthCm": 1.3, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.1, "SepalWidthCm": 3.4, "PetalLengthCm": 1.5, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 3.5, "PetalLengthCm": 1.3, "PetalWidthCm": 0.3, "class": "setosa"},
			{"SepalLengthCm": 4.5, "SepalWidthCm": 2.3, "PetalLengthCm": 1.3, "PetalWidthCm": 0.3, "class": "setosa"},
			{"SepalLengthCm": 4.4, "SepalWidthCm": 3.2, "PetalLengthCm": 1.3, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 3.5, "PetalLengthCm": 1.6, "PetalWidthCm": 0.6, "class": "setosa"},
			{"SepalLengthCm": 5.1, "SepalWidthCm": 3.8, "PetalLengthCm": 1.9, "PetalWidthCm": 0.4, "class": "setosa"},
			{"SepalLengthCm": 4.8, "SepalWidthCm": 3.0, "PetalLengthCm": 1.4, "PetalWidthCm": 0.3, "class": "setosa"},
			{"SepalLengthCm": 5.1, "SepalWidthCm": 3.8, "PetalLengthCm": 1.6, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 4.6, "SepalWidthCm": 3.2, "PetalLengthCm": 1.4, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.3, "SepalWidthCm": 3.7, "PetalLengthCm": 1.5, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 3.3, "PetalLengthCm": 1.4, "PetalWidthCm": 0.2, "class": "setosa"},
			{"SepalLengthCm": 7.0, "SepalWidthCm": 3.2, "PetalLengthCm": 4.7, "PetalWidthCm": 1.4, "class": "versicolor"},
			{"SepalLengthCm": 6.4, "SepalWidthCm": 3.2, "PetalLengthCm": 4.5, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 6.9, "SepalWidthCm": 3.1, "PetalLengthCm": 4.9, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 5.5, "SepalWidthCm": 2.3, "PetalLengthCm": 4.0, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 6.5, "SepalWidthCm": 2.8, "PetalLengthCm": 4.6, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 5.7, "SepalWidthCm": 2.8, "PetalLengthCm": 4.5, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 3.3, "PetalLengthCm": 4.7, "PetalWidthCm": 1.6, "class": "versicolor"},
			{"SepalLengthCm": 4.9, "SepalWidthCm": 2.4, "PetalLengthCm": 3.3, "PetalWidthCm": 1.0, "class": "versicolor"},
			{"SepalLengthCm": 6.6, "SepalWidthCm": 2.9, "PetalLengthCm": 4.6, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 5.2, "SepalWidthCm": 2.7, "PetalLengthCm": 3.9, "PetalWidthCm": 1.4, "class": "versicolor"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 2.0, "PetalLengthCm": 3.5, "PetalWidthCm": 1.0, "class": "versicolor"},
			{"SepalLengthCm": 5.9, "SepalWidthCm": 3.0, "PetalLengthCm": 4.2, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 6.0, "SepalWidthCm": 2.2, "PetalLengthCm": 4.0, "PetalWidthCm": 1.0, "class": "versicolor"},
			{"SepalLengthCm": 6.1, "SepalWidthCm": 2.9, "PetalLengthCm": 4.7, "PetalWidthCm": 1.4, "class": "versicolor"},
			{"SepalLengthCm": 5.6, "SepalWidthCm": 2.9, "PetalLengthCm": 3.6, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 6.7, "SepalWidthCm": 3.1, "PetalLengthCm": 4.4, "PetalWidthCm": 1.4, "class": "versicolor"},
			{"SepalLengthCm": 5.6, "SepalWidthCm": 3.0, "PetalLengthCm": 4.5, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 5.8, "SepalWidthCm": 2.7, "PetalLengthCm": 4.1, "PetalWidthCm": 1.0, "class": "versicolor"},
			{"SepalLengthCm": 6.2, "SepalWidthCm": 2.2, "PetalLengthCm": 4.5, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 5.6, "SepalWidthCm": 2.5, "PetalLengthCm": 3.9, "PetalWidthCm": 1.1, "class": "versicolor"},
			{"SepalLengthCm": 5.9, "SepalWidthCm": 3.2, "PetalLengthCm": 4.8, "PetalWidthCm": 1.8, "class": "versicolor"},
			{"SepalLengthCm": 6.1, "SepalWidthCm": 2.8, "PetalLengthCm": 4.0, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 2.5, "PetalLengthCm": 4.9, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 6.1, "SepalWidthCm": 2.8, "PetalLengthCm": 4.7, "PetalWidthCm": 1.2, "class": "versicolor"},
			{"SepalLengthCm": 6.4, "SepalWidthCm": 2.9, "PetalLengthCm": 4.3, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 6.6, "SepalWidthCm": 3.0, "PetalLengthCm": 4.4, "PetalWidthCm": 1.4, "class": "versicolor"},
			{"SepalLengthCm": 6.8, "SepalWidthCm": 2.8, "PetalLengthCm": 4.8, "PetalWidthCm": 1.4, "class": "versicolor"},
			{"SepalLengthCm": 6.7, "SepalWidthCm": 3.0, "PetalLengthCm": 5.0, "PetalWidthCm": 1.7, "class": "versicolor"},
			{"SepalLengthCm": 6.0, "SepalWidthCm": 2.9, "PetalLengthCm": 4.5, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 5.7, "SepalWidthCm": 2.6, "PetalLengthCm": 3.5, "PetalWidthCm": 1.0, "class": "versicolor"},
			{"SepalLengthCm": 5.5, "SepalWidthCm": 2.4, "PetalLengthCm": 3.8, "PetalWidthCm": 1.1, "class": "versicolor"},
			{"SepalLengthCm": 5.5, "SepalWidthCm": 2.4, "PetalLengthCm": 3.7, "PetalWidthCm": 1.0, "class": "versicolor"},
			{"SepalLengthCm": 5.8, "SepalWidthCm": 2.7, "PetalLengthCm": 3.9, "PetalWidthCm": 1.2, "class": "versicolor"},
			{"SepalLengthCm": 6.0, "SepalWidthCm": 2.7, "PetalLengthCm": 5.1, "PetalWidthCm": 1.6, "class": "versicolor"},
			{"SepalLengthCm": 5.4, "SepalWidthCm": 3.0, "PetalLengthCm": 4.5, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 6.0, "SepalWidthCm": 3.4, "PetalLengthCm": 4.5, "PetalWidthCm": 1.6, "class": "versicolor"},
			{"SepalLengthCm": 6.7, "SepalWidthCm": 3.1, "PetalLengthCm": 4.7, "PetalWidthCm": 1.5, "class": "versicolor"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 2.3, "PetalLengthCm": 4.4, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 5.6, "SepalWidthCm": 3.0, "PetalLengthCm": 4.1, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 5.5, "SepalWidthCm": 2.5, "PetalLengthCm": 4.0, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 5.5, "SepalWidthCm": 2.6, "PetalLengthCm": 4.4, "PetalWidthCm": 1.2, "class": "versicolor"},
			{"SepalLengthCm": 6.1, "SepalWidthCm": 3.0, "PetalLengthCm": 4.6, "PetalWidthCm": 1.4, "class": "versicolor"},
			{"SepalLengthCm": 5.8, "SepalWidthCm": 2.6, "PetalLengthCm": 4.0, "PetalWidthCm": 1.2, "class": "versicolor"},
			{"SepalLengthCm": 5.0, "SepalWidthCm": 2.3, "PetalLengthCm": 3.3, "PetalWidthCm": 1.0, "class": "versicolor"},
			{"SepalLengthCm": 5.6, "SepalWidthCm": 2.7, "PetalLengthCm": 4.2, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 5.7, "SepalWidthCm": 3.0, "PetalLengthCm": 4.2, "PetalWidthCm": 1.2, "class": "versicolor"},
			{"SepalLengthCm": 5.7, "SepalWidthCm": 2.9, "PetalLengthCm": 4.2, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 6.2, "SepalWidthCm": 2.9, "PetalLengthCm": 4.3, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 5.1, "SepalWidthCm": 2.5, "PetalLengthCm": 3.0, "PetalWidthCm": 1.1, "class": "versicolor"},
			{"SepalLengthCm": 5.7, "SepalWidthCm": 2.8, "PetalLengthCm": 4.1, "PetalWidthCm": 1.3, "class": "versicolor"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 3.3, "PetalLengthCm": 6.0, "PetalWidthCm": 2.5, "class": "virginica"},
			{"SepalLengthCm": 5.8, "SepalWidthCm": 2.7, "PetalLengthCm": 5.1, "PetalWidthCm": 1.9, "class": "virginica"},
			{"SepalLengthCm": 7.1, "SepalWidthCm": 3.0, "PetalLengthCm": 5.9, "PetalWidthCm": 2.1, "class": "virginica"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 2.9, "PetalLengthCm": 5.6, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 6.5, "SepalWidthCm": 3.0, "PetalLengthCm": 5.8, "PetalWidthCm": 2.2, "class": "virginica"},
			{"SepalLengthCm": 7.6, "SepalWidthCm": 3.0, "PetalLengthCm": 6.6, "PetalWidthCm": 2.1, "class": "virginica"},
			{"SepalLengthCm": 4.9, "SepalWidthCm": 2.5, "PetalLengthCm": 4.5, "PetalWidthCm": 1.7, "class": "virginica"},
			{"SepalLengthCm": 7.3, "SepalWidthCm": 2.9, "PetalLengthCm": 6.3, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 6.7, "SepalWidthCm": 2.5, "PetalLengthCm": 5.8, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 7.2, "SepalWidthCm": 3.6, "PetalLengthCm": 6.1, "PetalWidthCm": 2.5, "class": "virginica"},
			{"SepalLengthCm": 6.5, "SepalWidthCm": 3.2, "PetalLengthCm": 5.1, "PetalWidthCm": 2.0, "class": "virginica"},
			{"SepalLengthCm": 6.4, "SepalWidthCm": 2.7, "PetalLengthCm": 5.3, "PetalWidthCm": 1.9, "class": "virginica"},
			{"SepalLengthCm": 6.8, "SepalWidthCm": 3.0, "PetalLengthCm": 5.5, "PetalWidthCm": 2.1, "class": "virginica"},
			{"SepalLengthCm": 5.7, "SepalWidthCm": 2.5, "PetalLengthCm": 5.0, "PetalWidthCm": 2.0, "class": "virginica"},
			{"SepalLengthCm": 5.8, "SepalWidthCm": 2.8, "PetalLengthCm": 5.1, "PetalWidthCm": 2.4, "class": "virginica"},
			{"SepalLengthCm": 6.4, "SepalWidthCm": 3.2, "PetalLengthCm": 5.3, "PetalWidthCm": 2.3, "class": "virginica"},
			{"SepalLengthCm": 6.5, "SepalWidthCm": 3.0, "PetalLengthCm": 5.5, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 7.7, "SepalWidthCm": 3.8, "PetalLengthCm": 6.7, "PetalWidthCm": 2.2, "class": "virginica"},
			{"SepalLengthCm": 7.7, "SepalWidthCm": 2.6, "PetalLengthCm": 6.9, "PetalWidthCm": 2.3, "class": "virginica"},
			{"SepalLengthCm": 6.0, "SepalWidthCm": 2.2, "PetalLengthCm": 5.0, "PetalWidthCm": 1.5, "class": "virginica"},
			{"SepalLengthCm": 6.9, "SepalWidthCm": 3.2, "PetalLengthCm": 5.7, "PetalWidthCm": 2.3, "class": "virginica"},
			{"SepalLengthCm": 5.6, "SepalWidthCm": 2.8, "PetalLengthCm": 4.9, "PetalWidthCm": 2.0, "class": "virginica"},
			{"SepalLengthCm": 7.7, "SepalWidthCm": 2.8, "PetalLengthCm": 6.7, "PetalWidthCm": 2.0, "class": "virginica"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 2.7, "PetalLengthCm": 4.9, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 6.7, "SepalWidthCm": 3.3, "PetalLengthCm": 5.7, "PetalWidthCm": 2.1, "class": "virginica"},
			{"SepalLengthCm": 7.2, "SepalWidthCm": 3.2, "PetalLengthCm": 6.0, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 6.2, "SepalWidthCm": 2.8, "PetalLengthCm": 4.8, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 6.1, "SepalWidthCm": 3.0, "PetalLengthCm": 4.9, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 6.4, "SepalWidthCm": 2.8, "PetalLengthCm": 5.6, "PetalWidthCm": 2.1, "class": "virginica"},
			{"SepalLengthCm": 7.2, "SepalWidthCm": 3.0, "PetalLengthCm": 5.8, "PetalWidthCm": 1.6, "class": "virginica"},
			{"SepalLengthCm": 7.4, "SepalWidthCm": 2.8, "PetalLengthCm": 6.1, "PetalWidthCm": 1.9, "class": "virginica"},
			{"SepalLengthCm": 7.9, "SepalWidthCm": 3.8, "PetalLengthCm": 6.4, "PetalWidthCm": 2.0, "class": "virginica"},
			{"SepalLengthCm": 6.4, "SepalWidthCm": 2.8, "PetalLengthCm": 5.6, "PetalWidthCm": 2.2, "class": "virginica"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 2.8, "PetalLengthCm": 5.1, "PetalWidthCm": 1.5, "class": "virginica"},
			{"SepalLengthCm": 6.1, "SepalWidthCm": 2.6, "PetalLengthCm": 5.6, "PetalWidthCm": 1.4, "class": "virginica"},
			{"SepalLengthCm": 7.7, "SepalWidthCm": 3.0, "PetalLengthCm": 6.1, "PetalWidthCm": 2.3, "class": "virginica"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 3.4, "PetalLengthCm": 5.6, "PetalWidthCm": 2.4, "class": "virginica"},
			{"SepalLengthCm": 6.4, "SepalWidthCm": 3.1, "PetalLengthCm": 5.5, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 6.0, "SepalWidthCm": 3.0, "PetalLengthCm": 4.8, "PetalWidthCm": 1.8, "class": "virginica"},
			{"SepalLengthCm": 6.9, "SepalWidthCm": 3.1, "PetalLengthCm": 5.4, "PetalWidthCm": 2.1, "class": "virginica"},
			{"SepalLengthCm": 6.7, "SepalWidthCm": 3.1, "PetalLengthCm": 5.6, "PetalWidthCm": 2.4, "class": "virginica"},
			{"SepalLengthCm": 6.9, "SepalWidthCm": 3.1, "PetalLengthCm": 5.1, "PetalWidthCm": 2.3, "class": "virginica"},
			{"SepalLengthCm": 5.8, "SepalWidthCm": 2.7, "PetalLengthCm": 5.1, "PetalWidthCm": 1.9, "class": "virginica"},
			{"SepalLengthCm": 6.8, "SepalWidthCm": 3.2, "PetalLengthCm": 5.9, "PetalWidthCm": 2.3, "class": "virginica"},
			{"SepalLengthCm": 6.7, "SepalWidthCm": 3.3, "PetalLengthCm": 5.7, "PetalWidthCm": 2.5, "class": "virginica"},
			{"SepalLengthCm": 6.7, "SepalWidthCm": 3.0, "PetalLengthCm": 5.2, "PetalWidthCm": 2.3, "class": "virginica"},
			{"SepalLengthCm": 6.3, "SepalWidthCm": 2.5, "PetalLengthCm": 5.0, "PetalWidthCm": 1.9, "class": "virginica"},
			{"SepalLengthCm": 6.5, "SepalWidthCm": 3.0, "PetalLengthCm": 5.2, "PetalWidthCm": 2.0, "class": "virginica"},
			{"SepalLengthCm": 6.2, "SepalWidthCm": 3.4, "PetalLengthCm": 5.4, "PetalWidthCm": 2.3, "class": "virginica"},
			{"SepalLengthCm": 5.9, "SepalWidthCm": 3.0, "PetalLengthCm": 5.1, "PetalWidthCm": 1.8, "class": "virginica"}
		],
		["SepalLengthCm", "SepalWidthCm", "PetalLengthCm", "PetalWidthCm"],
		[Constants.ACT_FUNCS.softmax]
	],
	"Cultivos": [
		[
			{"hidratación": 0.85, "luz": 0.90, "nutrientes": 0.75, "temperatura": 0.60, "crecimiento": 12.45},
			{"hidratación": 0.20, "luz": 0.50, "nutrientes": 0.30, "temperatura": 0.40, "crecimiento": 2.10},
			{"hidratación": 0.55, "luz": 0.10, "nutrientes": 0.60, "temperatura": 0.55, "crecimiento": 4.35},
			{"hidratación": 0.95, "luz": 0.95, "nutrientes": 0.90, "temperatura": 0.85, "crecimiento": 15.80},
			{"hidratación": 0.40, "luz": 0.40, "nutrientes": 0.15, "temperatura": 0.90, "crecimiento": 3.25},
			{"hidratación": 0.70, "luz": 0.75, "nutrientes": 0.50, "temperatura": 0.50, "crecimiento": 9.15},
			{"hidratación": 0.10, "luz": 0.85, "nutrientes": 0.45, "temperatura": 0.25, "crecimiento": 1.50},
			{"hidratación": 0.60, "luz": 0.60, "nutrientes": 0.80, "temperatura": 0.70, "crecimiento": 10.20}
		],
		["hidratación", "luz", "nutrientes", "temperatura"],
		[Constants.ACT_FUNCS.identity]
	]
}


var selected_option: String
var datast_info: Array[Dictionary]
var attrs_info: Array[String]
var target_attrs_info: Array[String]
var act_func_restriction: int
var nn_restrictions: Dictionary[int, int]
var target_column_names: Array[String] = []
var class_decoder_map: Dictionary = {}
var csv_display_name: String = ""
var csv_headers: Array[String] = []
var csv_column_types: Dictionary = {}
var csv_raw_data: Array[Dictionary] = []
var _web_csv_callback: Variant
var _is_selecting_inference_dataset: bool = false
var _required_inference_attrs: Array[String] = []
var _required_inference_target_attrs: Array[String] = []


func _ready() -> void:

	entrenar_button.disabled = true
	target_scroll_container.visible = false
	entrenar_button.pressed.connect(_on_entrenar_button_pressed)

	for button: Button in hboxcontainer.get_children():
		button.pressed.connect(_on_button_pressed.bind(button.text))

	SignalsObserver.train_nn.connect(_on_nn_train_started)
	SignalsObserver.prepare_nn_inference_dataset_selection.connect(show_for_inference)

func _on_entrenar_button_pressed():
	if _is_selecting_inference_dataset and not _validate_inference_dataset_structure():
		return

	SignalsObserver.dataset_selected_nn.emit(datast_info, attrs_info, target_attrs_info, nn_restrictions)
	visible = false

func _on_nn_train_started():
	_is_selecting_inference_dataset = false
	visible = false


func show_for_inference(required_attrs: Array[String], required_target_attrs: Array[String]) -> void:
	restart_dataset_selection()
	_is_selecting_inference_dataset = true
	_required_inference_attrs = required_attrs.duplicate()
	_required_inference_target_attrs = required_target_attrs.duplicate()
	entrenar_button.text = "Cargar Dataset"
	visible = true
	await get_tree().process_frame
	position = (get_parent_area_size() - size) / 2


func restart_dataset_selection() -> void:
	selected_option = ""
	datast_info = []
	attrs_info = []
	target_attrs_info = []
	act_func_restriction = 0
	nn_restrictions = {}
	class_decoder_map = {}
	_reset_csv_target_selector()
	informative_text.text = "Aún no se ha seleccionado dataset"
	informative_text.label_settings.font_color = color_good
	entrenar_button.text = "Seleccionar Dataset"
	entrenar_button.disabled = true


func _on_button_pressed(option: String):
	selected_option = option
	_on_dataset_selected()
	if option == "Csv":
		await get_tree().create_timer(1.0).timeout


## Changes the state of the selector depending on
## the selection, of if the csv was read without problem
func _on_dataset_selected():
	match selected_option:
		"Cargar\nCsv":
			_reset_csv_target_selector()
			_load_csv()
		_:  # If a default dataset was selected
			_reset_csv_target_selector()

			# Save its info on the relevant variables
			datast_info = safe_get_array_of_dicts(DICT_OF_DATASETS[selected_option][0])
			attrs_info = safe_get_array_of_strings(DICT_OF_DATASETS[selected_option][1])
			target_attrs_info = _get_target_attrs_from_inputs(datast_info, attrs_info)
			act_func_restriction = DICT_OF_DATASETS[selected_option][2][0]

			# Extract its analysis to ensure the correct change of informative text
			# and restrictions over the nn
			var target_info = _analyze_and_prepare_targets(datast_info, target_attrs_info)
			if not target_info["ok"]:
				informative_text.text = target_info["message"]
				informative_text.label_settings.font_color = color_error
				entrenar_button.disabled = true
				return

			# Set the stablished restrictions
			nn_restrictions = {0: attrs_info.size(), -1: target_info["count"], -2: act_func_restriction}  # Restrictions for "in" and "out"

			informative_text.text = _build_dataset_summary_text(selected_option, attrs_info.size(), target_info)
			informative_text.label_settings.font_color = color_good
			entrenar_button.disabled = false


## Opens a window to select a csv, reads it
## and returns and array with each entity
## on the csv as a dictionary.
func _load_csv():
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		_load_csv_from_browser()
		return

	var file_dialog = FileDialog.new()

	# Config to access to the file system
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.csv ; CSV Files"])

	# Use the native file selector
	# if it cant, will load the godot default
	if "use_native_dialog" in file_dialog:
		file_dialog.use_native_dialog = true

	# Connect to the selection signal
	file_dialog.file_selected.connect(func(file_path: String):
		_parse_csv(file_path)
		file_dialog.queue_free()
	)

	# Clear if canceled
	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)

	add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.4)


func _load_csv_from_browser():
	var js_bridge = Engine.get_singleton("JavaScriptBridge")
	_web_csv_callback = js_bridge.create_callback(_on_web_csv_loaded)
	js_bridge.get_interface("window").godotCsvUploadCallback = _web_csv_callback

	js_bridge.eval(
		"""
		(function () {
			const input = document.createElement("input");
			input.type = "file";
			input.accept = ".csv,text/csv";
			input.style.display = "none";
			input.addEventListener("change", function () {
				const file = input.files && input.files[0];
				if (!file) {
					input.remove();
					return;
				}
				const reader = new FileReader();
				reader.onload = function (event) {
					window.godotCsvUploadCallback(event.target.result, file.name);
					input.remove();
				};
				reader.onerror = function () {
					window.godotCsvUploadCallback("", file.name, "No se pudo leer el archivo.");
					input.remove();
				};
				reader.readAsText(file);
			});
			document.body.appendChild(input);
			input.click();
		})();
		""",
		true
	)


func _on_web_csv_loaded(args: Array) -> void:
	if args.size() >= 3 and not str(args[2]).is_empty():
		informative_text.text = str(args[2])
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	if args.is_empty() or str(args[0]).is_empty():
		informative_text.text = "No se seleccionó ningún CSV."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	var csv_text := str(args[0])
	var display_name := "dataset.csv"
	if args.size() >= 2 and not str(args[1]).is_empty():
		display_name = str(args[1])

	var temp_path := "user://selected_nn_dataset.csv"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		informative_text.text = "Error preparando el CSV: %d" % error
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	file.store_string(csv_text)
	file.close()
	_parse_csv(temp_path, display_name)


## Checks if the csv selected has the correct format
## and parses it to the corresponding file type
func _parse_csv(file_path, display_name: String = ""):
	var file = FileAccess.open(file_path, FileAccess.READ)

	# If there were a problem with the file
	if file == null:
		var error = FileAccess.get_open_error()
		informative_text.text = "Error abriendo el archivo: %d" % error
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	# Get columns
	var headers = safe_get_array_of_strings(file.get_csv_line() as Array)
	if headers.size() < 2:
		file.close()
		informative_text.text = "El CSV debe tener al menos dos columnas."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	# Each data its going to be in this Array
	var data_array: Array[Dictionary] = []

	# While true, but is while there is lines to read
	while true:
		var row = file.get_csv_line()
		if file.eof_reached():
			break  # Because the eof_reached only goes to true once it tries to reed over the lengh of the file

		if row.is_empty():
			continue

		# Map column with value for each row
		var row_dict = {}
		for i in range(min(headers.size(), row.size())):
			row_dict[headers[i]] = row[i]

		data_array.append(row_dict)

	file.close()

	if data_array.is_empty():
		informative_text.text = "El dataset no contiene filas."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	if display_name.is_empty():
		display_name = file_path.get_file()

	csv_raw_data = data_array
	csv_headers = headers
	csv_display_name = display_name
	csv_column_types = _infer_column_types(csv_raw_data, csv_headers)
	_show_csv_target_selector(csv_headers)


## Processes the target columns and returns the information needed by the UI
## and NN restrictions. Classification targets are encoded in-place.
func _analyze_and_prepare_targets(data_array: Array[Dictionary], target_cols: Array[String]) -> Dictionary:
	if data_array.is_empty():
		return {"ok": false, "message": "El dataset no contiene filas."}
	if target_cols.is_empty():
		return {"ok": false, "message": "Seleccione variable/s objetivo."}

	# Datasets coming from constants can contain read-only dictionaries.
	# Clone each row to a mutable dictionary before any in-place update.
	for i in range(data_array.size()):
		var mutable_row: Dictionary = data_array[i].duplicate(true)
		data_array[i] = mutable_row

	var column_types: Dictionary = _infer_column_types(data_array, target_cols)
	for target_col in target_cols:
		if not column_types.has(target_col):
			return {"ok": false, "message": "No se detectó la columna objetivo %s." % target_col}

	var has_string_values = false
	var has_float_values = false
	var has_int_values = false

	for target_col in target_cols:
		match column_types[target_col]:
			"string":
				has_string_values = true
			"float":
				has_float_values = true
			"int":
				has_int_values = true

		_normalize_column_values(data_array, target_col)

	if target_cols.size() > 1 and has_string_values:
		return {"ok": false, "message": "Solo puede seleccionarse una variable categórica."}

	var info: Dictionary = {
		"ok": true,
		"target_cols": target_cols.duplicate(),
		"kind": "classification",
		"count": 0,
	}

	class_decoder_map = {}

	if has_string_values:
		class_decoder_map = one_hot_encode_string_targets(data_array, target_cols[0])
		Variables.nn_output_class_decoder = class_decoder_map
		info["kind"] = "classification"
		info["count"] = class_decoder_map.size()
	elif target_cols.size() == 1 and has_int_values and not has_float_values:
		class_decoder_map = encode_int_targets(data_array, target_cols[0])
		Variables.nn_output_class_decoder = class_decoder_map
		info["kind"] = "classification"
		info["count"] = class_decoder_map.size()
	else:
		Variables.nn_output_class_decoder = {}
		info["kind"] = "regression"
		info["count"] = target_cols.size()

	target_column_names = target_cols.duplicate()
	return info


func _normalize_numeric_value(value: Variant) -> Variant:
	if value is String:
		var text: String = value.strip_edges()
		if text.is_valid_int():
			return int(text)
		if text.is_valid_float():
			return float(text)
	return value


func _normalize_column_values(data_array: Array[Dictionary], column_name: String) -> void:
	for row in data_array:
		if row.has(column_name):
			row[column_name] = _normalize_numeric_value(row[column_name])


func _infer_column_types(data_array: Array[Dictionary], columns: Array[String]) -> Dictionary:
	var column_types: Dictionary = {}
	for column_name in columns:
		var has_string_values := false
		var has_float_values := false
		var has_int_values := false

		for row in data_array:
			if not row.has(column_name):
				continue

			var normalized_value = _normalize_numeric_value(row[column_name])
			match typeof(normalized_value):
				TYPE_STRING:
					has_string_values = true
				TYPE_FLOAT:
					has_float_values = true
				TYPE_INT:
					has_int_values = true

		if has_string_values:
			column_types[column_name] = "string"
		elif has_float_values:
			column_types[column_name] = "float"
		elif has_int_values:
			column_types[column_name] = "int"
		else:
			column_types[column_name] = "string"

	return column_types


func _reset_csv_target_selector() -> void:
	target_scroll_container.visible = false
	for child in target_selector.get_children():
		target_selector.remove_child(child)
		child.queue_free()

	csv_display_name = ""
	csv_headers = []
	csv_column_types = {}
	csv_raw_data = []
	target_attrs_info = []
	target_column_names = []
	Variables.nn_output_class_decoder = {}
	entrenar_button.disabled = true


func _show_csv_target_selector(headers: Array[String]) -> void:
	target_scroll_container.visible = true
	for child in target_selector.get_children():
		target_selector.remove_child(child)
		child.queue_free()

	csv_headers = headers.duplicate()
	csv_column_types = _infer_column_types(csv_raw_data, csv_headers)
	
	var select_target_variable_label: Label = Label.new()
	select_target_variable_label.text = "Seleccione Variable/s objetivo"
	target_selector.add_child(select_target_variable_label)
	for header in csv_headers:
		var check_button := CheckButton.new()
		check_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		check_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		check_button.text = header
		check_button.toggled.connect(_on_target_check_toggled)
		target_selector.add_child(check_button)

	informative_text.text = "Seleccione variable/s objetivo"
	informative_text.label_settings.font_color = color_good
	entrenar_button.disabled = true


func _on_target_check_toggled(_button_pressed: bool) -> void:
	var selected_targets: Array[String] = _get_selected_target_columns()
	_update_target_buttons_state(selected_targets)

	if selected_targets.is_empty():
		informative_text.text = "Seleccione variable/s objetivo"
		informative_text.label_settings.font_color = color_good
		entrenar_button.disabled = true
		return

	if selected_targets.size() >= csv_headers.size():
		informative_text.text = "Debe quedar al menos un atributo de entrada."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	var prepared_data := safe_get_array_of_dicts(csv_raw_data)
	var input_attrs := _get_input_attrs_from_targets(csv_headers, selected_targets)
	var target_info := _analyze_and_prepare_targets(prepared_data, selected_targets)
	if not target_info["ok"]:
		informative_text.text = target_info["message"]
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	_encode_categorical_input_columns(prepared_data, input_attrs)

	datast_info = prepared_data
	attrs_info = input_attrs
	target_attrs_info = selected_targets
	act_func_restriction = Constants.ACT_FUNCS.softmax if target_info["kind"] == "classification" else Constants.ACT_FUNCS.identity
	nn_restrictions = {0: attrs_info.size(), -1: target_info["count"], -2: act_func_restriction}

	if _selected_targets_include_categorical(selected_targets):
		informative_text.text = "Seleccionada variable categórica,\n no seleccione más variables"
	else:
		informative_text.text = _build_dataset_summary_text(csv_display_name, attrs_info.size(), target_info)
	informative_text.label_settings.font_color = color_good
	entrenar_button.disabled = false


func _validate_inference_dataset_structure() -> bool:
	var missing_attrs: Array[String] = _get_missing_names(_required_inference_attrs, attrs_info)
	if not missing_attrs.is_empty():
		informative_text.text = "El dataset de inferencia no tiene estos atributos de entrada: %s" % ", ".join(missing_attrs)
		informative_text.label_settings.font_color = color_error
		return false

	var extra_attrs: Array[String] = _get_missing_names(attrs_info, _required_inference_attrs)
	if not extra_attrs.is_empty():
		informative_text.text = "El dataset de inferencia tiene atributos de entrada extra: %s" % ", ".join(extra_attrs)
		informative_text.label_settings.font_color = color_error
		return false
	if attrs_info != _required_inference_attrs:
		informative_text.text = "El orden de los atributos de entrada no coincide con el usado al entrenar."
		informative_text.label_settings.font_color = color_error
		return false

	var missing_targets: Array[String] = _get_missing_names(_required_inference_target_attrs, target_attrs_info)
	if not missing_targets.is_empty():
		informative_text.text = "El dataset de inferencia no tiene estas salidas esperadas: %s" % ", ".join(missing_targets)
		informative_text.label_settings.font_color = color_error
		return false

	var extra_targets: Array[String] = _get_missing_names(target_attrs_info, _required_inference_target_attrs)
	if not extra_targets.is_empty():
		informative_text.text = "El dataset de inferencia tiene salidas esperadas extra: %s" % ", ".join(extra_targets)
		informative_text.label_settings.font_color = color_error
		return false
	if target_attrs_info != _required_inference_target_attrs:
		informative_text.text = "El orden de las salidas esperadas no coincide con el usado al entrenar."
		informative_text.label_settings.font_color = color_error
		return false

	return true


func _get_missing_names(required_names: Array[String], available_names: Array[String]) -> Array[String]:
	var missing_names: Array[String] = []
	for required_name in required_names:
		if not available_names.has(required_name):
			missing_names.append(required_name)
	return missing_names


func _get_selected_target_columns() -> Array[String]:
	var selected_targets: Array[String] = []
	for child in target_selector.get_children():
		if child is CheckButton and child.button_pressed:
			selected_targets.append(child.text)
	return selected_targets


func _update_target_buttons_state(selected_targets: Array[String]) -> void:
	var has_selection := not selected_targets.is_empty()
	var selected_type := ""
	if has_selection:
		selected_type = str(csv_column_types.get(selected_targets[0], "string"))

	for child in target_selector.get_children():
		if not (child is CheckButton):
			continue

		var check_button: CheckButton = child
		var button_type := str(csv_column_types.get(check_button.text, "string"))
		check_button.disabled = false

		if not check_button.button_pressed and has_selection:
			check_button.disabled = selected_type == "string" or button_type == "string"

	if has_selection and selected_type == "string":
		informative_text.text = "Seleccionada variable categórica,\n no seleccione más variables"
		informative_text.label_settings.font_color = color_good


func _selected_targets_include_categorical(selected_targets: Array[String]) -> bool:
	for target in selected_targets:
		if csv_column_types.get(target, "") == "string":
			return true
	return false


func _get_input_attrs_from_targets(headers: Array[String], target_cols: Array[String]) -> Array[String]:
	var input_attrs: Array[String] = []
	for header in headers:
		if not target_cols.has(header):
			input_attrs.append(header)
	return input_attrs


func _get_target_attrs_from_inputs(data_array: Array[Dictionary], input_attrs: Array[String]) -> Array[String]:
	var target_attrs: Array[String] = []
	if data_array.is_empty():
		return target_attrs

	for key in data_array[0].keys():
		var key_text := str(key)
		if not input_attrs.has(key_text):
			target_attrs.append(key_text)

	return target_attrs


func _encode_categorical_input_columns(data_array: Array[Dictionary], input_attrs: Array[String]) -> void:
	var column_types: Dictionary = _infer_column_types(data_array, input_attrs)
	for input_attr in input_attrs:
		if column_types.get(input_attr, "") != "string":
			_normalize_column_values(data_array, input_attr)
			continue

		var value_to_id: Dictionary = {}
		var next_id := 0
		for row in data_array:
			if not row.has(input_attr):
				continue

			var value_text := str(row[input_attr])
			if not value_to_id.has(value_text):
				value_to_id[value_text] = next_id
				next_id += 1
			row[input_attr] = value_to_id[value_text]


func _build_dataset_summary_text(dataset_name: String, input_attrs_count: int, target_info: Dictionary) -> String:
	var summary = "Se cargó el dataset %s.\nTiene %d atributos de entrada" % [dataset_name, input_attrs_count]
	if target_info["kind"] == "classification":
		var classes_count: int = int(target_info["count"])
		summary += " y %d clases,\nse establecerán %d neuronas de entrada y %d de salida\ny se recomienda función de activación softmax\npara la capa de salida" % [classes_count, input_attrs_count, classes_count]
	else:  # regression
		summary += " y %d valores a predecir" % int(target_info["count"])
	return summary


## Encodes string labels to integer ids and returns a decoder map: int -> original string.
func one_hot_encode_string_targets(data_array: Array[Dictionary], target_col_name: String) -> Dictionary:
	var string_to_int: Dictionary = {}
	var int_to_string: Dictionary = {}
	var current_index := 0

	for row in data_array:
		if not row.has(target_col_name):
			continue

		var label_text := str(row[target_col_name])
		if not string_to_int.has(label_text):
			string_to_int[label_text] = current_index
			int_to_string[current_index] = label_text
			current_index += 1

		row[target_col_name] = string_to_int[label_text]

	print("[LOG] Encoded %d string target classes for NN softmax output" % int_to_string.size())
	return int_to_string


## Encodes integer labels to contiguous class ids and returns a decoder map:
## output neuron id -> original integer value.
func encode_int_targets(data_array: Array[Dictionary], target_col_name: String) -> Dictionary:
	var unique_values: Array[int] = []
	var seen_values: Dictionary = {}

	for row in data_array:
		if not row.has(target_col_name):
			continue

		var original_value: int = int(row[target_col_name])
		if not seen_values.has(original_value):
			seen_values[original_value] = true
			unique_values.append(original_value)

	unique_values.sort()

	var original_to_class_id: Dictionary = {}
	var class_id_to_original: Dictionary = {}
	for class_id in range(unique_values.size()):
		var original_class_value: int = unique_values[class_id]
		original_to_class_id[original_class_value] = class_id
		class_id_to_original[class_id] = original_class_value

	for row in data_array:
		if row.has(target_col_name):
			row[target_col_name] = original_to_class_id[int(row[target_col_name])]

	print("[LOG] Encoded %d integer target classes for NN softmax output" % class_id_to_original.size())
	return class_id_to_original


## Takes an Array and ensures that it is returned as and Array[Dictionay]
## At the time of writing this code, Godot does not suppot nested complex types
## such as Array[Array[Dictionary]].
## So its necessary this function to keep the hard typed in other parts of the code
## where the nesting does not goes that deep.
func safe_get_array_of_dicts(data: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if data is Array:
		for item in data:
			if item is Dictionary:
				var mutable_item: Dictionary = item.duplicate(true)
				result.append(mutable_item)
			else:
				print("An element on the so called \"Array of Dictionary\" isn't a Dictionary: {item}")

	return result


## Takes an Array and ensures that it is returned as and Array[Dictionay]
## At the time of writing this code, Godot does not suppot nested complex types
## such as Array[Array[Dictionary]].
## So its necessary this function to keep the hard typed in other parts of the code
## where the nesting does not goes that deep.
func safe_get_array_of_strings(data: Array) -> Array[String]:
	var result: Array[String] = []

	if data is Array:
		for item in data:
			if item is String:
				result.append(item)
			else:
				print("An element on the so called \"Array of String\" isn't a String: {item}")

	return result
