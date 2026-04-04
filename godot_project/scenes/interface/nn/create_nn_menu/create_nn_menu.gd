extends PanelContainer

@onready var vboxcont: VBoxContainer = $VBoxContainer
@onready var new_neurons_layer: HBoxContainer = $VBoxContainer/NewNeuronsLayer

var neurons_per_layer: Dictionary[int, int] = {0: 1, -1: 1}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for c in vboxcont.get_children():

		if c is Button:
			c.pressed.connect(_on_button_pressed.bind(c.name))

		elif c is HBoxContainer:

			if c.name == "NewNeuronsLayer":
				# The NewNeuronsLayer must have no preloaded submenus
				for child in c.get_children():
					c.remove_child(child)
					child.queue_free()
				continue

			else:
				var plus_button: Button = c.get_child(0).get_child(0)
				var minus_button: Button = c.get_child(0).get_child(1)
				var text_edit: TextEdit = c.get_child(1)

				plus_button.pressed.connect(_on_plus_pressed.bind(c))
				minus_button.pressed.connect(_on_minus_pressed.bind(c))
				text_edit.text_changed.connect(_on_text_changed.bind(c))



func _on_button_pressed(which: String) -> void:
	print("[LOG] Signal 'create nn menu button' emited by %s" % which)
	SignalsObserver.create_nn_menu_button.emit(which)


## When the text is changed, there must change 1 or 2 things.
## Allways must change the dictionary "neurons_per_layer" respecting
## the limitations of each TextEdit,
## and in the case of a change in the number of layers, there must
## be changed the number of children of "NewNeuronsLayer".
func _on_text_changed(which: HBoxContainer) -> void:

	var submenu_name: String = which.name
	var textedit: TextEdit = which.get_child(1)
	var num_of_wanted_layers: int = int(textedit.text)

	match submenu_name:
		"NeuronsIn":

			# There can't be less than a neuron
			if num_of_wanted_layers < 1:
				textedit.text = "1"
				neurons_per_layer[0] = 1
				return

			neurons_per_layer[0] = int(num_of_wanted_layers)

		"NeuronsOut":

			# There can't be less than a neuron
			if num_of_wanted_layers < 1:
				textedit.text = "1"
				neurons_per_layer[-1] = 1
				return

			neurons_per_layer[-1] = int(num_of_wanted_layers)

		"Layers":
			
			var old_num_of_hidden_layers: int = neurons_per_layer.size() - 2  # Minus the in-layer and out-layer

			# Because the number can be changed by hand (not peressing the plus and minus)
			# the amount of times that the change must be called is not predecible
			var num_of_neurons_changed: int = num_of_wanted_layers - old_num_of_hidden_layers

			# If new layers where added
			if num_of_neurons_changed > 0:

				# The range must be iterated in reverse because the childs must be added in order.
				# And because we have the amount of neurons wanted, is easier to just subtract to that
				# number a decreasing amount of neurons that must be changed instead of add one by one
				# checking with an "if" if the number is enough.
				for current_neurons_left_to_add in range(num_of_neurons_changed, 0, -1):

					# For each submenu, its index is the amount of neurons before it beeing added
					# (because its index is -1 the id of the neuron, that starts in 1 instead of 0
					# (because the 0 is for the in-layer, that is not a hidden-one)),
					# or what is the same: neurons_now = neurons_wanted - neurons_left_to_add
					var new_submenu_index: int = num_of_wanted_layers - current_neurons_left_to_add
					var new_submenu_neuron_id: int = new_submenu_index + 1

					# A submenu of neurons in that layer is created
					var submenu_neurons_in_layer: NeuronsInLayer = NeuronsInLayer.newone(new_submenu_neuron_id)

					# And added as child
					new_neurons_layer.add_child(submenu_neurons_in_layer)

					# Then, the dictionary is uptaded
					neurons_per_layer[new_submenu_neuron_id] = 0

			# If layers were deleted
			elif num_of_neurons_changed < 0:

				num_of_neurons_changed *= -1

				print("num_of_neurons_changed ", num_of_neurons_changed)  #debug
				for current_neurons_left_to_remove in range(num_of_neurons_changed, 0, -1):
					print("current_neurons_left_to_remove ", current_neurons_left_to_remove)  #debug

					var submenu_index_to_remove: int = num_of_wanted_layers + current_neurons_left_to_remove - 1
					var submenu_neuron_id_to_remove: int = submenu_index_to_remove + 1

					# Each subnmenu's index $n$ corresponds to a neuron id $n+1$: submenu 0 -> neuron id 1
					# when removing a neuron, the variable "num" (num of neurons) is equal to the index
					# of the layer that is needed to be deleted.
					# Thats why the "get_child" uses "num" as the index
					var submenu_neurons_in_layer_to_remove: NeuronsInLayer = new_neurons_layer.get_child(submenu_index_to_remove)

					# Then the child is removed from the parent and deleted from the scene
					new_neurons_layer.remove_child(submenu_neurons_in_layer_to_remove)
					submenu_neurons_in_layer_to_remove.queue_free()

					# And the dictionary is updated
					neurons_per_layer.erase(submenu_neuron_id_to_remove)

			else:
				# This print is only to check if the "text_changed" signal is emited
				# even if the text is "changed" to be the same.
				print("[LOG] The number of neurons to wich the text changed its the same")  #debug


func _on_plus_pressed(which: HBoxContainer) -> void:

	var textedit: TextEdit = which.get_child(1)
	textedit.text = str(int(textedit.text) + 1)
	textedit.text_changed.emit()


func _on_minus_pressed(which: HBoxContainer) -> void:

	var submenu_name: String = which.name
	var textedit: TextEdit = which.get_child(1)
	var num: int = int(textedit.text)


	match submenu_name:
		"Layers":  # There can be no hidden layers
			if num > 0:
				textedit.text = str(num - 1 )
				textedit.text_changed.emit()
		_:  # The number of neurons of in-layer and out-layer cant be less than 1
			if num > 1:
				textedit.text = str(num - 1 )
				textedit.text_changed.emit()


func _update_neuron() -> void:
	pass
