
if exists('*E2v')
    function! ZFE2v(pattern)
        if match(a:pattern, '^\\[vVmM]') == 0
            return a:pattern
        else
            return E2v(a:pattern)
        endif
    endfunction
endif

" ============================================================
function! ZFTocPatternMake(ft, titleToken, codeBlockBegin, codeBlockEnd)
    if !exists('g:ZFToc_setting')
        let g:ZFToc_setting = {}
    endif
    let g:ZFToc_setting[a:ft] = {
                \     'titleRegExp' : '^[ \t]*' . a:titleToken . '+ .*$',
                \     'titleInfoGetter' : '',
                \     'titleLevelRegExpMatch' : '^[ \t]*(' . a:titleToken . '+).*$',
                \     'titleLevelRegExpReplace' : '\1',
                \     'titleNameRegExpMatch' : '^[ \t]*' . a:titleToken . '+[ \t]*(<.*?>)?[ \t]*(.*?)[ \t]*(<.*?>)?[ \t]*$',
                \     'titleNameRegExpReplace' : '\2',
                \     'codeBlockBegin' : a:codeBlockBegin,
                \     'codeBlockEnd' : a:codeBlockEnd,
                \ }
endfunction
if !exists('g:ZFToc_setting')
    call ZFTocPatternMake('markdown', '[#]', '^[ \t]*```.*$', '^[ \t]*```[ \t]*$')

    if get(g:, 'ZFToc_fallback_enable', 1)
        " ^[ \t]*(class|interface|protocol)\>
        " ^[ \t]*(public|protected|private|virtual|static|inline|def(ine)?|func(tion)?)[a-z0-9_ \*<>:!\?]+\(
        " ^[a-z_].*=[ \t]*(func(tion)?)?[ \t]*\([a-z0-9_ ,:!\?]*\)[ \t]*([\-=]>)?[ \t]*\{
        " ^[ \t]*[a-z0-9_]+[ \t]*\([^!;=\(\)]*\)[ \t]*(\{|\n[ \t]*\{)
        "
        " ^[ \t]*\/\*
        " ^[ \t]*\*+\/[ \t]*$|^[ \t]*\/\*.*\*\/[ \t]*$
        "
        " ^[ \t]*(\/\/|#|rem(ark)\>|return\>|if\>|for_?(each)?\>|while\>|switch\>)
        let g:ZFToc_setting['*'] = {
                    \   'titleRegExp' : '\m' . '^[ \t]*\%(class\|interface\|protocol\)\>'
                    \     . '\|' . '^[ \t]*\%(public\|protected\|private\|virtual\|static\|inline\|def\%(ine\)\=\|func\%(tion\)\=\)[a-z0-9_ \*<>:!?]\+('
                    \     . '\|' . '^[a-z_].*=[ \t]*\%(func\%(tion\)\=\)\=[ \t]*([a-z0-9_ ,:!?]*)[ \t]*\%([\-=]>\)\=[ \t]*{'
                    \     . '\|' . '^[ \t]*[a-z0-9_]\+[ \t]*([^!;=()]*)[ \t]*\%({\|\n[ \t]*{\)'
                    \   ,
                    \   'codeBlockBegin' : '\m' . '^[ \t]*\/\*',
                    \   'codeBlockEnd' : '\m' . '^[ \t]*\*\+\/[ \t]*$\|^[ \t]*\/\*.*\*\/[ \t]*$',
                    \   'excludeRegExp' : '^[ \t]*(\/\/|#|rem(ark)\>|return\>|if\>|for_?(each)?\>|while\>|switch\>)',
                    \ }
    endif
endi


" ============================================================
command! -nargs=* ZFToc :call ZFToc(<q-args>)
command! -nargs=0 ZFTocReset :call ZFTocReset()

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

if get(g:, 'ZFTocMakeKeymapToGlobal', 1)
    call ZFTocMakeKeymap(0)
endif
if get(g:, 'ZFTocMakeKeymapToLocal', 1)
    augroup ZFTocMakeKeymapToLocal_augroup
        autocmd!
        autocmd BufReadPost,BufCreate * call ZFTocMakeKeymap(1)
    augroup END
endif


" ============================================================
function! ZFTocGeneric(autoStart)
    if empty(expand('%'))
        redraw!
        echo '[ZFToc] no file'
        return ''
    endif

    " use feedkeys to bypass E523
    " reason: functions inside expr map can not change buffer text
    if get(b:, 'ZFTocFallback_noMatch', 0) || !a:autoStart
        if exists('b:ZFTocFallback_noMatch')
            let saved_noMatch = b:ZFTocFallback_noMatch
            let saved_setting = b:ZFTocFallback_setting
            unlet b:ZFTocFallback_noMatch
            unlet b:ZFTocFallback_setting
        endif
        call feedkeys(':ZFToc' . (a:autoStart ? "\<cr>" : ' '), 'nt')

        " restore in case user canceled
        if empty(get(b:, 'ZFTocFallback_setting', {})) && exists('saved_noMatch')
            let b:ZFTocFallback_noMatch = saved_noMatch
            let b:ZFTocFallback_setting = saved_setting
        endif
    else
        call feedkeys(":ZFToc\<cr>", 'nt')
    endif
    return ''
endfunction

function! ZFToc(...)
    if empty(expand('%'))
        redraw!
        echo '[ZFToc] no file'
        return 0
    endif

    let setting = s:getSetting()
    let pattern = get(a:, 1, '')
    if empty(setting) || !empty(pattern)
        return s:ZFTocFallback(pattern)
    else
        return s:toc(setting)
    endif
endfunction

function! ZFTocPrev(mode)
    let setting = s:getSetting()
    if !empty(setting)
        call s:tocPrev(setting, a:mode)
    elseif s:prepareSetting() && s:toc(b:ZFTocFallback_setting, 0)
        call s:tocPrev(b:ZFTocFallback_setting, a:mode)
    endif
endfunction

function! ZFTocNext(mode)
    let setting = s:getSetting()
    if !empty(setting)
        call s:tocNext(setting, a:mode)
    elseif s:prepareSetting() && s:toc(b:ZFTocFallback_setting, 0)
        call s:tocNext(b:ZFTocFallback_setting, a:mode)
    endif
endfunction

function! ZFTocReset()
    if exists('b:ZFTocFallback_setting')
        unlet b:ZFTocFallback_setting
    endif
endfunction


" ============================================================
function! s:getSetting()
    if !exists('*ZFE2v')
        echo 'ZFToc require othree/eregex.vim'
        echo '    install it or supply custom wrapper function ZFE2v(pattern)'
        return {}
    endif

    let setting = get(b:, 'ZFTocFallback_setting', {})
    if empty(setting)
        let setting = get(g:ZFToc_setting, &filetype, {})
        if empty(setting) && &filetype != ''
            let setting = get(g:ZFToc_setting, '*', {})
        endif
    endif

    if empty(get(setting, 'titleRegExp', ''))
        return {}
    else
        return setting
    endif
endfunction

function! s:prepareSetting(...)
    let pattern = get(a:, 1, '')
    if empty(pattern)
        if get(b:, 'ZFTocFallback_noMatch', 0) || empty(get(b:, 'ZFTocFallback_setting', {}))
            call inputsave()
            let pattern = input('[ZFToc] title pattern: ',
                        \ get(get(b:, 'ZFTocFallback_setting', {}), 'titleRegExp', ''))
            call inputrestore()
        else
            unlet pattern
            let pattern = b:ZFTocFallback_setting
        endif
    endif
    if empty(pattern)
        redraw!
        echo '[ZFToc] no input, canceled'
        return 0
    endif

    if type(pattern) == type({})
        let b:ZFTocFallback_setting = pattern
    else
        let b:ZFTocFallback_setting = {
                    \   'titleRegExp' : pattern,
                    \ }
    endif
    return 1
endfunction

" process files that ft not configured
function! s:ZFTocFallback(...)
    if !s:prepareSetting(get(a:, 1, ''))
        return 0
    endif
    let b:ZFTocFallback_noMatch = s:toc(b:ZFTocFallback_setting)
    return b:ZFTocFallback_noMatch
endfunction

function! s:toc(setting, ...)
    let autoOpen = get(a:, 1, 1)

    try
        if len(get(a:setting, 'codeBlockBegin', '')) > 0
                    \ && len(get(a:setting, 'codeBlockEnd', '')) > 0
            if match(a:setting.titleRegExp, '^\\[vVmM]') == 0
                        \ || match(a:setting.codeBlockBegin, '^\\[vVmM]') == 0
                        \ || match(a:setting.codeBlockEnd, '^\\[vVmM]') == 0
                if match(a:setting.titleRegExp, '^\\[vVmM]') == 0
                    let t = matchstr(a:setting.titleRegExp, '^\\[vVmM]')
                    let titleRegExp = strpart(a:setting.titleRegExp, 2)
                endif
                if match(a:setting.codeBlockBegin, '^\\[vVmM]') == 0
                    let t = matchstr(a:setting.codeBlockBegin, '^\\[vVmM]')
                    let codeBlockBegin = strpart(a:setting.codeBlockBegin, 2)
                endif
                if match(a:setting.codeBlockEnd, '^\\[vVmM]') == 0
                    let t = matchstr(a:setting.codeBlockEnd, '^\\[vVmM]')
                    let codeBlockEnd = strpart(a:setting.codeBlockEnd, 2)
                endif

                if t == '\v'
                    let tL = '('
                    let tR = ')'
                    let tS = '|'
                elseif t == '\V'
                    let tL = '\('
                    let tR = '\)'
                    let tS = '\|'
                elseif t == '\m'
                    let tL = '\('
                    let tR = '\)'
                    let tS = '\|'
                elseif t == '\M'
                    let tL = '\('
                    let tR = '\)'
                    let tS = '\|'
                endif

                let t .=      tL . titleRegExp . tR
                let t .= tS . tL . codeBlockBegin . tR
                let t .= tS . tL . codeBlockEnd . tR
            else
                let t = '(' . a:setting.titleRegExp . ')'
                let t .= '|(' . a:setting.codeBlockBegin . ')'
                let t .= '|(' . a:setting.codeBlockEnd . ')'
            endif
        else
            let t = a:setting.titleRegExp
        endif
        execute 'silent lvimgrep /' . ZFE2v(t) . '/j %'
    catch /E480/
        redraw!
        echom "[ZFToc] no titles."
        return 0
    catch
        echom v:exception
        return 0
    endtry

    let loclist = getloclist(0)
    if len(get(a:setting, 'codeBlockBegin', '')) > 0
        let code_block_flag = 0
        let codeBlockBegin = ZFE2v(get(a:setting, 'codeBlockBegin', ''))
        let codeBlockEnd = ZFE2v(get(a:setting, 'codeBlockEnd', ''))
        let excludeRegExp = ZFE2v(get(a:setting, 'excludeRegExp', ''))
        let i = 0
        let range = len(loclist)
        while i < range
            let d = loclist[i]
            if !empty(excludeRegExp) && match(d.text, excludeRegExp) >= 0
                call remove(loclist, i)
                let i -= 1
                let range -= 1
            elseif match(d.text, codeBlockBegin) >= 0
                if match(d.text, codeBlockEnd) < 0
                    let code_block_flag += 1
                endif
                call remove(loclist, i)
                let i -= 1
                let range -= 1
            elseif match(d.text, codeBlockEnd) >= 0
                if code_block_flag > 0
                    let code_block_flag -= 1
                endif
                call remove(loclist, i)
                let i -= 1
                let range -= 1
            elseif code_block_flag > 0
                call remove(loclist, i)
                let i -= 1
                let range -= 1
            endif
            let i += 1
        endwhile
        call setloclist(0, loclist)
    endif

    if empty(loclist)
        redraw!
        echom "[ZFToc] no titles."
        return 0
    endif
    if !autoOpen
        return 1
    endif

    call s:fold(loclist)

    let cur_line = line(".")
    let toc_line = 0
    lopen 25
    setlocal modifiable
    let Fn_titleInfoGetter = get(a:setting, 'titleInfoGetter', '')
    let titleLevelRegExpMatch = ZFE2v(get(a:setting, 'titleLevelRegExpMatch', ''))
    let titleLevelRegExpReplace = ZFE2v(get(a:setting, 'titleLevelRegExpReplace', ''))
    let titleNameRegExpMatch = ZFE2v(get(a:setting, 'titleNameRegExpMatch', ''))
    let titleNameRegExpReplace = ZFE2v(get(a:setting, 'titleNameRegExpReplace', ''))
    for i in range(len(loclist))
        let d = loclist[i]
        if toc_line == 0
            if d.lnum == cur_line
                let toc_line = i + 1
            elseif d.lnum > cur_line
                let toc_line = i
            endif
        endif
        if !empty(Fn_titleInfoGetter)
            let info = Fn_titleInfoGetter(d.text, d.end_lnum)
            if !empty(get(info, 'text', ''))
                let d.text = info['text']
            endif
            let level = get(info, 'level', 0)
        else
            if len(titleLevelRegExpMatch) > 0
                let level = len(substitute(d.text, titleLevelRegExpMatch, titleLevelRegExpReplace, ''))
                if level > 0
                    let level -= 1
                endif
            else
                let level = 0
            endif
            if len(titleNameRegExpMatch) > 0
                let d.text = substitute(d.text, titleNameRegExpMatch, titleNameRegExpReplace, '')
            endif
        endif
        call setline(i + 1, repeat('    ', level) . d.text)
    endfor
    if toc_line == 0 && !empty(loclist)
        let toc_line = len(loclist)
    endif

    setlocal nomodified
    setlocal nomodifiable
    call cursor(toc_line, 0)

    return 1
endfunction

function! s:tocPrev(setting, mode)
    let titleRegExp = ZFE2v(a:setting.titleRegExp)
    let codeBlockBegin = ZFE2v(get(a:setting, 'codeBlockBegin', ''))
    let codeBlockEnd = ZFE2v(get(a:setting, 'codeBlockEnd', ''))
    let excludeRegExp = ZFE2v(get(a:setting, 'excludeRegExp', ''))

    normal! m`
    if a:mode == 'v'
        execute "normal! gv\<esc>"
    endif
    let code_block_flag = 0
    let s:target = 1
    for i in range(getpos('.')[1] - 1, 1, -1)
        let line = getline(i)
        if !empty(excludeRegExp) && match(line, excludeRegExp) >= 0
            continue
        endif
        if len(codeBlockBegin) > 0
            if match(line, codeBlockEnd) >= 0
                if match(line, codeBlockBegin) < 0
                    let code_block_flag += 1
                endif
                continue
            elseif match(line, codeBlockBegin) >= 0
                if code_block_flag > 0
                    let code_block_flag -= 1
                endif
                continue
            elseif code_block_flag > 0
                continue
            endif
        endif
        if match(line, titleRegExp) >= 0
            let s:target = i
            break
        endif
    endfor
    let curPos = getpos('.')
    let curPos[1] = s:target
    call setpos('.', curPos)
    if a:mode == 'v'
        normal! m>gv
    endif
endfunction

function! s:tocNext(setting, mode)
    let titleRegExp = ZFE2v(a:setting.titleRegExp)
    let codeBlockBegin = ZFE2v(get(a:setting, 'codeBlockBegin', ''))
    let codeBlockEnd = ZFE2v(get(a:setting, 'codeBlockEnd', ''))
    let excludeRegExp = ZFE2v(get(a:setting, 'excludeRegExp', ''))

    normal! m`
    if a:mode == 'v'
        execute "normal! gv\<esc>"
    endif
    let code_block_flag = 0
    let s:target = line("$")
    for i in range(getpos(".")[1] + 1, line("$"))
        let line = getline(i)
        if !empty(excludeRegExp) && match(line, excludeRegExp) >= 0
            continue
        endif
        if len(codeBlockBegin) > 0
            if match(line, codeBlockBegin) >= 0
                if match(line, codeBlockEnd) < 0
                    let code_block_flag += 1
                endif
                continue
            elseif match(line, codeBlockEnd) >= 0
                if code_block_flag > 0
                    let code_block_flag -= 1
                endif
                continue
            elseif code_block_flag > 0
                continue
            endif
        endif
        if match(line, titleRegExp) >= 0
            let s:target = i
            break
        endif
    endfor
    let curPos = getpos('.')
    let curPos[1] = s:target
    call setpos('.', curPos)
    if a:mode == 'v'
        normal! m>gv
    endif
endfunction

function! s:fold(loclist)
    if !get(g:, 'ZFToc_fold_enable', 1)
        return
    endif
    if &foldmethod != 'manual' && !get(g:, 'ZFToc_fold_auto_change_foldmethod', 0)
        return
    endif

    normal! zE

    let iPrev = 0
    let iEnd = line('$')
    for loc in a:loclist
        let i = loc['end_lnum'] - 1
        if i > iPrev
            call s:doFold(iPrev, i - 1)
        endif
        let iPrev = i + 1
    endfor
    if iPrev != 0 && iEnd > iPrev
        call s:doFold(iPrev, iEnd - 1)
    endif

    normal! zR
endfunction

function! s:doFold(iL, iR)
    if a:iL > a:iR
        return
    endif
    if a:iL == a:iR && getline(a:iL + 1) == ''
        return
    endif
    execute ":" . (a:iL+1) . "," . (a:iR+1) . "fold"
endfunction

