let s:cpo_save=&cpo
set cpo&vim
cnoremap <silent> <Plug>(TelescopeFuzzyCommandSearch) e "lua require('telescope.builtin').command_history { default_text = [=[" . escape(getcmdline(), '"') . "]=] }"
inoremap <silent> <M-o> └─ a
inoremap <silent> <M-i> ├─ a
inoremap <silent> <M-u> │a
inoremap <C-W> u
inoremap <C-U> u
nnoremap <silent> 	 <Cmd>tabnext
nnoremap  <Cmd>nohlsearch|diffupdate|normal! 
nnoremap  :w
nmap  d
nnoremap & :&&
vnoremap < <gv
vnoremap > >gv
xnoremap <silent> <expr> @ mode() ==# 'V' ? ':normal! @'.getcharstr().'' : '@'
nnoremap N Nzzzv
xnoremap <silent> <expr> Q mode() ==# 'V' ? ':normal! @=reg_recorded()' : 'Q'
nnoremap Y y$
nnoremap n nzzzv
nnoremap <Plug>PlenaryTestFile :lua require('plenary.test_harness').test_file(vim.fn.expand("%:p"))
xmap <silent> <Plug>(MatchitVisualTextObject) <Plug>(MatchitVisualMultiBackward)o<Plug>(MatchitVisualMultiForward)
onoremap <silent> <Plug>(MatchitOperationMultiForward) :call matchit#MultiMatch("W",  "o")
onoremap <silent> <Plug>(MatchitOperationMultiBackward) :call matchit#MultiMatch("bW", "o")
xnoremap <silent> <Plug>(MatchitVisualMultiForward) :call matchit#MultiMatch("W",  "n")m'gv``
xnoremap <silent> <Plug>(MatchitVisualMultiBackward) :call matchit#MultiMatch("bW", "n")m'gv``
nnoremap <silent> <Plug>(MatchitNormalMultiForward) :call matchit#MultiMatch("W",  "n")
nnoremap <silent> <Plug>(MatchitNormalMultiBackward) :call matchit#MultiMatch("bW", "n")
onoremap <silent> <Plug>(MatchitOperationBackward) :call matchit#Match_wrapper('',0,'o')
onoremap <silent> <Plug>(MatchitOperationForward) :call matchit#Match_wrapper('',1,'o')
xnoremap <silent> <Plug>(MatchitVisualBackward) :call matchit#Match_wrapper('',0,'v')m'gv``
xnoremap <silent> <Plug>(MatchitVisualForward) :call matchit#Match_wrapper('',1,'v'):if col("''") != col("$") | exe ":normal! m'" | endifgv``
nnoremap <silent> <Plug>(MatchitNormalBackward) :call matchit#Match_wrapper('',0,'n')
nnoremap <silent> <Plug>(MatchitNormalForward) :call matchit#Match_wrapper('',1,'n')
nnoremap <C-S> :w
nnoremap <silent> <S-Tab> <Cmd>tabprevious
nnoremap <silent> <M-o> r└l
nnoremap <silent> <M-i> r├l
nnoremap <silent> <M-u> r│l
nmap <C-W><C-D> d
nnoremap <C-L> <Cmd>nohlsearch|diffupdate|normal! 
inoremap  u
inoremap  u
inoremap <silent> kj 
let &cpo=s:cpo_save
unlet s:cpo_save
set noequalalways
set grepformat=%f:%l:%c:%m
set grepprg=rg\ --vimgrep\ -uu\ 
set helplang=en
set noloadplugins
set packpath=/nix/store/lpvd9jcq8k518mrafh2srw9a41cdavyd-neovim-unwrapped-0.11.6/share/nvim/runtime
set runtimepath=~/.config/nvim,~/.local/share/nvim/site,~/.local/share/nvim/lazy/lazy.nvim,~/.local/share/nvim/lazy/telescope-fzf-native.nvim,~/.local/share/nvim/lazy/telescope-file-browser.nvim,~/.local/share/nvim/lazy/plenary.nvim,~/.local/share/nvim/lazy/telescope.nvim,~/.local/share/nvim/lazy/nvim-notify,~/.local/share/nvim/lazy/nvim-autopairs,~/.local/share/nvim/lazy/cmp_luasnip,~/.local/share/nvim/lazy/cmp-git,~/.local/share/nvim/lazy/cmp-cmdline,~/.local/share/nvim/lazy/cmp-path,~/.local/share/nvim/lazy/cmp-buffer,~/.local/share/nvim/lazy/nvim-cmp,~/.local/share/nvim/lazy/cmp-nvim-lsp,~/.local/share/nvim/lazy/neodev.nvim,~/.local/share/nvim/lazy/nvim-lspconfig,~/.local/share/nvim/lazy/gitsigns.nvim,~/.local/share/nvim/lazy/mason.nvim,~/.local/share/nvim/lazy/vimtex,~/.local/share/nvim/lazy/LuaSnip,~/.local/share/nvim/lazy/nvim-web-devicons,~/.local/share/nvim/lazy/lualine.nvim,~/.local/share/nvim/lazy/nvim-treesitter-textobjects,~/.local/share/nvim/lazy/gruvbox.nvim,/nix/store/lpvd9jcq8k518mrafh2srw9a41cdavyd-neovim-unwrapped-0.11.6/share/nvim/runtime,/nix/store/lpvd9jcq8k518mrafh2srw9a41cdavyd-neovim-unwrapped-0.11.6/share/nvim/runtime/pack/dist/opt/netrw,/nix/store/lpvd9jcq8k518mrafh2srw9a41cdavyd-neovim-unwrapped-0.11.6/share/nvim/runtime/pack/dist/opt/matchit,/nix/store/lpvd9jcq8k518mrafh2srw9a41cdavyd-neovim-unwrapped-0.11.6/lib/nvim,~/.local/state/nvim/lazy/readme,~/.local/share/nvim/lazy/cmp_luasnip/after,~/.local/share/nvim/lazy/cmp-cmdline/after,~/.local/share/nvim/lazy/cmp-path/after,~/.local/share/nvim/lazy/cmp-buffer/after,~/.local/share/nvim/lazy/cmp-nvim-lsp/after,~/.local/share/nvim/lazy/vimtex/after
set shiftwidth=2
set statusline=%#lualine_transparent#
set termguicolors
set undofile
set undolevels=10000
set window=55
" vim: set ft=vim :
