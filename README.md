# vim-php
An **intuitive** plugin to import/expand classes, traits and interfaces, finally!

## 2018-10-07: This repository still active, feel free to open issues or send pull request

![Preview](https://sahib.io/vim-php-namespace-sm.gif)

## Install
Install using your favorite plugin manager, like Vundle:
```vim
Plugin 'sahibalejandro/vim-php'
```

## CTags
You need **Universal Ctags** to generate CTags for classes, traits and interfaces.
Here you can find it: https://github.com/universal-ctags/ctags

Once you have installed **Universal Ctags** just run this command:
```
ctags --recurse --languages=php --php-kinds=ctif
```

You need at least the following kinds: `cti`, which corresponds to `class`,
`trait` and `interface`.

## Commands

### PHPImportClass
This command will add the `use Foo\Bar` statement for the class/trait/interface under cursor.

### PHPExpandFQCN
This command will expand the FQCN for the class/trait/interface under cursor.

### PHPExpandFQCNAbsolute
This command will expand the FQCN with a leading backslash for the class/trait/interface under
cursor.

## Configuration

Just add this to your `.vimrc` file:
```vim
augroup VIM_PHP
    autocmd!
    autocmd FileType php nnoremap <Leader>u :PHPImportClass<cr>
    autocmd FileType php nnoremap <Leader>e :PHPExpandFQCNAbsolute<cr>
    autocmd FileType php nnoremap <Leader>E :PHPExpandFQCN<cr>
augroup END
```
Change the mappings to your needs.
