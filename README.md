# ZFVimToc

vim script to quick view TOC (Table Of Contents) for any filetype


# how to use

1. use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager you like to install

    ```
    Plug 'othree/eregex.vim'
    Plugin 'ZSaberLv0/ZFVimToc'
    ```

1. use `:call ZF_Toc()` or `:ZFToc` to view a TOC


# keymaps

recommended keymap:

```
autocmd FileType YourFileType nnoremap <silent> <buffer> <leader>vt :call ZF_Toc()<cr>
autocmd FileType YourFileType nnoremap <silent> <buffer> [[ :call ZF_TocPrev('n')<cr>
autocmd FileType YourFileType xnoremap <silent> <buffer> [[ :call ZF_TocPrev('v')<cr>
autocmd FileType YourFileType nnoremap <silent> <buffer> ]] :call ZF_TocNext('n')<cr>
autocmd FileType YourFileType xnoremap <silent> <buffer> ]] :call ZF_TocNext('v')<cr>
```

by default, the above keymaps would be applied to `markdown` files,
you may disable or change by:

```
let g:ZFVimToc_autoKeymap = ['markdown']
```


# config your own filetype

by default, only `markdown` file are configured for TOC view,
you may add config for your own filetype

```
let g:ZFVimToc_setting['markdown'] = {
            \     'titleRegExp' : '^[ \t]*[#]+.*$',
            \     'titleLevelRegExpMatch' : '^[ \t]*([#]+).*$',
            \     'titleLevelRegExpReplace' : '\1',
            \     'titleNameRegExpMatch' : '^[ \t]*[#]+[ \t]*(<.*?>)?[ \t]*(.*?)[ \t]*(<.*?>)?[ \t]*$',
            \     'titleNameRegExpReplace' : '\2',
            \     'codeBlockBegin' : '^[ \t]*```.*$',
            \     'codeBlockEnd' : '^[ \t]*```[ \t]*$',
            \ }
```

patterns:

* `titleRegExp` : regexp to match title
* `titleLevelRegExpMatch` and `titleLevelRegExpReplace` : regexp to check title level,
    result should be any string, whose (length - 1) indicates the title's level
* `titleNameRegExpMatch` and `titleNameRegExpReplace` : optional,
    regexp to convert title name to human readable one,
    empty to use the original matched line
* `codeBlockBegin` and `codeBlockEnd` : optional,
    regexp to match code block,
    any contents inside the code block won't be considered as title,
    empty to disable this feature

about pattern regexp:

* we use [othree/eregex.vim](https://github.com/othree/eregex.vim) for regexp,
    instead of vim's builtin regexp


# additional settings

the TOC preview is a location list in fact (`:h :lopen`)

you may have these settings in your vimrc to make it more convenient:

```
augroup ZFVimToc_setting
    autocmd!
    autocmd BufWinEnter quickfix
                \ nnoremap <buffer> <silent> q :bd<cr>|
                \ nnoremap <buffer> <silent> <leader>vt :bd<cr>|
                \ nnoremap <buffer> <silent> <cr> <cr>:lclose<cr>|
                \ nnoremap <buffer> <silent> o <cr>:lclose<cr>|
                \ setlocal foldmethod=indent
augroup END
```

