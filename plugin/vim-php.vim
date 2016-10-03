function! PhpNamespace()

    let l:class = expand('<cword>')
    let l:tags = SearchTags('^'.l:class.'$')

    " If no tags found then we can't do nothing.
    if empty(l:tags)
        call Message('No matches for "'.l:class.'" :(')
        return 0
    endif

    " Choose the tag we will use and make the FQCN string
    let l:tag = ChooseTag(l:tags)
    let l:fqcn = l:tag.namespace.'\'.l:tag.name

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
" Get the specified tag to use from a List of tags.
"
function! ChooseTag(tags)

    " If there is only one tag then just return it
    if len(a:tags) == 1
        return a:tags[0]
    endif

    " Display an input list witha all available tags to let the user select one.
    let l:index = inputlist(MakeOptionsList(a:tags)) - 1

    return a:tags[l:index]
endfunction

"
" Takes a List of tags and return a List of options to pass in inputlist()
"
function! MakeOptionsList(tags)
    let l:options = []
    let l:number = 1

    for l:tag in a:tags
        call add(l:options, l:number.' => '.l:tag.namespace.'\'.l:tag.name)
        let l:number = l:number + 1
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
