" Check we actually have PHP installed, otherwise you'll never be able to save
if exists("loadedPHPLint") || !executable('php')
    finish
endif

let loadedPHPLint = 1

autocmd BufWriteCmd * execute('call LintPHPFile()')

function LintPHPFile()
    if &filetype == 'php'
        let b:thisFile = expand("%")
        let b:testFile = tempname()
        execute "noautocmd w " . b:testFile

        " Check the test file got written, this might fail if the disk is 
        " full and prevent you from saving. Which would be bad.
        if filereadable(b:testFile)
            let b:phpLint = system("php -l " . b:testFile)

            let b:matchLine = matchstr(b:phpLint, 'No syntax errors')
            if strlen(b:matchLine) == 0
                " Replace the temp file name in the output, so as not to confuse
                " people with the weird filenames
                let b:phpLint = substitute(b:phpLint, b:testFile, b:thisFile, "g")
                echohl WarningMsg | echon "\nPHP Errors found, file not saved! (Override by prepending :noa)\n"
                echohl None | echo b:phpLint
                return
            endif
        endif
    endif

    " We have to handle the write op ourselves, as we overrode it
    noautocmd w
endf
