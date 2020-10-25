# ZFVimToc

vim script to quick view TOC (Table Of Contents) for any filetype

if you like my work, [check here](https://github.com/ZSaberLv0?utf8=%E2%9C%93&tab=repositories&q=ZFVim) for a list of my vim plugins


# how to use

1. use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager you like to install

    ```
    Plugin 'othree/eregex.vim'
    Plugin 'ZSaberLv0/ZFVimToc'
    ```

1. use `<leader>vt` or `:ZFToc` to view a TOC

    * for configured `filetype` (see `g:ZFToc_setting`), TOC should show directly
        * to force use custom pattern, use `<leader>zt` or `:ZFToc YourPattern`,
            enter an empty pattern to reset to default configured one
    * for other `filetype`, you would be asked to enter regexp to search for titles

1. use `[[` or `]]` to jump to prev/next title


# keymaps

the default keymap and the var to config:

```
let g:ZFTocKeymap_TOC='<leader>vt'
let g:ZFTocKeymap_TOCCustom='<leader>zt'
let g:ZFTocKeymap_prev='[['
let g:ZFTocKeymap_next=']]'
```


# config your own filetype

by default, only `markdown` file are configured for TOC view,
you may add config for your own filetype

```
let g:ZFToc_setting['markdown'] = {
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
augroup ZFToc_setting_augroup
    autocmd!
    autocmd BufWinEnter quickfix
                \  nnoremap <buffer> <silent> q :bd<cr>
                \| nnoremap <buffer> <silent> <leader>vt :bd<cr>
                \| nnoremap <buffer> <silent> <cr> <cr>:lclose<cr>
                \| nnoremap <buffer> <silent> o <cr>:lclose<cr>
                \| setlocal foldmethod=indent
augroup END
```

