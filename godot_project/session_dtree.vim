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
badd +14 scripts/signals_observer.gd
badd +78 scenes/views/dtree_view/dtree_view.gd
badd +1 ~/eu/tfg/godot_project
badd +1 res://scenes/views/dtree_view/dtree_canvas/dtree_canvas.tscn
badd +1 res://scenes/views/dtree_view/dtree_canvas/dtree_canvas.gd
badd +1 scenes/views/dtree_view/dtree_canvas/dtree_canvas.tscn
badd +20 scenes/menus/main_menu.gd
badd +26 scenes/objects/dtree/dnode/dnode.tscn
badd +58 scenes/objects/dtree/dnode/dnode.gd
badd +457 scenes/objects/dtree/algorithm_dtree/algorithm_dtree.gd
badd +225 scenes/controllers/controller_dtree/controller_dtree.gd
badd +1 assets/load_button/load_button.png
badd +4 scenes/interface/load_button/load_button.gd
badd +8 scenes/interface/save_button/save_button.gd
badd +42 scenes/objects/dtree/dtree.gd
badd +1 scenes/objects/dtree/algorithm_dtree/algorithm_dtree.tscn
badd +1 scenes/objects/dtree/conection/conection.gd
badd +1 scenes/objects/dtree/conection_container/conection_container.gd
badd +20 scripts/constants.gd
badd +98 scenes/interface/window/window.gd
badd +66 scenes/objects/dtree/eval_data_container/eval_data_container.gd
badd +1 scenes/interface/panel_dataset_selection/panel_dataset_selection.gd
badd +34 scenes/charts/bars_chart/bars_chart.gd
badd +6 scenes/objects/dtree/eval_data/eval_data.gd
badd +18 scenes/objects/dtree/algorithm_dtree/dnode_logical/dnode_logical.gd
badd +1 scenes/objects/dtree/eval_data_container/eval_data_container.gd.uid
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
let s:l = 17 - ((16 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 17
normal! 035|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scripts/signals_observer.gd
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
let s:l = 14 - ((12 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 14
normal! 024|
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
let s:l = 21 - ((20 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 21
normal! 060|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/views/dtree_view/dtree_view.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/views/dtree_view/dtree_canvas/dtree_canvas.tscn
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
let s:l = 78 - ((32 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 78
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/controllers/controller_dtree/controller_dtree.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/dtree/dnode/dnode.gd
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
let s:l = 340 - ((32 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 340
normal! 028|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/algorithm_dtree/algorithm_dtree.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/dtree/algorithm_dtree/algorithm_dtree.tscn
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
let s:l = 454 - ((43 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 454
normal! 069|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/dtree.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/dtree/dtree/dtree.gd
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
let s:l = 24 - ((14 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 24
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/dnode/dnode.gd
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
let s:l = 14 - ((8 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 14
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/conection/conection.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/dtree/dnode/dnode.gd
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
let s:l = 52 - ((31 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 52
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/conection_container/conection_container.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/dtree/conection/conection.gd
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
let s:l = 1 - ((0 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/interface/window/window.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/objects/dtree/conection_container/conection_container.gd
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
let s:l = 116 - ((13 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 116
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/interface/panel_dataset_selection/panel_dataset_selection.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/interface/window/window.gd
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
let s:l = 43 - ((25 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 43
normal! 036|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/eval_data_container/eval_data_container.gd
argglobal
balt ~/eu/tfg/godot_project/scenes/interface/window/window.gd
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
let s:l = 1 - ((0 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 0
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/algorithm_dtree/algorithm_dtree.gd
argglobal
setlocal foldmethod=manual
setlocal foldexpr=0
setlocal foldmarker={{{,}}}
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 449 - ((32 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 449
normal! 043|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/eval_data_container/eval_data_container.gd
argglobal
setlocal foldmethod=manual
setlocal foldexpr=0
setlocal foldmarker={{{,}}}
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 66 - ((7 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 66
normal! 024|
lcd ~/eu/tfg/godot_project
tabnext
edit ~/eu/tfg/godot_project/scenes/objects/dtree/eval_data/eval_data.gd
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
let s:l = 9 - ((7 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 9
normal! 0
lcd ~/eu/tfg/godot_project
tabnext 4
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
