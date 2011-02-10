" Check we actually have PHP installed, otherwise you'll never be able to save
if !exists("loadedPHPLint") && executable('php')
    let loadedPHPLint = 1
else
    finish
endif


" To disable auto-lint, add "let noAutoLint = 1" to your .vimrc
if !exists("noAutoLint")
    autocmd BufWriteCmd *.php execute('call AutoLintPHPFile()')
endif

function AutoLintPHPFile()
    if LintPHPFile()
        " We have to handle the write op ourselves, as we overrode it
        noautocmd w
    endif
endf


" Allow manual linting with :Phplint
command! PHPLint call LintPHPFile()

function LintPHPFile()
    if &filetype != 'php'
        return 1
    endif

    let thisFile = expand("%")

    " If the file isn't writable don't do anything, as it'll freak vim out
    if filewritable(thisFile)
        let testFile = tempname()

        " This resets the view to the top, so we need to restore it
        let view = winsaveview()
        let bufferContents = getbufline(bufnr("%"), 1, "$")
        exe writefile(bufferContents, testFile)
        call winrestview(view)

        " Check the test file got written, this might fail if the disk is 
        " full and prevent you from saving. Which would be bad.
        if filereadable(testFile)
            let phpLint = system('php -l ' . testFile)
            let phpLint = substitute(phpLint, testFile, thisFile, "g")
            call delete(testFile)

            let errLine = matchstr(phpLint, 'No syntax errors')
            if strlen(errLine) > 0
                cclose
                redraw " Avoids the annoying 'Press ENTER to BLAH' message
                return 1

            else
                let lintLines = split(phpLint, "\n")

                let errorLines = []
                for line in lintLines
                    let pos = matchstr(line, 'on line')
                    if strlen(pos) > 0
                        call add(errorLines, line)
                    endif
                endfor

                let cFile = tempname()
                exe writefile(errorLines, cFile)

                let oldCpoptions = &cpoptions
                let oldErrorformat = &errorformat

                set cpoptions-=F
                set errorformat=%m\ in\ %f\ on\ line\ %l

                exe "cfile " . cFile
                copen 5
                call delete(cFile)

                let &cpoptions = oldCpoptions
                let &errorformat = oldErrorformat

                return 0

            endif
        endif
    endif

    return 1
endf
