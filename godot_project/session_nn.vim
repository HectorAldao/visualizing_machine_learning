let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
doautoall SessionLoadPre
silent only
silent tabonly
cd ~/eu/tfg/godot_project
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
set shortmess+=aoO
badd +1 scenes/views/dtree_view/controller_dtree/controller_dtree.gd
badd +1 scenes/views/dtree_view/dtree_canvas/dtree_canvas.gd
badd +1 scenes/objects/dtree/dtree/dtree.gd
badd +1 scenes/objects/dtree/dtree/algorithm_dtree.gd
badd +28 scripts/signals_observer.gd
badd +32 scenes/views/dtree_view/dtree_view.gd
badd +1 res://scenes/views/dtree_view/dtree_canvas/dtree_canvas.tscn
badd +1 res://scenes/views/dtree_view/dtree_canvas/dtree_canvas.gd
badd +1 scenes/views/dtree_view/dtree_canvas/dtree_canvas.tscn
badd +21 scenes/menus/main_menu.gd
badd +9 scenes/objects/dtree/dnode/dnode.tscn
badd +14 scenes/objects/dtree/dnode/dnode.gd
badd +449 scenes/objects/dtree/algorithm_dtree/algorithm_dtree.gd
badd +354 scenes/controllers/controller_dtree/controller_dtree.gd
badd +1 assets/load_button/load_button.png
badd +1 scenes/interface/load_button/load_button.gd
badd +1 scenes/interface/save_button/save_button.gd
badd +73 scenes/objects/dtree/dtree.gd
badd +1 scenes/objects/dtree/algorithm_dtree/algorithm_dtree.tscn
badd +73 scenes/objects/dtree/conection/conection.gd
badd +7 scenes/objects/dtree/conection_container/conection_container.gd
badd +53 scripts/constants.gd
badd +1 scenes/interface/window/window.gd
badd +66 scenes/objects/dtree/eval_data_container/eval_data_container.gd
badd +1 scenes/interface/panel_dataset_selection/panel_dataset_selection.gd
badd +34 scenes/charts/bars_chart/bars_chart.gd
badd +9 scenes/objects/dtree/eval_data/eval_data.gd
badd +18 scenes/objects/dtree/algorithm_dtree/dnode_logical/dnode_logical.gd
badd +1 scenes/objects/dtree/eval_data_container/eval_data_container.gd.uid
badd +117 scenes/views/nn_view/nn_view.gd
badd +239 scenes/interface/nn/create_nn_menu/create_nn_menu.gd
badd +116 scenes/objects/nn/dense_conection_container/dense_conection_container.gd
badd +1 scenes/objects/nn/nn/neural_network.gd
badd +21 scenes/objects/nn/layer/layer.gd
badd +1 res://scenes/interface/nn/create_nn_menu/create_nn_menu.gd
badd +9 scenes/objects/nn/neuron/neuron.gd
badd +71 scenes/interface/dtree/window/window.gd
badd +1 scenes/interface/nn/layers_in_neuron_submenu/neurons_in_layer.gd
badd +3 scripts/variables.gd
badd +55 scenes/interface/scroll_container/scroll_container.gd
badd +15 scenes/charts/function_plot/function_plot.gd
badd +60 scenes/objects/nn/nn/neural_network_logical.gd
badd +1 scenes/interface/nn/neurons_in_layer_submenu/neurons_in_layer.gd
badd +9 scenes/interface/nn/panel_algorithm_nn/panel_algorithm_nn.gd
badd +210 scenes/interface/nn/panel_dataset_selection/panel_dataset_selection.gd
badd +1 scenes/objects/nn/algorithm_nn/algorithm_nn.gd
badd +0 ~/eu/tfg/godot_project
argglobal
%argdel
$argadd ~/eu/tfg/godot_project
set stal=2
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabrewind
edit scripts/constants.gd
argglobal
balt scripts/signals_observer.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 53 - ((49 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 53
normal! 029|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scripts/signals_observer.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/interface/nn/create_nn_menu/create_nn_menu.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 25 - ((19 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 25
normal! 08|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scripts/variables.gd
argglobal
balt ~/eu/tfg/godot_project/scripts/signals_observer.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 3 - ((2 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 3
normal! 049|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/menus/main_menu.gd
argglobal
balt ~/eu/tfg/godot_project/scripts/constants.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 21 - ((17 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 21
normal! 060|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/views/nn_view/nn_view.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/menus/main_menu.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 168 - ((24 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 168
normal! 021|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/interface/nn/create_nn_menu/create_nn_menu.gd
argglobal
balt ~/eu/tfg/godot_project/scripts/signals_observer.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 239 - ((17 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 239
normal! 049|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/interface/nn/neurons_in_layer_submenu/neurons_in_layer.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/interface/nn/layers_in_neuron_submenu/neurons_in_layer.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>37_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 1 - ((0 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/nn/nn/neural_network.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/nn/dense_conection_container/dense_conection_container.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 1 - ((0 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 048|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/nn/layer/layer.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/nn/nn/neural_network.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 21 - ((12 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 21
normal! 020|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/nn/neuron/neuron.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/nn/layer/layer.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 4 - ((3 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 4
normal! 013|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/nn/dense_conection_container/dense_conection_container.gd
argglobal
balt ~/eu/tfg/godot_project/scripts/signals_observer.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>36_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 116 - ((26 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 116
normal! 045|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/nn/algorithm_nn/algorithm_nn.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/interface/nn/panel_dataset_selection/panel_dataset_selection.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>37_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 317 - ((48 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 317
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/nn/nn/neural_network_logical.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/charts/function_plot/function_plot.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>37_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 1 - ((0 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 09|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/interface/nn/panel_dataset_selection/panel_dataset_selection.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/interface/panel_dataset_selection/panel_dataset_selection.gd
setlocal foldmethod=manual
setlocal foldexpr=<SNR>37_GDScriptFoldLevel()
setlocal foldmarker={{{,}}}
setlocal foldignore=
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 211 - ((35 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 211
normal! 022|
lcd ~/eu/tfg/godot_project
tabnext 11
set stal=1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
set hlsearch
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
