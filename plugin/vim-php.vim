" List of tags found
let s:tags = []

" Determine if the options window is open
let s:windowIsOpen = 0

" Action to do when a class is selected by the user, it can be:
" use = Insert the use statement
" expand_fqcn = Expand the FQCN
" expand_fqcn = Expand the FQCN with a leading backslash
let s:action = 'use'

" Define commands for PHP user
command! PHPImportClass call s:PHPImportClass('use')
command! PHPExpandFQCN call s:PHPImportClass('expand_fqcn')
command! PHPExpandFQCNAbsolute call s:PHPImportClass('expand_fqcn_absolute')

"
" Start the import process
"
function! s:PHPImportClass(action)
    let s:action = a:action
    let l:class = expand('<cword>')
    let s:tags = s:SearchTags(l:class)

    if empty(s:tags)
        call s:Message('Class, trait or interface "'.l:class.'" not found.')
        return
    endif

    if len(s:tags) == 1
        call s:SelectOption(0)
    else
        call s:DisplayOptions()
    endif
endfunction

"
" Open a window to display a list of FQCN of the found tags to let the user
" select an option or cancel.
"
function! s:DisplayOptions()

    " Make the options list.
    let l:options = s:MakeOptionsList()

    " Open a new window to display the options list.
    execute 'bo '.len(l:options).'new'
    let s:windowIsOpen = 1

    " Write each option in a line an then move cursor to the top.
    call append(0, l:options)
    normal! ddgg0

    " Avoid the user modify the buffer contents.
    setlocal cursorline
    setlocal nomodifiable
    setlocal statusline=Select\ a\ Class\ or\ Trait

    " This buffer command will be called when user select an option.
    command! -buffer PHPSelectOption call s:SelectOption(line('.') - 1)

    " Map common keys to select or close the options window.
    nnoremap <buffer> <esc> :q!<cr>:echo "Canceled"<cr>
    nnoremap <buffer> <cr> :PHPSelectOption<cr>
endfunction

"
" Select and option from the found tags and apply the requested action
" (s:action)
"
function! s:SelectOption(index)
    let l:tag = s:tags[a:index]
    let l:fqcn = l:tag.namespace.'\'.l:tag.name

    " Close the window if it's open
    if s:windowIsOpen
        execute "normal! :q!\<cr>"
        let s:windowIsOpen = 0
    endif

    if s:FqcnExists(l:fqcn)
        call s:Message('"'.l:fqcn.'" already in use.')
    else
        call s:InsertUseStatement(l:fqcn)
        call s:Message('"'.l:fqcn.'" imported.')
    endif

 endfunction

"
" Search for classes or traits using the given pattern
"
function! s:SearchTags(class)
    let l:tags = []

    " Search tags and filter by type: class, trait or interface
    for l:tag in taglist('^'.a:class.'$')

        " Not all tags have a namespace, those will be considered as root
        " classes.
        if has_key(l:tag, 'namespace') == 0
            let l:tag.namespace = ''
        endif

        if l:tag.kind == 'c' || l:tag.kind == 't' || l:tag.kind == 'i'
            let l:tag.namespace = s:NormalizeNamespace(l:tag)
            call add(l:tags, l:tag)
        endif
    endfor

    return l:tags
endfunction

"
" Takes a List of tags and return a List of options to pass in inputlist()
"
function! s:MakeOptionsList()
    let l:options = []

    for l:tag in s:tags
        let l:type = (l:tag.kind == 'c') ? 'Class' : 'Trait'
        call add(l:options, ' '.l:tag.namespace.'\'.l:tag.name.' ('.l:type.')')
    endfor

    return l:options
endfunction

"
" Remove the double backslashes from a namespace.
"
function! s:NormalizeNamespace(tag)
    let l:ns = a:tag.namespace

    if stridx(l:ns, '\\') > -1
        let l:ns = substitute(l:ns, '\\\\', '\\', 'g')
    endif

    return l:ns
endfunction

"
" Checks if the given fqcn is already in use.
"
function! s:FqcnExists(fqcn)
    " Escape the backslash, this is needed because we expect a normalized
    " fqcn which it don't have escaped backslashes.
    let l:escaped = substitute(a:fqcn, '\\', '\\\\', 'g')

    " Search for the use statement, for example: use App\\Class;
    return s:SearchInBuffer('^use '.l:escaped.';')
endfunction

"
" Returns true if the given pattern exists in the current buffer
"
function! s:SearchInBuffer(pattern)
    normal! mx
    let l:lineNumber = search(a:pattern)
    normal! `x
    return l:lineNumber > 0
endfunction

"
" Insert the "use" statement with the given namespace
"
function! s:InsertUseStatement(fqcn)

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
function! s:Message(message)
    redraw
    echo a:message
endfunction
