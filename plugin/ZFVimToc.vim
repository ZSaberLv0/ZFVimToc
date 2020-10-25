
if exists('*E2v')
    function! ZFE2v(pattern)
        return E2v(a:pattern)
    endfunction
endif

" ============================================================
function! ZFTocPatternMake(ft, titleToken, codeBlockBegin, codeBlockEnd)
    if !exists('g:ZFToc_setting')
        let g:ZFToc_setting={}
    endi
    let g:ZFToc_setting[a:ft] = {
                \     'titleRegExp' : '^[ \t]*' . a:titleToken . '+ .*$',
                \     'titleLevelRegExpMatch' : '^[ \t]*(' . a:titleToken . '+).*$',
                \     'titleLevelRegExpReplace' : '\1',
                \     'titleNameRegExpMatch' : '^[ \t]*' . a:titleToken . '+[ \t]*(<.*?>)?[ \t]*(.*?)[ \t]*(<.*?>)?[ \t]*$',
                \     'titleNameRegExpReplace' : '\2',
                \     'codeBlockBegin' : a:codeBlockBegin,
                \     'codeBlockEnd' : a:codeBlockEnd,
                \ }
endfunction
if !exists('g:ZFToc_setting') || !exists('g:ZFToc_setting["markdown"]')
    call ZFTocPatternMake('markdown', '[#]', '^[ \t]*```.*$', '^[ \t]*```[ \t]*$')
endi


" ============================================================
command! -nargs=* ZFToc :call ZFToc(<q-args>)

function! ZFTocMakeKeymap(...)
    let bufferOnly = get(a:, 1, 0) ? ' <buffer> ' : ''
    if !empty(get(g:, 'ZFTocKeymap_TOC', '<leader>vt'))
        execute 'nnoremap <expr> ' . bufferOnly . get(g:, 'ZFTocKeymap_TOC', '<leader>vt') . ' "" . ZFTocGeneric(1)'
    endif
    if !empty(get(g:, 'ZFTocKeymap_TOCCustom', '<leader>zt'))
        execute 'nnoremap <expr> ' . bufferOnly . get(g:, 'ZFTocKeymap_TOCCustom', '<leader>zt') . ' "" . ZFTocGeneric(0)'
    endif
    if !empty(get(g:, 'ZFTocKeymap_prev', '[['))
        execute 'nnoremap <silent> ' . bufferOnly . get(g:, 'ZFTocKeymap_prev', '[[') . ' :call ZFTocPrev("n")<cr>'
        execute 'xnoremap <silent> ' . bufferOnly . get(g:, 'ZFTocKeymap_prev', '[[') . ' :<c-u>call ZFTocPrev("v")<cr>'
    endif
    if !empty(get(g:, 'ZFTocKeymap_next', ']]'))
        execute 'nnoremap <silent> ' . bufferOnly . get(g:, 'ZFTocKeymap_next', ']]') . ' :call ZFTocNext("n")<cr>'
        execute 'xnoremap <silent> ' . bufferOnly . get(g:, 'ZFTocKeymap_next', ']]') . ' :<c-u>call ZFTocNext("v")<cr>'
    endif
endfunction
call ZFTocMakeKeymap(0)

if get(g:, 'ZFTocMakeKeymapToLocal', 1)
    augroup ZFTocMakeKeymapToLocal_augroup
        autocmd!
        autocmd BufReadPost,BufCreate * call ZFTocMakeKeymap(1)
    augroup END
endif


" ============================================================
function! s:getSetting()
    if !exists('*ZFE2v')
        echo 'ZFToc require othree/eregex.vim'
        echo '    install it or supply custom wrapper function ZFE2v(pattern)'
        return {}
    endif
    let setting = get(g:ZFToc_setting, &filetype, {})
    if empty(setting) && &filetype != ''
        let setting = get(g:ZFToc_setting, '', {})
    endif
    return setting
endfunction

function! ZFToc(...)
    if empty(expand('%'))
        redraw!
        echo '[ZFToc] no file'
        return
    endif
    let setting = s:getSetting()
    let pattern = get(a:, 1)
    if empty(setting) || !empty(pattern)
        call s:ZFTocFallback(pattern)
        return
    endif

    if exists('b:ZFToc_patternNoMatch')
        unlet b:ZFToc_patternNoMatch
    endif
    if exists('b:ZFToc_patternLast')
        unlet b:ZFToc_patternLast
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
        echom "[ZFToc] no titles."
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
        echom "[ZFToc] no titles."
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

function! ZFTocGeneric(autoStart)
    if empty(expand('%'))
        redraw!
        echo '[ZFToc] no file'
        return ''
    endif

    if get(b:, 'ZFToc_patternNoMatch', 0) || !a:autoStart
        call feedkeys(':ZFToc' . (a:autoStart ? "\<cr>" : ' '), 't')
    else
        call feedkeys(":ZFToc \<c-r>=get(b:, 'ZFToc_patternLast', '')\<cr>\<cr>", 't')
    endif
    return ''
endfunction

function! s:ZFTocFallback(...)
    let pattern = get(a:, 1)
    if empty(pattern)
        if get(b:, 'ZFToc_patternNoMatch', 0) || empty(get(b:, 'ZFToc_patternLast', ''))
            call inputsave()
            let pattern = input('[ZFToc] title pattern: ', get(b:, 'ZFToc_patternLast', ''))
            call inputrestore()
        else
            let pattern = get(b:, 'ZFToc_patternLast', '')
        endif
    endif
    let b:ZFToc_patternLast = pattern
    if empty(pattern)
        redraw!
        echo '[ZFToc] no input, canceled'
        return
    endif
    if exists('b:ZFToc_patternNoMatch')
        unlet b:ZFToc_patternNoMatch
    endif

    try
        execute 'silent lvimgrep /' . ZFE2v(pattern) . '/j %'
    catch /E480/
        let b:ZFToc_patternNoMatch = 1
        redraw!
        echom "[ZFToc] no titles."
        return
    catch
        echom v:exception
        return
    endtry

    let loclist = getloclist(0)

    if empty(loclist)
        redraw!
        echom "[ZFToc] no titles."
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

function! ZFTocPrev(mode)
    let setting = s:getSetting()
    if !empty(get(b:, 'ZFToc_patternLast', ''))
        let titleRegExp=ZFE2v(b:ZFToc_patternLast)
        let codeBlockBegin=''
        let codeBlockEnd=''
    elseif !empty(setting)
        let titleRegExp=ZFE2v(setting.titleRegExp)
        let codeBlockBegin=ZFE2v(setting.codeBlockBegin)
        let codeBlockEnd=ZFE2v(setting.codeBlockEnd)
    else
        ZFToc
        return
    endif
    normal! m`
    if a:mode=='v'
        execute "normal! gv\<esc>"
    endif
    let has_content=0
    let code_block_flag=0
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
function! ZFTocNext(mode)
    let setting = s:getSetting()
    if !empty(get(b:, 'ZFToc_patternLast', ''))
        let titleRegExp=ZFE2v(b:ZFToc_patternLast)
        let codeBlockBegin=''
        let codeBlockEnd=''
    elseif !empty(setting)
        let titleRegExp=ZFE2v(setting.titleRegExp)
        let codeBlockBegin=ZFE2v(setting.codeBlockBegin)
        let codeBlockEnd=ZFE2v(setting.codeBlockEnd)
    else
        ZFToc
        return
    endif
    normal! m`
    if a:mode=='v'
        execute "normal! gv\<esc>"
    endif
    let has_content=0
    let code_block_flag=0
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

