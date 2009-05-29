if exists("loadedPHPLint")
    finish
endif

let loadedPHPLint = 1

function LintFile()
    let thisFile = expand("%")
    let testFile = tempname()
    execute "noautocmd w " . testFile

    let phpLint = system("php -l " . testFile)

    let matchLine = matchstr(phpLint, 'No syntax errors')
    if strlen(matchLine) == 0
        echohl WarningMsg | echon "\nPHP Errors found, file not saved!\n"
        echohl None | echo phpLint
    else
        noautocmd w
    endif
endf

autocmd BufWriteCmd *.php execute('call LintFile()')
