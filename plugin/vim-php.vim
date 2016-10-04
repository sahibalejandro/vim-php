function! PhpNamespace()

    let l:class = expand('<cword>')
    let s:tags = SearchTags('^'.l:class.'$')

    " If no tags found then we can't do nothing.
    if empty(s:tags)
        call Message('No matches for "'.l:class.'" :(')
        return 0
    endif

    " Choose the tag we will use and make the FQCN string
    call ChooseTag(s:tags)
endfunction

"
" Choose the tag or open a window to let the user choose one.
"
function! ChooseTag(tags)
    " If there is only one tag then just use it
    if len(a:tags) == 1
        call SelectTag(0)
        return
    endif

    " Make the options and open a window to display them.
    let l:options = MakeOptionsList(a:tags)
    execute 'bo '.len(l:options).'new'

    " Write each option in a line an then move curstor to the top.
    call append(0, l:options)
    normal! ddgg0

    " Avoid the user modify the buffer contents.
    setlocal cursorline
    setlocal nomodifiable
    setlocal statusline=j/k\ =\ Up/down,\ <Enter>\ =\ Select,\ <Esc>\ =\ Cancel

    " Map common keys to select or close the options window.
    nnoremap <buffer> <esc> :q!<cr>:echo "Canceled"<cr>
    nnoremap <buffer> <cr> :call SelectTag(line('.') - 1)<cr>
endfunction

"
" Select the tag and insert the use statement.
"
function! SelectTag(index)
    let l:tag = s:tags[a:index]
    let l:fqcn = l:tag.namespace.'\'.l:tag.name

    if a:index > 0
        execute "normal! :q!\<cr>"
    endif

    if FqcnExists(l:fqcn) == 0
        call InsertUseStatement(l:fqcn)
    endif

    call Message('Class "'.l:fqcn.'" added.')
 endfunction

"
" Get a List of tags that matches de given pattern and are "class" kind.
"
function! SearchTags(pattern)
    let l:tags = []

    " Search tags and filter by type: class and trait
    for l:tag in taglist(a:pattern)
        if l:tag.kind == 'c' || l:tag.kind == 't'
            let l:tag.namespace = NormalizeNamespace(l:tag)
            call add(l:tags, l:tag)
        endif
    endfor

    return l:tags
endfunction

"
" Takes a List of tags and return a List of options to pass in inputlist()
"
function! MakeOptionsList(tags)
    let l:options = []

    for l:tag in a:tags
        call add(l:options, ' '.l:tag.namespace.'\'.l:tag.name)
    endfor

    return l:options
endfunction

"
" Remove the double backslashes from a namespace.
"
function! NormalizeNamespace(tag)
    let l:ns = a:tag.namespace

    if stridx(l:ns, '\\') > -1
        let l:ns = substitute(l:ns, '\\\\', '\\', 'g')
    endif

    return l:ns
endfunction

"
" Checks if the given fqcn is already in use.
"
function! FqcnExists(fqcn)
    " Escape the backslash, this is needed because we expect a normalized
    " fqcn which it don't have escaped backslashes.
    let l:escaped = substitute(a:fqcn, '\\', '\\\\', 'g')

    " Search for the use statement, for example: use App\\Class;
    return SearchInBuffer('^use '.l:escaped.';')
endfunction

"
" Returns true if the given pattern exists in the current buffer
"
function! SearchInBuffer(pattern)
    normal! mx
    let l:lineNumber = search(a:pattern)
    normal! `x
    return l:lineNumber > 0
endfunction

"
" Insert the "use" statement with the given namespace
"
function! InsertUseStatement(fqcn)

    let l:use = 'use ' . a:fqcn . ';'

    normal! mx

    " Try to insert after the last "use" statement.
    if search('^use .*;$', 'be') > 0
        call append(line('.'), l:use)

    " Try to insert after the "namespace" statement, leaving one blank line
    " before the "use" statement.
    elseif search('^namespace .*;$') > 0
        call append(line('.'), '')
        call append(line('.') + 1, l:use)

    " Try to insert after the "<?php" statement, leaving one blank line
    " before the "use" statement.
    elseif search('^<?php') > 0
        call append(line('.'), '')
        call append(line('.') + 1, l:use)

    " Insert at the top of the file
    else
        call append(1, l:use)
    endif

    normal! `x
endfunction

"
" Display a nice message
"
function! Message(message)
    redraw
    echo a:message
endfunction
