
if exists('*E2v')
    function! ZFE2v(pattern)
        return E2v(a:pattern)
    endfunction
endif

if !exists('*ZFTocE2v')
    " option: {
    "   'fixE872' : 1/0,
    " }
    function! ZFTocE2v(pattern, ...)
        let option = get(a:, 1, {})
        if match(a:pattern, '^\\[vVmM]') == 0
            return a:pattern
        endif

        if exists('*ZFE2v')
            let pattern = ZFE2v(a:pattern)
        else
            let pattern = a:pattern
        endif
        if get(option, 'fixE872', get(g:, 'ZFToc_fixE872', 1))
            let pattern = substitute(pattern, '\\\\', '_ZFTOC_BS_', 'g')
            let pattern = substitute(pattern, '\\(', '\\%(', 'g')
            return substitute(pattern, '_ZFTOC_BS_', '\\\\', 'g')
        else
            return pattern
        endif
    endfunction
endif

let s:option_no_fixE872 = {'fixE872' : 0}

" ============================================================
function! ZFTocPatternMake(ft, titleToken, codeBlockBegin, codeBlockEnd)
    if !exists('g:ZFToc_setting')
        let g:ZFToc_setting = {}
    endif
    if exists('*ZFE2v')
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
    else
        let g:ZFToc_setting[a:ft] = {
                    \     'titleRegExp' : '^[ \t]*' . a:titleToken . '\+ .*$',
                    \     'titleInfoGetter' : '',
                    \     'titleLevelRegExpMatch' : '^[ \t]*\(' . a:titleToken . '\+\).*$',
                    \     'titleLevelRegExpReplace' : '\1',
                    \     'titleNameRegExpMatch' : '^[ \t]*' . a:titleToken . '\+[ \t]*\(<.\{-}>\)\=[ \t]*\(.\{-}\)[ \t]*\(<.\{-}>\)\=[ \t]*$',
                    \     'titleNameRegExpReplace' : '\2',
                    \     'codeBlockBegin' : a:codeBlockBegin,
                    \     'codeBlockEnd' : a:codeBlockEnd,
                    \ }
    endif
endfunction
if !exists('g:ZFToc_setting')
    call ZFTocPatternMake('markdown', '[#]', '^[ \t]*```.*$', '^[ \t]*```[ \t]*$')

    if get(g:, 'ZFToc_fallback_enable', 1)
        " ^[ \t]*(public|protected|private|static|final)*[ \t]*(class|interface|protocol|abstract)\>
        "     class
        "     public static final interface
        "
        " ^[ \t]*(public|protected|private|virtual|static|inline|extern|def(ine)?|func(tion)?)[a-z0-9_ \*<>:!\?]+\(
        "     public func(
        "
        " ^[a-z_].*=[ \t]*(fun|(func(tion)?))?[ \t]*\([a-z0-9_ ,:!\?]*\)[ \t]*([\-=]>)?[ \t\r\n]*\{
        "     abc = func(xx) {
        "     abc = (xxx) => {
        "
        " ^[ \t]*[a-z0-9_]+[ \t]*\([^!;=\(\)]*\)[ \t\r\n]*\{
        "     abc(xxx) {
        "
        " ^[ \t]*[a-z_][a-z0-9_ <>\*&]+[ \t]+[<>\*&]*[a-z_][a-z0-9_:#]+[ \t]*\(
        "     abc abc::abc#xyz(
        "     abc &abc::abc#xyz(
        "     abc *abc::abc#xyz(
        "
        " ^[ \t]*([a-z_][a-z0-9_ \t<>\*&:]+)?\<operator\>.*\(
        "     abc abc::operator xxx(
        if exists('*ZFE2v')
            let g:ZFToc_setting['*'] = {
                        \   'titleRegExp' : '^[ \t]*(public|protected|private|static|final)*[ \t]*(class|interface|protocol|abstract)\>'
                        \     . '|' . '^[ \t]*(public|protected|private|virtual|static|inline|extern|def(ine)?|func(tion)?)[a-z0-9_ \*<>:!\?]+\('
                        \     . '|' . '^[a-z_].*=[ \t]*(fun|(func(tion)?))?[ \t]*\([a-z0-9_ ,:!\?]*\)[ \t]*([\-=]>)?[ \t\r\n]*\{'
                        \     . '|' . '^[ \t]*[a-z0-9_]+[ \t]*\([^!;=\(\)]*\)[ \t\r\n]*\{'
                        \     . '|' . '^[ \t]*[a-z_][a-z0-9_ <>\*&]+[ \t]+[<>\*&]*[a-z_][a-z0-9_:#]+[ \t]*\('
                        \     . '|' . '^[ \t]*([a-z_][a-z0-9_ \t<>\*&:]+)?\<operator\>.*\('
                        \   ,
                        \   'codeBlockBegin' : '^[ \t]*\/\*',
                        \   'codeBlockEnd' : '^[ \t]*\*+\/[ \t]*$|^[ \t]*\/\*.*\*\/[ \t]*$',
                        \   'excludeRegExp' : '^[ \t]*(\/\/|#|"|rem(ark)\>)'
                        \     . '|' . '^[ \t]*(return|if|else|elseif|elif|fi|for_?(each)?|while|switch|call|echo)\>'
                        \     . '|' . '^[ \t]*au(tocmd)?\>'
                        \     . '|' . '^[ \t]*[nicxv](nore)?map\>'
                        \   ,
                        \ }
        else
            let g:ZFToc_setting['*'] = {
                        \   'titleRegExp' : '^[ \t]*\(public\|protected\|private\|static\|final\)*[ \t]*\(class\|interface\|protocol\|abstract\)\>'
                        \     . '\|' . '^[ \t]*\(public\|protected\|private\|virtual\|static\|inline\|extern\|def\(ine\)\=\|func\(tion\)\=\)[a-z0-9_ \*<>:!?]\+('
                        \     . '\|' . '^[a-z_].*=[ \t]*\(func\(tion\)\=\)\=[ \t]*([a-z0-9_ ,:!?]*)[ \t]*\([\-=]>\)\=[ \t\r\n]*{'
                        \     . '\|' . '^[ \t]*[a-z0-9_]\+[ \t]*([^!;=()]*)[ \t\r\n]*{'
                        \     . '\|' . '^[ \t]*[a-z_][a-z0-9_ <>\*&]\+[ \t]\+[<>\*&]*[a-z_][a-z0-9_:#]\+[ \t]*('
                        \     . '\|' . '^[ \t]*\([a-z_][a-z0-9_ \t<>\*&:]\+\)\=\<operator\>.*('
                        \   ,
                        \   'codeBlockBegin' : '^[ \t]*\/\*',
                        \   'codeBlockEnd' : '^[ \t]*\*\+\/[ \t]*$\|^[ \t]*\/\*.*\*\/[ \t]*$',
                        \   'excludeRegExp' : '^[ \t]*\(\/\/\|#\|"\|rem\(ark\)\>\)'
                        \     . '\|' . '^[ \t]*\(return\|if\|else\|elseif\|elif\|fi\|for_\=\(each\)\=\|while\|switch\|call\|echo\)\>'
                        \     . '\|' . '^[ \t]*au\(tocmd\)\=\>'
                        \     . '\|' . '^[ \t]*[nicxv]\(nore\)\=map\>'
                        \   ,
                        \ }
        endif
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
    if !empty(get(b:, 'ZFTocFallback_loclist', [])) || !a:autoStart
        if !empty(get(b:, 'ZFTocFallback_loclist', []))
            let saved_loclist = b:ZFTocFallback_loclist
            let saved_setting = b:ZFTocFallback_setting
            unlet b:ZFTocFallback_loclist
            unlet b:ZFTocFallback_setting
        endif
        call feedkeys(':ZFToc' . (a:autoStart ? "\<cr>" : ' '), 'nt')

        " restore in case user canceled
        if empty(get(b:, 'ZFTocFallback_setting', {})) && exists('saved_loclist')
            let b:ZFTocFallback_loclist = saved_loclist
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
        return []
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
    call s:tocJump(a:mode, 0)
endfunction

function! ZFTocNext(mode)
    call s:tocJump(a:mode, 1)
endfunction

function! ZFTocReset()
    if exists('b:ZFTocFallback_loclist')
        unlet b:ZFTocFallback_loclist
    endif
    if exists('b:ZFTocFallback_setting')
        unlet b:ZFTocFallback_setting
    endif
    if exists('b:ZFToc_loclist')
        unlet b:ZFToc_loclist
    endif
endfunction


" ============================================================
function! s:getSetting()
    let setting = get(b:, 'ZFTocFallback_setting', {})
    if empty(setting)
        let setting = get(b:, 'ZFToc_setting', {})
        if empty(setting)
            let setting = get(g:ZFToc_setting, &filetype, {})
            if empty(setting)
                let setting = get(g:ZFToc_setting, '*', {})
            endif
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
        if !empty(get(b:, 'ZFTocFallback_loclist', [])) || empty(get(b:, 'ZFTocFallback_setting', {}))
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
    let b:ZFTocFallback_loclist = s:toc(b:ZFTocFallback_setting)
    return b:ZFTocFallback_loclist
endfunction

function! s:toc(setting, ...)
    let autoOpen = get(a:, 1, 1)

    if exists('b:ZFToc_loclist')
        unlet b:ZFToc_loclist
    endif

    try
        if len(get(a:setting, 'codeBlockBegin', '')) > 0
                    \ && len(get(a:setting, 'codeBlockEnd', '')) > 0
            if match(a:setting['titleRegExp'], '^\\[vVmM]') == 0
                        \ || match(a:setting['codeBlockBegin'], '^\\[vVmM]') == 0
                        \ || match(a:setting['codeBlockEnd'], '^\\[vVmM]') == 0
                if match(a:setting['titleRegExp'], '^\\[vVmM]') == 0
                    let t = matchstr(a:setting['titleRegExp'], '^\\[vVmM]')
                    let titleRegExp = strpart(a:setting['titleRegExp'], 2)
                endif
                if match(a:setting['codeBlockBegin'], '^\\[vVmM]') == 0
                    let t = matchstr(a:setting['codeBlockBegin'], '^\\[vVmM]')
                    let codeBlockBegin = strpart(a:setting['codeBlockBegin'], 2)
                endif
                if match(a:setting['codeBlockEnd'], '^\\[vVmM]') == 0
                    let t = matchstr(a:setting['codeBlockEnd'], '^\\[vVmM]')
                    let codeBlockEnd = strpart(a:setting['codeBlockEnd'], 2)
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
                let t = '(' . a:setting['titleRegExp'] . ')'
                let t .= '|(' . a:setting['codeBlockBegin'] . ')'
                let t .= '|(' . a:setting['codeBlockEnd'] . ')'
            endif
        else
            let t = a:setting['titleRegExp']
        endif
        let wildignoreSaved = &wildignore
        noautocmd let &wildignore = ''
        execute 'silent lvimgrep /' . ZFTocE2v(t) . '/j %'
        noautocmd let &wildignore = wildignoreSaved
    catch /E480/
        redraw!
        echom "[ZFToc] no titles."
        return []
    catch
        echom v:exception
        return []
    endtry

    let loclist = getloclist(0)
    if len(get(a:setting, 'codeBlockBegin', '')) > 0
        let codeBlockFlag = 0
        let codeBlockBegin = ZFTocE2v(get(a:setting, 'codeBlockBegin', ''))
        let codeBlockEnd = ZFTocE2v(get(a:setting, 'codeBlockEnd', ''))
        let excludeRegExp = ZFTocE2v(get(a:setting, 'excludeRegExp', ''))
        let i = 0
        let range = len(loclist)
        while i < range
            let d = loclist[i]
            let codeBlockBeginMatch = match(d['text'], codeBlockBegin)
            let codeBlockEndMatch = match(d['text'], codeBlockEnd)
            if !empty(excludeRegExp) && match(d['text'], excludeRegExp) >= 0
                call remove(loclist, i)
                let i -= 1
                let range -= 1
            elseif codeBlockBeginMatch >= 0
                        \ && (codeBlockEndMatch < 0 || codeBlockBeginMatch != codeBlockEndMatch)
                let codeBlockFlag += 1
                call remove(loclist, i)
                let i -= 1
                let range -= 1
            elseif codeBlockEndMatch >= 0
                        \ && (codeBlockFlag > 0 || codeBlockBeginMatch >= 0)
                if codeBlockFlag > 0
                    let codeBlockFlag -= 1
                endif
                call remove(loclist, i)
                let i -= 1
                let range -= 1
            elseif codeBlockFlag > 0
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
        return []
    endif

    let b:ZFToc_loclist = loclist

    if !autoOpen
        return loclist
    endif

    call s:fold(loclist)

    let cur_line = line(".")
    let toc_line = 0
    lopen 25
    setlocal modifiable
    let Fn_titleInfoGetter = get(a:setting, 'titleInfoGetter', '')
    let titleLevelRegExpMatch = ZFTocE2v(get(a:setting, 'titleLevelRegExpMatch', ''), s:option_no_fixE872)
    let titleLevelRegExpReplace = ZFTocE2v(get(a:setting, 'titleLevelRegExpReplace', ''), s:option_no_fixE872)
    let titleNameRegExpMatch = ZFTocE2v(get(a:setting, 'titleNameRegExpMatch', ''), s:option_no_fixE872)
    let titleNameRegExpReplace = ZFTocE2v(get(a:setting, 'titleNameRegExpReplace', ''), s:option_no_fixE872)
    for i in range(len(loclist))
        let d = loclist[i]
        if toc_line == 0
            if d['lnum'] == cur_line
                let toc_line = i + 1
            elseif d['lnum'] > cur_line
                let toc_line = i
            endif
        endif
        if !empty(Fn_titleInfoGetter)
            let info = Fn_titleInfoGetter(d['text'], d['lnum'])
            if !empty(get(info, 'text', ''))
                let d['text'] = info['text']
            endif
            let level = get(info, 'level', 0)
        else
            if len(titleLevelRegExpMatch) > 0
                let level = len(substitute(d['text'], titleLevelRegExpMatch, titleLevelRegExpReplace, ''))
                if level > 0
                    let level -= 1
                endif
            else
                let level = 0
            endif
            if len(titleNameRegExpMatch) > 0
                let d['text'] = substitute(d['text'], titleNameRegExpMatch, titleNameRegExpReplace, '')
            endif
        endif
        call setline(i + 1, repeat('    ', level) . d['text'])
    endfor
    if toc_line == 0 && !empty(loclist)
        let toc_line = len(loclist)
    endif

    setlocal nomodified
    setlocal nomodifiable
    call cursor(toc_line, 0)

    return loclist
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
        let i = loc['lnum'] - 1
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

function! s:tocJump(mode, isNext)
    if &filetype == 'qf'
        if a:isNext
            normal! j
        else
            normal! k
        endif
        execute "normal \<cr>"
        return
    endif

    normal! m`
    if a:mode == 'v'
        execute "normal! gv\<esc>"
    endif

    let setting = s:getSetting()
    if !empty(setting)
        let loclist = s:toc(setting, 0)
    elseif s:prepareSetting()
        let loclist = s:toc(b:ZFTocFallback_setting, 0)
    else
        let loclist = []
    endif
    if !empty(loclist)
        call s:tocJumpImpl(loclist, a:isNext)
    endif

    if a:mode == 'v'
        normal! m>gv
    endif
endfunction
function! s:tocJumpImpl(loclist, isNext)
    let line = line('.')
    if a:isNext
        let lineTarget = line('$')
        let i = len(a:loclist) - 1
        let iEnd = -1
        while i != iEnd
            let d = a:loclist[i]
            if line >= d['lnum']
                if i + 1 < len(a:loclist)
                    let lineTarget = a:loclist[i + 1]['lnum']
                endif
                break
            else
                let lineTarget = d['lnum']
            endif
            let i -= 1
        endwhile
    else
        let lineTarget = 1
        let i = 0
        let iEnd = len(a:loclist)
        while i != iEnd
            let d = a:loclist[i]
            if line <= d['lnum']
                if i - 1 >= 0
                    let lineTarget = a:loclist[i - 1]['lnum']
                endif
                break
            else
                let lineTarget = d['lnum']
            endif
            let i += 1
        endwhile
    endif
    if line == lineTarget
        return
    endif

    let curPos = getpos('.')
    let curPos[1] = lineTarget
    call setpos('.', curPos)
endfunction

