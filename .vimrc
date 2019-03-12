call plug#begin('~/.vim/plugged')

Plug 'pangloss/vim-javascript'
Plug 'moll/vim-node'
Plug 'mhinz/vim-mix-format'
Plug 'airblade/vim-gitgutter'

Plug 'dracula/dracula-theme'
Plug 'kiddos/malokai.vim'
Plug 'morhetz/gruvbox'

Plug 'scrooloose/nerdtree'

call plug#end()

:set mouse=a
syntax on

autocmd vimenter * NERDTree

