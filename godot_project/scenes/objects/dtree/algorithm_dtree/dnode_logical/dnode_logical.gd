extends RefCounted
class_name DNodeLogical

# Helper class for decision tree algorithm logic
# Mirrors the DecisionNode class from Python

var attribute: String = ""  # Attribute used to split the data
var children: Dictionary = {}  # attribute_value -> child DNodeLogical
var is_leaf: bool = false  # True if this node is a leaf
var label: String = ""  # Class label if leaf
var tree_node_id: int = -1  # ID in the visual tree (assigned when created)

func _init(p_attribute: String = "", p_is_leaf: bool = false, p_label: String = ""):
	attribute = p_attribute
	is_leaf = p_is_leaf
	label = p_label

func add_child(value, node: DNodeLogical) -> void:
	children[value] = node
