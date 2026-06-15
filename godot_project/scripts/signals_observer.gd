extends Node


# Signals

@warning_ignore_start("unused_signal")


# dtree
signal dtree_node_selected(details: Dictionary)
signal dtree_clicked_node_changed(node_id: int)
signal dtree_eval_data_selected(details: Dictionary)
signal dtree_eval_data_advanced(node_type: int, eval_data_info: Dictionary, node_info: Dictionary)
signal dtree_training_finished



signal dataset_selected(data:Array[Dictionary], attrs: Array[String])
signal dataset_selected_nn(data:Array[Dictionary], attrs: Array[String], target_attrs: Array[String], nn_restrictions: Dictionary[int, int])

signal start_evaluation(data:Array[Dictionary])

signal drop_data()

signal all_data_droped()

# navigation
signal return_to_main_menu


# scenes/interface/nn/create_nn_menu/create_nn_menu.gd
signal load_nn
signal reload_nn
signal train_nn
signal update_nn_layer(layer_id: int)
signal establish_nn_dset_restrictions(restrictions: Dictionary[int, int])
signal prepare_nn_inference_dataset_selection(attrs: Array[String], target_attrs: Array[String])

# nn
signal add_layer
signal remove_layer
signal nn_inform_size(nn_position: Vector2)

# layer
signal add_neuron(layer_id: int)
signal remove_neuron(layer_id: int)

# neuron
signal info_neuron(neuron_id: int, layer_id: int)
signal nn_neuron_text_changed(layer_id: int, neuron_id: int, new_text: String)
signal nn_clicked_neuron_changed(layer_id: int, neuron_id: int)

# dense
signal update_conections(layer_id: int, num_of_neurons: int)
signal update_all_conections

# nn_view
signal nn_view_want_nn_size
signal nn_view_set_nn_position(new_position: Vector2)

# algorithm nn
signal forward_step_completed(layer_idx, neuron_idx, output_value)
signal backward_step_completed(layer_idx, neuron_idx, delta_value)
signal weight_updated(layer_idx, neuron_idx, weight_idx, new_value)
signal nn_train_finished
signal nn_layer_resalted(layer_idx: int)
signal nn_inference_ready
signal nn_inference_finished
signal setup_nn_eval_data(container_role: String, value_keys: Array[String])
signal add_change_eval_data(container_role: String, dict_of_data: Dictionary, animate_appear: bool)
signal nn_eval_data_enter_network(container_role: String)
signal nn_eval_data_output_leave(container_role: String)
signal nn_eval_data_expected_to_error(container_role: String, dict_of_data: Dictionary)
signal nn_eval_data_error_return(container_role: String)
signal nn_eval_data_animation_finished(container_role: String, animation_name: String)
signal clear_nn_eval_data(container_role: String)

# panel algorithm nn
signal train_nn_next_neuron(neuron_id: int, layer_id: int)
signal train_nn_next_layer(layer_id: int)
signal train_nn_next_step
signal train_nn_complete
signal inference_nn_start

# window_nn
signal nn_resalted_neuron_forward(neuron_id: int, layer_id: int, input_values: Array, output_value: float)
signal nn_resalted_neuron_backward(neuron_id: int, layer_id: int, backward_info: Dictionary)
signal nn_resalted_layer_forward(layer_info: Dictionary)
signal nn_resalted_layer_backward(layer_info: Dictionary)
signal nn_resalted_data_loaded(data_info: Dictionary)
signal nn_resalted_error_calculated(error_info: Dictionary)
signal nn_resalted_error_returned(error_info: Dictionary)
signal nn_resalted_data_step(step_info: Dictionary)

# panel training nn
signal save_nn

# panel export format
signal export_onnx
signal export_nnef

# window
signal clear_window

@warning_ignore_restore("unused_signal")
