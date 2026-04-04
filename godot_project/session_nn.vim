let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/eu/tfg/godot_project
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +1 scenes/views/dtree_view/controller_dtree/controller_dtree.gd
badd +27 scenes/views/dtree_view/dtree_canvas/dtree_canvas.gd
badd +1 scenes/objects/dtree/dtree/dtree.gd
badd +1 scenes/objects/dtree/dtree/algorithm_dtree.gd
badd +19 scripts/signals_observer.gd
badd +78 scenes/views/dtree_view/dtree_view.gd
badd +1 ~/eu/tfg/godot_project
badd +1 res://scenes/views/dtree_view/dtree_canvas/dtree_canvas.tscn
badd +1 res://scenes/views/dtree_view/dtree_canvas/dtree_canvas.gd
badd +1 scenes/views/dtree_view/dtree_canvas/dtree_canvas.tscn
badd +21 scenes/menus/main_menu.gd
badd +26 scenes/objects/dtree/dnode/dnode.tscn
badd +14 scenes/objects/dtree/dnode/dnode.gd
badd +449 scenes/objects/dtree/algorithm_dtree/algorithm_dtree.gd
badd +340 scenes/controllers/controller_dtree/controller_dtree.gd
badd +1 assets/load_button/load_button.png
badd +4 scenes/interface/load_button/load_button.gd
badd +8 scenes/interface/save_button/save_button.gd
badd +24 scenes/objects/dtree/dtree.gd
badd +1 scenes/objects/dtree/algorithm_dtree/algorithm_dtree.tscn
badd +51 scenes/objects/dtree/conection/conection.gd
badd +7 scenes/objects/dtree/conection_container/conection_container.gd
badd +20 scripts/constants.gd
badd +116 scenes/interface/window/window.gd
badd +66 scenes/objects/dtree/eval_data_container/eval_data_container.gd
badd +43 scenes/interface/panel_dataset_selection/panel_dataset_selection.gd
badd +34 scenes/charts/bars_chart/bars_chart.gd
badd +9 scenes/objects/dtree/eval_data/eval_data.gd
badd +18 scenes/objects/dtree/algorithm_dtree/dnode_logical/dnode_logical.gd
badd +1 scenes/objects/dtree/eval_data_container/eval_data_container.gd.uid
badd +43 scenes/views/nn_view/nn_view.gd
badd +109 scenes/interface/nn/create_nn_menu/create_nn_menu.gd
badd +68 scenes/objects/nn/dense_conection_container/dense_conection_container.gd
badd +11 scenes/objects/nn/nn/neural_network.gd
badd +41 scenes/objects/nn/layer/layer.gd
badd +1 res://scenes/interface/nn/create_nn_menu/create_nn_menu.gd
badd +3 scenes/objects/nn/neuron/neuron.gd
badd +71 scenes/interface/dtree/window/window.gd
badd +31 scenes/interface/nn/layers_in_neuron_submenu/neurons_in_layer.gd
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
let s:l = 20 - ((14 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 20
normal! 043|
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
let s:l = 19 - ((14 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 19
normal! 038|
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
let s:l = 21 - ((15 * winheight(0) + 22) / 45)
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
let s:l = 38 - ((28 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 38
normal! 053|
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
let s:l = 109 - ((15 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 109
normal! 044|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/interface/nn/layers_in_neuron_submenu/neurons_in_layer.gd
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
let s:l = 31 - ((26 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 31
normal! 048|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/nn/nn/neural_network.gd
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
let s:l = 11 - ((7 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 11
normal! 034|
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
let s:l = 28 - ((21 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 28
normal! 028|
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
let s:l = 3 - ((2 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 3
normal! 016|
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
let s:l = 16 - ((12 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 16
normal! 038|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/conection/conection.gd
argglobal
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
let s:l = 136 - ((0 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 136
normal! 014|
lcd ~/eu/tfg/godot_project
tabnext 5
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
