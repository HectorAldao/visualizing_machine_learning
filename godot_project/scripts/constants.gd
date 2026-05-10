extends Node

const SCENES: Dictionary[String, String] = {
	"main_menu": "uid://j220721ca3np",
	"dtree_view": "uid://dr3bg1sj3y1nu",
	"dtree": "uid://ci7giiq21giw1",
	"algorithm_dtree": "uid://tg5i3lmvlt3s",
	"controller_dtree": "uid://5h4ba5ys8aml",
	"panel_algorithm_dtree": "uid://c2a76qive15yf",
	"conection": "uid://bvm44kn2u2552",
	"conection_container": "uid://ci7giiq21giw1",
	"dnode": "uid://b54b7e4e3ojl8",
	"barschart": "uid://pycmc75uwvq0",
	"eval_data": "uid://dlu0e0xckfe3q",
	"eval_data_container": "uid://dli7f1or8hqm6",
	"nn_eval_data":"uid://0nval2e1ex2v",

	"nn_view": "uid://cxtlfe3b8dfux",
	"layer": "uid://bs14tnn0hedwc",
	"neuron": "uid://re6neyyt2frx",
	"neuronsinlayer": "uid://e7nvan78e0pf",

	"popupinfo": "uid://ccqd5qw3k7i4y",

	"latex_formula": "uid://c0p8glq0rsesw",
	}

const THEMES: Dictionary[String, String] = {
	"leaf": "uid://vanr6vum3qcu",
	"noleaf": "uid://cmsv2q8q35lvy",
	"nodedefault": "uid://dxluxv1xceiqb",
	"resalted_neuron": "uid://b5ecvrwlunl4u"
}

const REFCOUNTS: Dictionary[String, String] = {
	"neural_network_logical": "uid://be7g05yi62lb2",
}

const NN_LIMITS: Dictionary[String, int] = {
	"max_layers" = 6,
	"max_neurons" = 6,
}

const ACT_FUNCS: Dictionary[String, int] = {
	"relu": 0,
	"sigmoid": 1,
	"softmax": 2,
	"identity": 3,
}

const LOSS_FUNCS: Dictionary[String, int] = {
	"mse": 0,
	"coss_entr": 1,
}

const NN_REDRAW_CONECTIONS: bool = true

const NN_CONNECTION_RANDOM_MULT: float = 0.1
const NN_CONNECTION_VARIANCE: float = 0.5
const NN_CONECTION_SCALE: float = 20
const NN_CONECTION_BIAS: float = 0
const NN_MAX_WIDTH: float = 5

const NN_EVAL_DATA_DISPLAY_DECIMALS: int = 3
const NN_EVAL_DATA_GAP: float = 24.0
const NN_EVAL_DATA_EXPECTED_GAP: float = 56.0
const NN_EVAL_DATA_APPEAR_OFFSET: Vector2 = Vector2(-32.0, 0.0)
const NN_EVAL_DATA_ENTER_OFFSET: Vector2 = Vector2(42.0, 0.0)
const NN_EVAL_DATA_ERROR_RETURN_OFFSET: Vector2 = Vector2(-42.0, 0.0)
const NN_EVAL_DATA_APPEAR_TIME: float = 0.25
const NN_EVAL_DATA_APPEAR_FADE_TIME: float = 0.2
const NN_EVAL_DATA_MOVE_FADE_TIME: float = 0.35
const NN_EVAL_DATA_EXPECTED_FADE_TIME: float = 0.25
const NN_EVAL_DATA_NEXT_STEP_DELAY: float = 0.5
const NN_EVAL_DATA_TITLE_GAP: float = 18.0

const NN_LEARNINGRATE: float = 0.001
