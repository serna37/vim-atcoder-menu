if get(g:, 'ac_vim_default_keymap', 1)
    nnoremap <silent><Leader>a :cal atcoder#ac_menu()<CR>
endif

com! AtCoderStartify cal atcoder#startify()
com! AtCoderTimer cal atcoder#timer()
