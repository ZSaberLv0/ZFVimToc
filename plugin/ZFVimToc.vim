" ZFVimToc - vim script to quick view TOC (Table Of Contents) for any filetype
" Author:  ZSaberLv0 <http://zsaber.com/>

if exists('*E2v')
    function! ZFE2v(pattern)
        return E2v(a:pattern)
    endfunction
endif

let g:ZFVimToc_loaded=1

" ============================================================
function! ZF_TocPatternMake(ft, titleToken, codeBlockBegin, codeBlockEnd)
    if !exists('g:ZFVimToc_setting')
        let g:ZFVimToc_setting={}
    endi
    let g:ZFVimToc_setting[a:ft] = {
                \     'titleRegExp' : '^[ \t]*' . a:titleToken . '+.*$',
                \     'titleLevelRegExpMatch' : '^[ \t]*(' . a:titleToken . '+).*$',
                \     'titleLevelRegExpReplace' : '\1',
                \     'titleNameRegExpMatch' : '^[ \t]*' . a:titleToken . '+[ \t]*(<.*?>)?[ \t]*(.*?)[ \t]*(<.*?>)?[ \t]*$',
                \     'titleNameRegExpReplace' : '\2',
                \     'codeBlockBegin' : a:codeBlockBegin,
                \     'codeBlockEnd' : a:codeBlockEnd,
                \ }
endfunction
if !exists('g:ZFVimToc_setting') || !exists('g:ZFVimToc_setting["markdown"]')
    call ZF_TocPatternMake('markdown', '[#]', '^[ \t]*```.*$', '^[ \t]*```[ \t]*$')
endi

if !exists('g:ZFVimToc_autoKeymap')
    let g:ZFVimToc_autoKeymap = ['markdown']
endif

function! ZF_VimToc_makeKeymap()
    nnoremap <buffer> [[ :call ZF_TocPrev('n')<cr>
    xnoremap <buffer> [[ :call ZF_TocPrev('v')<cr>
    nnoremap <buffer> ]] :call ZF_TocNext('n')<cr>
    xnoremap <buffer> ]] :call ZF_TocNext('v')<cr>
    nnoremap <buffer> <leader>vt :call ZF_Toc()<cr>
endfunction
for ft in g:ZFVimToc_autoKeymap
    let cmd = ''
    let cmd .= 'augroup ZF_Plugin_ZFVimToc_augroup_' . ft . ' | '
    let cmd .= '    execute "autocmd!" | '
    let cmd .= '    execute "autocmd FileType ' . ft . ' call ZF_VimToc_makeKeymap()" | '
    let cmd .= 'augroup END'
    execute cmd
endfor


" ============================================================
function! s:getSetting()
    if !exists('*ZFE2v')
        echo 'ZFVimToc require othree/eregex.vim'
        echo '    install it or supply custom wrapper function ZFE2v(pattern)'
        return {}
    endif
    let setting = get(g:ZFVimToc_setting, &filetype, {})
    if empty(setting) && &filetype != ''
        let setting = get(g:ZFVimToc_setting, '', {})
    endif
    if empty(setting)
        echo 'ZFVimToc: filetype "' . &filetype . '" not configured'
    endif
    return setting
endfunction

function! ZF_Toc()
    let setting = s:getSetting()
    if empty(setting)
        return
    endif
    let tagL = get(a:, 1, g:ZFVimExpand_tagL)
    let l:cur_line = line(".")
    let l:toc_line = 0

    try
        if len(setting.codeBlockBegin) > 0
            let t='(' . setting.titleRegExp . ')'
            let t.='|(' . setting.codeBlockBegin . ')'
            let t.='|(' . setting.codeBlockEnd . ')'
        else
            let t=setting.titleRegExp
        endif
        execute 'silent lvimgrep /' . ZFE2v(t) . '/ %'
    catch /E480/
        echom "no titles."
        return
    endtry

    call cursor(l:cur_line, 0)

    let loclist = getloclist(0)
    let i = 1
    let range = len(loclist)
    if len(setting.codeBlockBegin) > 0
        let code_block_flag = 0
        let codeBlockBegin=ZFE2v(setting.codeBlockBegin)
        let codeBlockEnd=ZFE2v(setting.codeBlockEnd)
        while i <= range
            let d = loclist[i-1]
            if match(d.text, codeBlockBegin) > -1
                if code_block_flag > 0 && match(d.text, codeBlockEnd) > -1
                    let code_block_flag-=1
                else
                    let code_block_flag+=1
                endif
                call remove(loclist, i - 1)
                let i = i - 1
                let range = range - 1
            elseif match(d.text, codeBlockEnd) > -1
                let code_block_flag-=1
                call remove(loclist, i - 1)
                let i = i - 1
                let range = range - 1
            elseif code_block_flag > 0
                call remove(loclist, i - 1)
                let i = i - 1
                let range = range - 1
            endif
            let i = i + 1
        endwhile
        call setloclist(0, loclist)
    endif

    lopen 25
    setlocal modifiable
    if line('$') > 1
        let titleLevelRegExpMatch=ZFE2v(setting.titleLevelRegExpMatch)
        let titleLevelRegExpReplace=ZFE2v(setting.titleLevelRegExpReplace)
        let titleNameRegExpMatch=ZFE2v(setting.titleNameRegExpMatch)
        let titleNameRegExpReplace=ZFE2v(setting.titleNameRegExpReplace)
        for i in range(1, line('$'))
            let d = getloclist(0)[i-1]
            if l:toc_line == 0
                if d.lnum == l:cur_line
                    let l:toc_line = i
                elseif d.lnum > l:cur_line
                    let l:toc_line = i - 1
                endif
            endif

            let l:level = len(substitute(d.text, titleLevelRegExpMatch, titleLevelRegExpReplace, ''))
            if l:level > 0
                let l:level -= 1
            endif
            if len(titleNameRegExpMatch) > 0
                let d.text = substitute(d.text, titleNameRegExpMatch, titleNameRegExpReplace, '')
            endif
            call setline(i, repeat('    ', l:level). d.text)
        endfor
    endif
    setlocal nomodified
    setlocal nomodifiable
    call cursor(l:toc_line, 0)
endfunction
command! -nargs=0 ZFToc :call ZF_Toc()

function! ZF_TocPrev(mode)
    let setting = s:getSetting()
    if empty(setting)
        return
    endif
    let cur_line = getpos(".")[1]
    let has_content=0
    let code_block_flag=0
    let titleRegExp=ZFE2v(setting.titleRegExp)
    let codeBlockBegin=ZFE2v(setting.codeBlockBegin)
    let codeBlockEnd=ZFE2v(setting.codeBlockEnd)
    for i in range(cur_line)
        normal! k
        let line = getline(".")
        if len(codeBlockBegin) > 0
            if match(line, codeBlockEnd) > -1
                if code_block_flag > 0 && match(line, codeBlockBegin) > -1
                    let code_block_flag-=1
                else
                    let code_block_flag+=1
                endif
                let has_content=1
            elseif match(line, codeBlockBegin) > -1
                let code_block_flag-=1
            elseif code_block_flag > 0
                continue
            endif
        endif
        if match(line, titleRegExp) > -1
            if has_content==0
                continue
            else
                break
            endif
        elseif match(line, '[^ \t]') > -1
            let has_content=1
        endif
    endfor
    if a:mode=='v'
        normal! m>gv
    endif
    redraw!
endfunction
function! ZF_TocNext(mode)
    let setting = s:getSetting()
    if empty(setting)
        return
    endif
    let cur_line = getpos(".")[1]
    let has_content=0
    let code_block_flag=0
    let titleRegExp=ZFE2v(setting.titleRegExp)
    let codeBlockBegin=ZFE2v(setting.codeBlockBegin)
    let codeBlockEnd=ZFE2v(setting.codeBlockEnd)
    for i in range(cur_line, line("$"))
        normal! j
        let line = getline(".")
        if len(codeBlockBegin) > 0
            if match(line, codeBlockBegin) > -1
                if code_block_flag > 0 && match(line, codeBlockEnd) > -1
                    let code_block_flag-=1
                else
                    let code_block_flag+=1
                endif
                let has_content=1
            elseif match(line, codeBlockEnd) > -1
                let code_block_flag-=1
            elseif code_block_flag > 0
                continue
            endif
        endif
        if match(line, titleRegExp) > -1
            if has_content==0
                continue
            else
                break
            endif
        elseif match(line, '[^ \t]') > -1
            let has_content=1
        endif
    endfor
    if a:mode=='v'
        normal! m>gv
    endif
    redraw!
endfunction

