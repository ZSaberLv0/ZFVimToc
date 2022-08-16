# ZFVimToc

vim script to quick view TOC (Table Of Contents) for any filetype

if you like my work, [check here](https://github.com/ZSaberLv0?utf8=%E2%9C%93&tab=repositories&q=ZFVim) for a list of my vim plugins,
or [buy me a coffee](https://github.com/ZSaberLv0/ZSaberLv0)


# how to use

1. use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager you like to install

    ```
    Plugin 'ZSaberLv0/ZFVimToc'
    Plugin 'othree/eregex.vim' " required
    ```

1. use `<leader>vt` or `:ZFToc` to view a TOC

    * for configured `filetype` (see `g:ZFToc_setting`), TOC should show directly
        * to force use custom pattern, use `<leader>zt` or `:ZFToc YourPattern`,
            use `:ZFTocReset` to restore default config
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
            \     'titleInfoGetter' : '',
            \     'titleLevelRegExpMatch' : '^[ \t]*([#]+).*$',
            \     'titleLevelRegExpReplace' : '\1',
            \     'titleNameRegExpMatch' : '^[ \t]*[#]+[ \t]*(<.*?>)?[ \t]*(.*?)[ \t]*(<.*?>)?[ \t]*$',
            \     'titleNameRegExpReplace' : '\2',
            \     'codeBlockBegin' : '^[ \t]*```.*$',
            \     'codeBlockEnd' : '^[ \t]*```[ \t]*$',
            \     'excludeRegExp' : '',
            \ }

" or use `*` for any filetype, you may disable the default config by
"   g:ZFToc_fallback_enable = 0
let g:ZFToc_setting['*'] = {
            \   'titleRegExp' : '\m' . '^[ \t]*\%(class\|interface\|protocol\)\>'
            \     . '\|' . '^[ \t]*\%(public\|protected\|private\|virtual\|static\|inline\|def\%(ine\)\=\|func\%(tion\)\=\)[a-z0-9_ \*<>:!?]\+('
            \     . '\|' . '^[a-z_].*=[ \t]*\%(func\%(tion\)\=\)\=[ \t]*([a-z0-9_ ,:!?]*)[ \t]*\%([\-=]>\)\=[ \t]*{'
            \     . '\|' . '^[ \t]*[a-z0-9_]\+[ \t]*([^!;=()]*)[ \t]*\%({\|\n[ \t]*{\)'
            \   ,
            \   'codeBlockBegin' : '\m' . '^[ \t]*\/\*',
            \   'codeBlockEnd' : '\m' . '^[ \t]*\*\+\/[ \t]*$\|^[ \t]*\/\*.*\*\/[ \t]*$',
            \   'excludeRegExp' : '^[ \t]*(\/\/|#|rem(ark)\>|return\>|if\>|for_?(each)?\>|while\>)',
            \ }
```

patterns:

* `titleRegExp` : required, regexp to match title
* `titleInfoGetter` : optional, `function(title, line)` to obtain title info to show in location window,
    if supplied, you should return a Dict that contains necessary info:

    ```
    {
      'text' : 'the text to show in location window',
      'level' : 'the indent level of the title',
    }
    ```

    or, you may use these patterns to convert the title:

    * `titleLevelRegExpMatch` and `titleLevelRegExpReplace` : optional, regexp to check title level,
        result should be any string, whose (length - 1) indicates the title's level
    * `titleNameRegExpMatch` and `titleNameRegExpReplace` : optional,
        regexp to convert title name to human readable one,
        empty to use the original matched line

* `codeBlockBegin` and `codeBlockEnd` : optional,
    regexp to match code block,
    any contents inside the code block won't be considered as title,
    empty to disable this feature
* `excludeRegExp` : optional, exclude lines that match this pattern

about pattern regexp:

* we use [othree/eregex.vim](https://github.com/othree/eregex.vim) for regexp,
    instead of vim's builtin regexp,
    but you may still use original vim's pattern by adding `\v` or `\m` series (`:h /\v`) at head,
    for example: `\m(abc)`


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

