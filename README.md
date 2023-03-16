# ZFVimToc

vim script to quick view TOC (Table Of Contents) for any filetype

if you like my work, [check here](https://github.com/ZSaberLv0?utf8=%E2%9C%93&tab=repositories&q=ZFVim) for a list of my vim plugins,
or [buy me a coffee](https://github.com/ZSaberLv0/ZSaberLv0)


# how to use

1. use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager you like to install

    ```
    Plugin 'ZSaberLv0/ZFVimToc'
    Plugin 'othree/eregex.vim' " optional, for perl style regexp
    ```

1. use `<leader>vt` or `:ZFToc` to view a TOC

    * for configured `filetype` (see `g:ZFToc_setting`), TOC should show directly
        * to force use custom pattern, use `<leader>zt` or `:ZFToc YourPattern`,
            use `:ZFTocReset` to restore default config
    * for other `filetype`, you may use `:ZFToc YourPattern` to use custom pattern,
        we also bundled a default fallback for any filetypes,
        `let g:ZFToc_setting['*']=xxx` to supply your own config
    * for scripts, you may setup `b:ZFToc_setting` for buffer local setting

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

by default, only `markdown` are explicitly configured,
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
```


for convenient, we also bundled a default fallback for any filetype, to list anything that looks like functions

```
" use `*` for any filetype, you may disable the default config by
"   g:ZFToc_fallback_enable = 0
let g:ZFToc_setting['*'] = {...}

" the default fallback is a little complex, see the source code for default value:
"   https://github.com/ZSaberLv0/ZFVimToc/blob/master/plugin/ZFVimToc.vim
" also take care of `E872` and `E53`, see FAQ bellow
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

* when [othree/eregex.vim](https://github.com/othree/eregex.vim) installed,
    we would use perl style regexp,
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

# FAQ

* Q: `Vim(lvimgrep):E872: (NFA regexp) Too many '('`

    A: you would get this issue if the regex pattern contains too many groups
        (`(abc)` for example, see `:h E53` for more info),
        the solution is replace it by `\%(abc\)`

    * to make life easier, the default impl has already performed `\(abc\)` to `\%(abc\)`,
        but that leads `\1` not work properly

