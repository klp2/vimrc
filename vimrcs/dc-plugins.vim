"=====[ .t files are perl ]======================

autocmd BufNewFile,BufRead  *.t                     setfiletype perl


"=====[ Comments are important ]==================

highlight Comment term=bold ctermfg=white


"======[ Magically build interim directories if necessary ]===================

function! AskQuit (msg, options, quit_option)
    if confirm(a:msg, a:options) == a:quit_option
        exit
    endif
endfunction

function! EnsureDirExists ()
    let required_dir = expand("%:h")
    if !isdirectory(required_dir)
        call AskQuit("Parent directory '" . required_dir . "' doesn't exist.",
             \       "&Create it\nor &Quit?", 2)

        try
            call mkdir( required_dir, 'p' )
        catch
            call AskQuit("Can't create '" . required_dir . "'",
            \            "&Quit\nor &Continue anyway?", 1)
        endtry
    endif
endfunction

augroup AutoMkdir
    autocmd!
    autocmd  BufNewFile  *  :call EnsureDirExists()
augroup END


"=====[ Make arrow keys move visual blocks around ]======================

vmap <up>    <Plug>SchleppUp
vmap <down>  <Plug>SchleppDown
vmap <left>  <Plug>SchleppLeft
vmap <right> <Plug>SchleppRight

vmap D       <Plug>SchleppDupLeft
vmap <C-D>   <Plug>SchleppDupLeft


"=====[ Configure % key (via matchit plugin) for Perl 6 as well ]=============

" Match angle brackets...
"set matchpairs+=<:>,«:»


" =====[ Perl programming support ]===========================

"Adjust keyword characters to match Perlish identifiers...
set iskeyword+=$
set iskeyword+=%
set iskeyword+=@-@
set iskeyword+=:
set iskeyword-=,


" Insert common Perl code structures...

iab udd use Data::Dump 'ddx';<CR>ddx;<LEFT>
iab udv use Dumpvalue;<CR>Dumpvalue->new->dumpValues();<ESC>hi
iab uds use Data::Show;<CR>show
iab ubm use Benchmark qw( cmpthese );<CR><CR>cmpthese -10, {<CR>};<ESC>O
iab usc use Smart::Comments;<CR>###
iab uts use Test::Simple 'no_plan';
iab utm use Test::More 'no_plan';
iab dbs $DB::single = 1;<ESC>


"=====[ Run a Perl module's test suite ]=========================

let g:PerlTests_program       = 'perltests'   " ...What to call
let g:PerlTests_search_height = 5             " ...How far up to search
let g:PerlTests_test_dir      = '/t'          " ...Where to look for tests

augroup Perl_Tests
    autocmd!
    autocmd BufEnter *.p[lm]  nmap <buffer> ;t :call RunPerlTests()<CR>
    autocmd BufEnter *.t      nmap <buffer> ;t :call RunPerlTests()<CR>
augroup END

function! RunPerlTests ()
    " Start in the current directory...
    let dir = expand('%:h')

    " Walk up through parent directories, looking for a test directory...
    for n in range(g:PerlTests_search_height)
        " When found...
        if isdirectory(dir . g:PerlTests_test_dir)
            " Go there...
            silent exec 'cd ' . dir

            " Run the tests...
            exec ':!' . g:PerlTests_program

            " Return to the previous directory...
            silent cd -
            return
        endif

        " Otherwise, keep looking up the directory tree...
        let dir = dir . '/..'
    endfor

    " If not found, report the failure...
    echohl WarningMsg
    echomsg "Couldn't find a suitable" g:PerlTests_test_dir '(tried' g:PerlTests_search_height 'levels up)'
    echohl None
endfunction


"=====[ Auto-setup for Perl scripts and modules and test files ]===========

augroup Perl_Setup
    autocmd!
    autocmd BufNewFile   *.p[lm65],*.t   0r !perl_file_template <afile>
    autocmd BufNewFile   *.p[lm65],*.t   /^[ \t]*[#].*implementation[ \t]\+here/
augroup END


"=====[ Proper syntax highlighting for Rakudo files ]===========

autocmd BufNewFile,BufRead  *   :call CheckForPerl6()

function! CheckForPerl6 ()
    if getline(1) =~ 'rakudo'
        setfiletype perl6
    endif
    if expand('<afile>:e') == 'pod6'
        highlight Pod6Block_Heading1 cterm=bold,underline
        highlight Pod6FC_Important cterm=underline

        setfiletype pod6
        syntax enable
    endif
endfunction

" =====[ Smart completion via <TAB> and <S-TAB> ]=============

runtime plugin/smartcom.vim

" Add extra completions (mainly for Perl programming)...

let ANYTHING = ""
let NOTHING  = ""
let EOL      = '\s*$'

                " Left     Right      Insert                             Reset cursor
                " =====    =====      ===============================    ============
call SmartcomAdd( '<<',    ANYTHING,  '>>',                              {'restore':1} )
call SmartcomAdd( '<<',    '>>',      "\<CR>\<ESC>O\<TAB>"                             )
call SmartcomAdd( '?',     ANYTHING,  '?',                               {'restore':1} )
call SmartcomAdd( '?',     '?',       "\<CR>\<ESC>O\<TAB>"                             )
call SmartcomAdd( '{{',    ANYTHING,  '}}',                              {'restore':1} )
call SmartcomAdd( '{{',    '}}',      NOTHING,                                         )
call SmartcomAdd( 'qr{',   ANYTHING,  '}xms',                            {'restore':1} )
call SmartcomAdd( 'qr{',   '}xms',    "\<CR>\<C-D>\<ESC>O\<C-D>\<TAB>"                 )
call SmartcomAdd( 'm{',    ANYTHING,  '}xms',                            {'restore':1} )
call SmartcomAdd( 'm{',    '}xms',    "\<CR>\<C-D>\<ESC>O\<C-D>\<TAB>",                )
call SmartcomAdd( 's{',    ANYTHING,  '}{}xms',                          {'restore':1} )
call SmartcomAdd( 's{',    '}{}xms',  "\<CR>\<C-D>\<ESC>O\<C-D>\<TAB>",                )
call SmartcomAdd( '\*\*',  ANYTHING,  '**',                              {'restore':1} )
call SmartcomAdd( '\*\*',  '\*\*',    NOTHING,                                         )

" Handle single : correctly...
call SmartcomAdd( '^:\|[^:]:',  EOL,  "\<TAB>" )

"After an alignable, align...
function! AlignOnPat (pat)
    return "\<ESC>:call EQAS_Align('nmap',{'pattern':'" . a:pat . "'})\<CR>A"
endfunction
                " Left         Right        Insert
                " ==========   =====        =============================
call SmartcomAdd( '=',         ANYTHING,    "\<ESC>:call EQAS_Align('nmap')\<CR>A")
call SmartcomAdd( '=>',        ANYTHING,    AlignOnPat('=>') )
call SmartcomAdd( '\s#',       ANYTHING,    AlignOnPat('\%(\S\s*\)\@<= #') )
call SmartcomAdd( '[''"]\s*:', ANYTHING,    AlignOnPat(':'),                   {'filetype':'vim'} )
call SmartcomAdd( ':',         ANYTHING,    "\<TAB>",                          {'filetype':'vim'} )


" Perl keywords...
"
                " Left         Right   Insert                                  Where
                " ==========   =====   =============================           ===================
call SmartcomAdd( '^\s*for',   EOL,    " my $___ (___) {\n___\n}\n___",        {'filetype':'perl'} )
call SmartcomAdd( '^\s*if',    EOL,    " (___) {\n___\n}\n___",                {'filetype':'perl'} )
call SmartcomAdd( '^\s*while', EOL,    " (___) {\n___\n}\n___",                {'filetype':'perl'} )
call SmartcomAdd( '^\s*given', EOL,    " (___) {\n___\n}\n___",                {'filetype':'perl'} )
call SmartcomAdd( '^\s*when',  EOL,    " (___) {\n___\n}\n___",                {'filetype':'perl'} )


"=====[ Correct common mistypings in-the-fly ]=======================

iab        ,,  =>
iab    retrun  return
iab     pritn  print
iab       teh  the
iab      liek  like
iab  liekwise  likewise
iab      Pelr  Perl
iab      pelr  perl
iab        ;t  't
iab    Jarrko  Jarkko
iab    jarrko  jarkko
iab      moer  more
iab  previosu  previous



"=====[ Add or subtract comments ]===============================

" Work out what the comment character is, by filetype...
autocmd FileType             *sh,awk,python,perl,perl6,ruby    let b:cmt = exists('b:cmt') ? b:cmt : '#'
autocmd FileType             vim                               let b:cmt = exists('b:cmt') ? b:cmt : '"'
autocmd BufNewFile,BufRead   *.vim,.vimrc                      let b:cmt = exists('b:cmt') ? b:cmt : '"'
autocmd BufNewFile,BufRead   *                                 let b:cmt = exists('b:cmt') ? b:cmt : '#'
autocmd BufNewFile,BufRead   *.p[lm],.t                        let b:cmt = exists('b:cmt') ? b:cmt : '#'

" Work out whether the line has a comment then reverse that condition...
function! ToggleComment ()
    " What's the comment character???
    let comment_char = exists('b:cmt') ? b:cmt : '#'

    " Grab the line and work out whether it's commented...
    let currline = getline(".")

    " If so, remove it and rewrite the line...
    if currline =~ '^' . comment_char
        let repline = substitute(currline, '^' . comment_char, "", "")
        call setline(".", repline)

    " Otherwise, insert it...
    else
        let repline = substitute(currline, '^', comment_char, "")
        call setline(".", repline)
    endif
endfunction

" Toggle comments down an entire visual selection of lines...
function! ToggleBlock () range
    " What's the comment character???
    let comment_char = exists('b:cmt') ? b:cmt : '#'

    " Start at the first line...
    let linenum = a:firstline

    " Get all the lines, and decide their comment state by examining the first...
    let currline = getline(a:firstline, a:lastline)
    if currline[0] =~ '^' . comment_char
        " If the first line is commented, decomment all...
        for line in currline
            let repline = substitute(line, '^' . comment_char, "", "")
            call setline(linenum, repline)
            let linenum += 1
        endfor
    else
        " Otherwise, encomment all...
        for line in currline
            let repline = substitute(line, '^\('. comment_char . '\)\?', comment_char, "")
            call setline(linenum, repline)
            let linenum += 1
        endfor
    endif
endfunction

" Set up the relevant mappings
nmap <silent> # :call ToggleComment()<CR>j0
vmap <silent> # :call ToggleBlock()<CR>



"=====[ Search folding ]=====================

" Don't start new buffers folded
set foldlevelstart=99

" Highlight folds
highlight Folded  ctermfg=cyan ctermbg=black

" Toggle on and off...
nmap <silent> <expr>  zz  FS_ToggleFoldAroundSearch({'context':1})

" Show only sub defns (and maybe comments)...
let perl_sub_pat = '^\s*\%(sub\|func\|method\|package\)\s\+\k\+'
let vim_sub_pat  = '^\s*fu\%[nction!]\s\+\k\+'
augroup FoldSub
    autocmd!
    autocmd BufEnter * nmap <silent> <expr>  zp  FS_FoldAroundTarget(perl_sub_pat,{'context':1})
    autocmd BufEnter * nmap <silent> <expr>  za  FS_FoldAroundTarget(perl_sub_pat.'\zs\\|^\s*#.*',{'context':0, 'folds':'invisible'})
    autocmd BufEnter *.vim,.vimrc nmap <silent> <expr>  zp  FS_FoldAroundTarget(vim_sub_pat,{'context':1})
    autocmd BufEnter *.vim,.vimrc nmap <silent> <expr>  za  FS_FoldAroundTarget(vim_sub_pat.'\\|^\s*".*',{'context':0, 'folds':'invisible'})
    autocmd BufEnter * nmap <silent> <expr>             zv  FS_FoldAroundTarget(vim_sub_pat.'\\|^\s*".*',{'context':0, 'folds':'invisible'})
augroup END

" Show only C #includes...
nmap <silent> <expr>  zu  FS_FoldAroundTarget('^\s*use\s\+\S.*;',{'context':1})



"=====[ Much smarter "edit next file" command ]=======================

nmap <silent><expr>  e  g:GTF_goto_file()
nmap <silent><expr>  q  g:GTF_goto_file('`')



"=====[ Smarter interstitial completions of identifiers ]=============
"
" When autocompleting within an identifier, prevent duplications...

augroup Undouble_Completions
    autocmd!
    autocmd CompleteDone *  call Undouble_Completions()
augroup None

function! Undouble_Completions ()
    let col  = getpos('.')[2]
    let line = getline('.')
    call setline('.', substitute(line, '\(\k\+\)\%'.col.'c\zs\1', '', ''))
endfunction
