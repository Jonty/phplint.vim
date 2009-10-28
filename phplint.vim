" Check we actually have PHP installed, otherwise you'll never be able to save
if exists("loadedPHPLint") || !executable('php')
    finish
endif

let loadedPHPLint = 1

autocmd BufWriteCmd * execute('call LintPHPFile()')

function LintPHPFile()
    if &filetype == 'php'
        let thisFile = expand("%")

        " If the file isn't writable don't do anything, as it'll freak vim out
        if filewritable(thisFile)
            let testFile = tempname()
            let bufferContents = getbufline(bufnr("%"), 1, "$")
            exe writefile(bufferContents, testFile)

            " Check the test file got written, this might fail if the disk is 
            " full and prevent you from saving. Which would be bad.
            if filereadable(testFile)
                let phpLint = system('php -l ' . testFile)
                let phpLint = substitute(phpLint, testFile, thisFile, "g")
                
                let errLine = matchstr(phpLint, 'No syntax errors')
                if strlen(errLine) > 0
                    cclose
                    redraw " Avoids the annoying 'Press ENTER to BLAH' message
                else
                    let lintLines = split(phpLint, "\n")
                    let lintLines = lintLines[0:-2] " The last line is garbage

                    let cFile = tempname()
                    exe writefile(lintLines, cFile)

                    set errorformat=%m\ in\ %f\ on\ line\ %l
                    exe "cfile " . cFile
                    copen 5

                    return
                endif
            endif

        endif
    endif

    " We have to handle the write op ourselves, as we overrode it
    noautocmd w
endf
