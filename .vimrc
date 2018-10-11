set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'rust-lang/rust.vim'

call vundle#end()

" Custom bindings

cmap w!! w !sudo tee % > /dev/null

nmap ; :
nmap ,<space> :nohlsearch<CR>
nmap <space>w :w<CR>
nmap Q @q
nmap Y y$

imap jk <esc>
imap jj <esc>

nmap <tab> gt
nmap <s-tab> gT

" Navigate splits with Up/Down/Left/Right
map <Up> <C-W>k
map <Down> <C-W>j
map <Left> <C-W>h
map <Right> <C-W>l

vmap > >gv
vmap < <gv

map <space>t :NERDTreeToggle<CR>

map <space>u :call ToggleCursorLine()<CR>
map <space>l :call ToggleNumber()<CR>
map <space>p :call TogglePaste()<CR>
map <space>b :call ToggleBackground()<CR>


" Basic C program
nmap <F2> i#include <stdio.h><CR>#include <stdlib.h><CR><CR>int main()<CR>{<CR>return 0;<CR>}<Esc>
" Basic C++ program
nmap <F3> i#include <iostream><CR>using namespace std;<CR><CR>int main()<CR>{<CR>return 0;<CR>}<Esc>



" Completion
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" Colorscheme
colorscheme solarized
syntax enable

" Indentation
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set copyindent
set smarttab
filetype plugin indent on

" Always display the status line
set laststatus=2

" Searching
set incsearch
set hlsearch
set ignorecase
set smartcase


set history=1000
set undolevels=1000
set title
set novisualbell
set noerrorbells
set belloff=all
set nowrap
set showcmd

set wildmenu
set lazyredraw
set showmatch
set number
set ruler
set backspace=indent,eol,start

set nocursorline

highlight Normal ctermbg=white
set background=light

" Custom functions to toggle stuff

function! ToggleNumber()
	if(&relativenumber == 1)
		set norelativenumber
	else
		set relativenumber
	endif
endfunc

function! TogglePaste()
	if(&paste == 1)
		set nopaste
	else
		set paste
	endif
endfunc

function! ToggleCursorLine()
	if (&cursorline == 1)
		set nocursorline
	else
		set cursorline
	endif
endfunc

function! ToggleBackground()
	if (&background == 'light')
		set background=dark
	else
		set background=light
	endif
endfunc

