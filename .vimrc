execute pathogen#infect()

set mouse=a
set nu
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set t_Co=256
set showcmd
set wildmenu
set nocompatible
set hidden
set wildignore=*.o
set ruler
set hlsearch
set lazyredraw
set noerrorbells
set novisualbell
set t_vb=
set tm=500
set encoding=utf8
set ffs=unix,dos,mac
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=2
set timeoutlen=1000
set ttimeoutlen=0
set backspace=2
set bg=dark

colorscheme solarized
filetype plugin indent on
syntax on

" Syntastic
let g:syntastic_php_checkers=['php', 'phpcs']
let g:syntastic_php_phpcs_args='--standard=PSR2 -n'

" set leader to ,
let mapleader=","
let g:mapleader=","

" ,/ turn off search highlighting
nmap <leader>/ :nohl<CR>

" Bash like keys for the command line
cnoremap <C-A>      <Home>
cnoremap <C-E>      <End>
cnoremap <C-K>      <C-U>

" new tab
map <C-t><C-t> :tabnew<CR>
" close tab
map <C-t><C-w> :tabclose<CR>
" toggle tagbar
nmap <F8> :TagbarToggle<CR>

" automatically read a file that has been modified
" and is open in vim
set autoread

" cursor shows matching ) and }
set showmatch

" set status line
set laststatus=2
set statusline=\ %{HasPaste()}%<%-15.25(%f%)%m%r%h\ %w\ \
set statusline+=\ \ \ [%{&ff}/%Y]
set statusline+=\ \ \ %<%20.30(%{hostname()}:%{CurDir()}%)\
set statusline+=%=%-10.(%l,%c%V%)\ %p%%/%L
set statusline+=%{SyntasticStatuslineFlag()}

" auto reload vimrc when editing it
autocmd! bufwritepost .vimrc source ~/.vimrc

" set the filetype to json for .json extension files
autocmd! BufRead,BufNewFile *.json set filetype=json

" make CSS omnicompletion work for SASS and SCSS
autocmd BufNewFile,BufRead *.scss             set ft=scss.css
autocmd BufNewFile,BufRead *.sass             set ft=sass.css

augroup json_autocmd
  autocmd!
  autocmd FileType json set autoindent
  autocmd FileType json set formatoptions=tcq2l
  autocmd FileType json set textwidth=78 shiftwidth=2
  autocmd FileType json set softtabstop=2 tabstop=8
  autocmd FileType json set expandtab
  autocmd FileType json set foldmethod=syntax
augroup END

" allow multiple indentation/deindentation in visual mode
vnoremap < <gv
vnoremap > >gv

" highlight extra (trailing whitespace) red
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" --------------------------------------------
" use syntax complete if nothing else available
" --------------------------------------------
if has("autocmd") && exists("+omnifunc")
  autocmd Filetype *
              \ if &omnifunc == "" |
              \     setlocal omnifunc=syntaxcomplete#Complete |
              \ endif
endif

" --------------------------------------------
" CtrlP
" --------------------------------------------
let g:ctrlp_user_command = 'find %s -type f'

" --------------------------------------------
" Command-T
" --------------------------------------------
let g:CommandTMaxHeight = 15

" --------------------------------------------
" Functions
" --------------------------------------------
function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  diffthis
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction
com! DiffSaved call s:DiffWithSaved()

command! UnMinify call UnMinify()
function! UnMinify()
    %s/{\ze[^\r\n]/{\r/g
    %s/){/) {/g
    %s/};\?\ze[^\r\n]/\0\r/g
    %s/;\ze[^\r\n]/;\r/g
    %s/[^\s]\zs[=&|]\+\ze[^\s]/ \0 /g
    normal ggVG=
endfunction

function! CurDir()
    let curdir = substitute(getcwd(), $HOME, "~", "")
    return curdir
endfunction

function! HasPaste()
    if &paste
        return '[PASTE]'
    else
        return ''
    endif
endfunction

function! OpenPerlFile(module)
    let file = system("perldoc -l " . a:module)
    let file = substitute(file, "\n$", "", "")
    let file = substitute(file, "pod$", "pm", "")
    execute "tabedit " . file
endfunction

call pathogen#helptags()
