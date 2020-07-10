
if exists('*E2v')
    function! ZFE2v(pattern)
        return E2v(a:pattern)
    endfunction
endif

" ============================================================
function! ZF_TocPatternMake(ft, titleToken, codeBlockBegin, codeBlockEnd)
    if !exists('g:ZFVimToc_setting')
        let g:ZFVimToc_setting={}
    endi
    let g:ZFVimToc_setting[a:ft] = {
                \     'titleRegExp' : '^[ \t]*' . a:titleToken . '+ .*$',
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

function! ZF_VimTocGeneric(autoStart)
    if empty(expand('%'))
        redraw!
        echo '[ZFVimToc] no file'
        return ''
    endif

    if empty(s:getSetting())
        if get(b:, 'ZF_VimToc_patternNoMatch', 0) || !a:autoStart
            call feedkeys(':ZFToc' . (a:autoStart ? "\<cr>" : ' '), 't')
        else
            call feedkeys(":ZFToc \<c-r>=get(b:, 'ZF_VimToc_patternLast', '')\<cr>\<cr>", 't')
        endif
    else
        call feedkeys(":ZFToc\<cr>", 't')
    endif
    return ''
endfunction
if !exists('g:ZFVimToc_keymap') || g:ZFVimToc_keymap
    nnoremap <expr> <leader>vt '' . ZF_VimTocGeneric(1)
    nnoremap <expr> <leader>zt '' . ZF_VimTocGeneric(0)
endif

if !exists('g:ZFVimToc_autoKeymap')
    let g:ZFVimToc_autoKeymap = {}
endif
if !exists('g:ZFVimToc_autoKeymap["markdown"]')
    let g:ZFVimToc_autoKeymap['markdown']=1
endif

function! ZF_VimToc_makeKeymap()
    nnoremap <silent> <buffer> [[ :call ZF_TocPrev('n')<cr>
    xnoremap <silent> <buffer> [[ :<c-u>call ZF_TocPrev('v')<cr>
    nnoremap <silent> <buffer> ]] :call ZF_TocNext('n')<cr>
    xnoremap <silent> <buffer> ]] :<c-u>call ZF_TocNext('v')<cr>
    nnoremap <silent> <buffer> <leader>vt :call ZF_Toc()<cr>
    nnoremap <silent> <buffer> <leader>zt :call ZF_Toc()<cr>
endfunction
for ft in keys(g:ZFVimToc_autoKeymap)
    if g:ZFVimToc_autoKeymap[ft]
        let cmd = ''
        let cmd .= 'augroup ZF_Plugin_ZFVimToc_augroup_' . ft . ' | '
        let cmd .= '    execute "autocmd!" | '
        let cmd .= '    execute "autocmd FileType ' . ft . ' call ZF_VimToc_makeKeymap()" | '
        let cmd .= 'augroup END'
        execute cmd
    endif
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
    return setting
endfunction

function! ZF_Toc(...)
    if empty(expand('%'))
        redraw!
        echo '[ZFVimToc] no file'
        return
    endif
    let setting = s:getSetting()
    let pattern = get(a:, 1)
    if empty(setting) || !empty(pattern)
        call s:ZFTocFallback(pattern)
        return
    endif

    try
        if len(setting.codeBlockBegin) > 0
            let t='(' . setting.titleRegExp . ')'
            let t.='|(' . setting.codeBlockBegin . ')'
            let t.='|(' . setting.codeBlockEnd . ')'
        else
            let t=setting.titleRegExp
        endif
        execute 'silent lvimgrep /' . ZFE2v(t) . '/j %'
    catch /E480/
        redraw!
        echom "[ZFVimToc] no titles."
        return
    catch
        echom v:exception
        return
    endtry

    let loclist = getloclist(0)
    if len(setting.codeBlockBegin) > 0
        let code_block_flag = 0
        let codeBlockBegin=ZFE2v(setting.codeBlockBegin)
        let codeBlockEnd=ZFE2v(setting.codeBlockEnd)
        let i = 1
        let range = len(loclist)
        while i <= range
            let d = loclist[i-1]
            if match(d.text, codeBlockBegin) > -1
                if code_block_flag > 0 && match(d.text, codeBlockEnd) > -1
                    let code_block_flag-=1
                else
                    let code_block_flag+=1
                endif
                let i -= 1
                call remove(loclist, i)
                let range = range - 1
            elseif match(d.text, codeBlockEnd) > -1
                let code_block_flag-=1
                let i -= 1
                call remove(loclist, i)
                let range = range - 1
            elseif code_block_flag > 0
                let i -= 1
                call remove(loclist, i)
                let range = range - 1
            endif
            let i += 1
        endwhile
        call setloclist(0, loclist)
    endif

    if empty(loclist)
        redraw!
        echom "[ZFVimToc] no titles."
        return
    endif

    let cur_line = line(".")
    let toc_line = 0
    lopen 25
    setlocal modifiable
    let titleLevelRegExpMatch=ZFE2v(setting.titleLevelRegExpMatch)
    let titleLevelRegExpReplace=ZFE2v(setting.titleLevelRegExpReplace)
    let titleNameRegExpMatch=ZFE2v(setting.titleNameRegExpMatch)
    let titleNameRegExpReplace=ZFE2v(setting.titleNameRegExpReplace)
    for i in range(len(loclist))
        let d = loclist[i]
        if toc_line == 0
            if d.lnum == cur_line
                let toc_line = i + 1
            elseif d.lnum > cur_line
                let toc_line = i
            endif
        endif
        let level = len(substitute(d.text, titleLevelRegExpMatch, titleLevelRegExpReplace, ''))
        if level > 0
            let level -= 1
        endif
        if len(titleNameRegExpMatch) > 0
            let d.text = substitute(d.text, titleNameRegExpMatch, titleNameRegExpReplace, '')
        endif
        call setline(i + 1, repeat('    ', level). d.text)
    endfor
    setlocal nomodified
    setlocal nomodifiable
    call cursor(toc_line, 0)
endfunction
command! -nargs=* ZFToc :call ZF_Toc(<q-args>)

function! s:ZFTocFallback(...)
    let pattern = get(a:, 1)
    if empty(pattern)
        if get(b:, 'ZF_VimToc_patternNoMatch', 0) || empty(get(b:, 'ZF_VimToc_patternLast', ''))
            call inputsave()
            let pattern = input('[ZFVimToc] title pattern: ', get(b:, 'ZF_VimToc_patternLast', ''))
            call inputrestore()
        else
            let pattern = get(b:, 'ZF_VimToc_patternLast', '')
        endif
    endif
    let b:ZF_VimToc_patternLast = pattern
    if empty(pattern)
        redraw!
        echo '[ZFVimToc] no input, canceled'
        return
    endif
    if exists('b:ZF_VimToc_patternNoMatch')
        unlet b:ZF_VimToc_patternNoMatch
    endif

    try
        execute 'silent lvimgrep /' . ZFE2v(pattern) . '/j %'
    catch /E480/
        let b:ZF_VimToc_patternNoMatch = 1
        redraw!
        echom "[ZFVimToc] no titles."
        return
    catch
        echom v:exception
        return
    endtry

    let loclist = getloclist(0)

    if empty(loclist)
        redraw!
        echom "[ZFVimToc] no titles."
        return
    endif

    let cur_line = line(".")
    let toc_line = 0
    lopen 25
    setlocal modifiable
    for i in range(len(loclist))
        let d = loclist[i]
        if toc_line == 0
            if d.lnum == cur_line
                let toc_line = i + 1
            elseif d.lnum > cur_line
                let toc_line = i
            endif
        endif
        let d.text = substitute(d.text, '^.\{-}|.\{-}| ', '', '')
        call setline(i + 1, d.text)
    endfor
    setlocal nomodified
    setlocal nomodifiable
    call cursor(toc_line, 0)
endfunction

function! ZF_TocPrev(mode)
    let setting = s:getSetting()
    if empty(setting)
        return
    endif
    normal! m`
    if a:mode=='v'
        execute "normal! gv\<esc>"
    endif
    let has_content=0
    let code_block_flag=0
    let titleRegExp=ZFE2v(setting.titleRegExp)
    let codeBlockBegin=ZFE2v(setting.codeBlockBegin)
    let codeBlockEnd=ZFE2v(setting.codeBlockEnd)
    let s:target = 1
    for i in range(getpos('.')[1] - 1, 1, -1)
        let line = getline(i)
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
                let s:target = i
                break
            endif
        elseif match(line, '[^ \t]') > -1
            let has_content=1
        endif
    endfor
    let curPos = getpos('.')
    let curPos[1] = s:target
    call setpos('.', curPos)
    if a:mode=='v'
        normal! m>gv
    endif
endfunction
function! ZF_TocNext(mode)
    let setting = s:getSetting()
    if empty(setting)
        return
    endif
    normal! m`
    if a:mode=='v'
        execute "normal! gv\<esc>"
    endif
    let has_content=0
    let code_block_flag=0
    let titleRegExp=ZFE2v(setting.titleRegExp)
    let codeBlockBegin=ZFE2v(setting.codeBlockBegin)
    let codeBlockEnd=ZFE2v(setting.codeBlockEnd)
    let s:target = line("$")
    for i in range(getpos(".")[1] + 1, line("$"))
        let line = getline(i)
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
                let s:target = i
                break
            endif
        elseif match(line, '[^ \t]') > -1
            let has_content=1
        endif
    endfor
    let curPos = getpos('.')
    let curPos[1] = s:target
    call setpos('.', curPos)
    if a:mode=='v'
        normal! m>gv
    endif
endfunction

