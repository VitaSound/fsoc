\ fsoc/futils/cross_lint.4th - cross-linter (port of tools/cross_lint.py)
\ Checks fsys/host/<id>-cross.4th against target kernel fsys/kernel/<id>.
\
\ Usage:
\   s" <cross.4th>" s" <kernel-dir>" cross-lint ( -- rc )
\   rc: 0 = no errors; 1 = errors found.
\
\ Python original tools/cross_lint.py preserved unchanged.
\ All strings use static buffers filled at top-level (no s" inside :def).
[IFUNDEF] cross-lint-loaded

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    \ ------------------------------------------------------------------
    \ Static strings bx-/ax- suffixes
    \ ------------------------------------------------------------------
    \ Суффиксы-имена cl-sfx-*: полный токен вида bx-xxx/ax-xxx
    \ опознаётся по концу токена (cl-endswith).
    create cl-s-bx      3 allot   s" bx-"    cl-s-bx     swap cmove     3 constant cl-l-s-bx
    create cl-s-ax      3 allot   s" ax-"    cl-s-ax     swap cmove     3 constant cl-l-s-ax
    create cl-s-hi      4 allot   s" -hi:"   cl-s-hi     swap cmove     4 constant cl-l-s-hi
    create cl-s-colon   1 allot   s" :"      cl-s-colon   swap cmove     1 constant cl-l-s-colon

    create cl-m-noerr   10 allot   s" No errors."       cl-m-noerr   swap cmove  10 constant cl-l-m-noerr
    create cl-m-errors   8 allot   s" ERRORS:"          cl-m-errors  swap cmove   8 constant cl-l-m-errors
    create cl-m-warns    9 allot   s" WARNINGS:"         cl-m-warns   swap cmove    9 constant cl-l-m-warns
    create cl-m-nowarn   11 allot   s" No warnings."     cl-m-nowarn  swap cmove   11 constant cl-l-m-nowarn
    \ Тексты сообщений дословно как в tools/cross_lint.py (allot = len строки).
    create cl-m-misscall 41 allot   s" Missing bx-call/ax-call in cross-compiler"
        cl-m-misscall swap cmove   41 constant cl-l-m-misscall
    create cl-m-misslit  39 allot   s" Missing bx-lit/ax-lit in cross-compiler"
        cl-m-misslit swap cmove    39 constant cl-l-m-misslit
    create cl-m-missret  39 allot   s" Missing bx-ret/ax-ret in cross-compiler"
        cl-m-missret swap cmove    39 constant cl-l-m-missret
    create cl-m-missone  45 allot   s" Missing bx-one/ax-one (main compilation loop)"
        cl-m-missone swap cmove    45 constant cl-l-m-missone
    create cl-m-missfind 45 allot   s" bx-find/ax-find not defined in cross-compiler"
        cl-m-missfind swap cmove   45 constant cl-l-m-missfind
    create cl-m-misscomma 31 allot   s" No bx-comma/ax-comma word found"
        cl-m-misscomma swap cmove  31 constant cl-l-m-misscomma
    create cl-m-missallot 31 allot   s" No bx-allot/ax-allot word found"
        cl-m-missallot swap cmove  31 constant cl-l-m-missallot
    create cl-m-missfrom 61 allot   s" Missing bx-from-image/ax-from-image (kernel word compilation)"
        cl-m-missfrom swap cmove   61 constant cl-l-m-missfrom
    create cl-m-missload 44 allot   s" Missing bx-load/ax-load (source file loader)"
        cl-m-missload swap cmove   44 constant cl-l-m-missload
    create cl-m-nocall   54 allot   s" No 'call' primitive found in kernel (expected for STC)"
        cl-m-nocall swap cmove     54 constant cl-l-m-nocall
    create cl-m-nolit    41 allot   s" No literal/klit primitive found in kernel"
        cl-m-nolit swap cmove      41 constant cl-l-m-nolit
    create cl-m-noret    37 allot   s" No exit/ret primitive found in kernel"
        cl-m-noret swap cmove      37 constant cl-l-m-noret
    create cl-m-nofind   27 allot   s" No find primitive in kernel"
        cl-m-nofind swap cmove     27 constant cl-l-m-nofind
    create cl-m-nocomma  28 allot   s" No comma primitive in kernel"
        cl-m-nocomma swap cmove    28 constant cl-l-m-nocomma
    create cl-m-noallot  28 allot   s" No allot primitive in kernel"
        cl-m-noallot swap cmove    28 constant cl-l-m-noallot

    create cl-s-dw   3 allot   s" dw,"    cl-s-dw   swap cmove   3 constant cl-l-s-dw
    create cl-s-db   3 allot   s" db,"    cl-s-db   swap cmove   3 constant cl-l-s-db
    create cl-s-fasm 9 allot   s" fasm-emit" cl-s-fasm swap cmove  9 constant cl-l-s-fasm
    create cl-s-dptr 6 allot   s" dptr#," cl-s-dptr swap cmove   6 constant cl-l-s-dptr
    create cl-s-movdptr 9 allot s" mov-dptr#" cl-s-movdptr swap cmove 9 constant cl-l-s-movdptr
    create cl-s-cell 6 allot   s" -cell!" cl-s-cell swap cmove   6 constant cl-l-s-cell
    create cl-s-addr 6 allot   s" -addr!" cl-s-addr swap cmove   6 constant cl-l-s-addr

    create cl-sfx-call  5 allot   s" -call"  cl-sfx-call swap cmove  5 constant cl-l-sfx-call
    create cl-sfx-lit   4 allot   s" -lit"   cl-sfx-lit swap cmove   4 constant cl-l-sfx-lit
    create cl-sfx-ret   4 allot   s" -ret"   cl-sfx-ret swap cmove   4 constant cl-l-sfx-ret
    create cl-sfx-exit  5 allot   s" -exit"  cl-sfx-exit swap cmove  5 constant cl-l-sfx-exit
    create cl-sfx-find  5 allot   s" -find"  cl-sfx-find swap cmove  5 constant cl-l-sfx-find
    create cl-sfx-comma 6 allot   s" -comma" cl-sfx-comma swap cmove  6 constant cl-l-sfx-comma
    create cl-sfx-allot 6 allot   s" -allot" cl-sfx-allot swap cmove  6 constant cl-l-sfx-allot
    create cl-sfx-one   4 allot   s" -one"   cl-sfx-one swap cmove    4 constant cl-l-sfx-one
    create cl-sfx-from  11 allot  s" -from-image" cl-sfx-from swap cmove 11 constant cl-l-sfx-from
    create cl-sfx-load  5 allot   s" -load"  cl-sfx-load swap cmove    5 constant cl-l-sfx-load

    create cl-s-kpath 12 allot
    11 constant cl-l-s-kpath
    s" /kernel.4th" cl-s-kpath swap cmove

    \ ------------------------------------------------------------------
    1   constant cl-b-call
    2   constant cl-b-lit
    4   constant cl-b-ret
    8   constant cl-b-one
    16  constant cl-b-find
    32  constant cl-b-comma
    64  constant cl-b-allot
    128 constant cl-b-from
    256 constant cl-b-load
    variable cl-found

    1   constant cl-p-call
    2   constant cl-p-lit
    4   constant cl-p-ret
    8   constant cl-p-exit
    16  constant cl-p-find
    32  constant cl-p-comma
    64  constant cl-p-allot
    variable cl-kprims

    variable cl-err-n variable cl-warn-n
    variable cl-emits-machine

    \ ------------------------------------------------------------------
    begin-structure cl-crossrec%
        field: cw-name
        field: cw-nlen
        field: cw-type
    end-structure
    variable cl-cross-n
    create cl-cross 64 cl-crossrec% * allot

    variable cl-ta variable cl-tu
    variable cl-ts
    variable cl-ci variable cl-cok
    variable cl-a variable cl-ua variable cl-b variable cl-vb
    variable cl-kernel-a variable cl-kernel-u
    variable cl-cross-a variable cl-cross-u

    create cl-file-buf 65536 allot
    variable cl-file-l

    create cl-cross-path 1024 allot
    create cl-kernel-path 1024 allot

    \ ------------------------------------------------------------------
    \ Читает файл по пути (a u) в cl-file-buf.
    \ Контракт ( a u -- count ior ): ior=0 успех, ior<>0 ошибка (что-то уже на стеке не бывает).
    : cl-readwhole ( a u -- count ior )
        r/o open-file if
            drop 0 cl-file-l ! 0 1 exit
        then >r
        cl-file-buf 65536 r@ read-file
        r> close-file drop        \ закрытие не должно ломать результат чтения
        if                        \ ior read-file <> 0 → ошибка
            drop 0 cl-file-l ! 0 1 exit
        then
        dup cl-file-l !
        0 ;

    : cl-str= ( a u b vb -- f )
        >r >r >r >r
        r> cl-a !
        r> cl-ua !
        r> cl-b !
        r> cl-vb !
        cl-ua @ cl-vb @ = if
            0 cl-ci ! 1 cl-cok !
            begin cl-cok @ 1 and cl-ci @ cl-ua @ u< and while
                cl-a @ cl-ci @ + c@ cl-b @ cl-ci @ + c@ <> if 0 cl-cok ! then
                1 cl-ci +!
            repeat
            cl-cok @
        else 0 then ;

    : cl-starts-with ( a u b vb -- f )
        >r >r >r >r
        r> cl-a !
        r> cl-ua !
        r> cl-b !
        r> cl-vb !
        cl-ua @ cl-vb @ < if 0 exit then
        0 cl-ci ! 1 cl-cok !
        begin cl-cok @ 1 and cl-ci @ cl-vb @ u< and while
            cl-a @ cl-ci @ + c@ cl-b @ cl-ci @ + c@ <> if 0 cl-cok ! then
            1 cl-ci +!
        repeat
        cl-cok @ ;

    : cl-endswith ( a u b vb -- f )
        >r >r >r >r
        r> cl-a !
        r> cl-ua !
        r> cl-b !
        r> cl-vb !
        cl-ua @ cl-vb @ < if 0 exit then
        0 cl-ci ! 1 cl-cok !
        begin cl-cok @ 1 and cl-ci @ cl-vb @ u< and while
            cl-a @ cl-ua @ cl-vb @ - + cl-ci @ + c@
            cl-b @ cl-ci @ + c@
            <> if 0 cl-cok ! then
            1 cl-ci +!
        repeat
        cl-cok @ ;

    \ ------------------------------------------------------------------
    variable cl-src variable cl-p variable cl-len

    : cl-is-ws ( c -- f )
        dup 32 = if drop 1 exit then
        dup 9 = if drop 1 exit then
        dup 13 = if drop 1 exit then
        10 = ;
    : cl-cpeek ( -- c )
        cl-p @ cl-src @ + c@ ;
    : cl-skip-ws ( -- )
        begin
            cl-p @ cl-len @ u< while
                cl-cpeek cl-is-ws if 1 cl-p +! else exit then
            repeat ;

    : read-token ( -- a u f )
        cl-skip-ws
        cl-p @ cl-len @ u< if
            cl-p @ cl-ts !
            begin
                cl-p @ cl-len @ u< while
                    cl-cpeek cl-is-ws if
                        cl-src @ cl-ts @ + cl-p @ cl-ts @ - 1
                        exit
                    then
                    1 cl-p +!
                repeat
                cl-src @ cl-ts @ + cl-p @ cl-ts @ - 1
            else
                0 0 0
            then ;

    : cl-next-token ( -- f )
        read-token
        >r swap >r
        cl-tu !
        r> cl-ta !
        r> ;

    variable cl-bit variable cl-sba variable cl-sbu
    \ ( suf-a suf-u bit ): суффикс сверяется с КОНЦОМ полного токена.
    : cl-try-suffix ( suf-a suf-u bit -- )
        >r >r >r r> cl-sba ! r> cl-sbu ! r> cl-bit !
        cl-tu @ cl-sbu @ < if exit then
        cl-ta @ cl-tu @ cl-sba @ cl-sbu @ cl-endswith if
            cl-bit @ cl-found @ or cl-found !
        then ;

    \ Вызывается с полным токеном вида bx-call / ax-from-image и т.п.
    : cl-note-token ( -- )
        cl-sfx-call  cl-l-sfx-call  cl-b-call  cl-try-suffix
        cl-sfx-lit   cl-l-sfx-lit   cl-b-lit   cl-try-suffix
        cl-sfx-ret   cl-l-sfx-ret   cl-b-ret   cl-try-suffix
        cl-sfx-exit  cl-l-sfx-exit  cl-b-ret   cl-try-suffix
        cl-sfx-one   cl-l-sfx-one   cl-b-one   cl-try-suffix
        cl-sfx-find  cl-l-sfx-find  cl-b-find  cl-try-suffix
        cl-sfx-comma cl-l-sfx-comma cl-b-comma cl-try-suffix
        cl-sfx-allot cl-l-sfx-allot cl-b-allot cl-try-suffix
        cl-sfx-from  cl-l-sfx-from  cl-b-from  cl-try-suffix
        cl-sfx-load  cl-l-sfx-load  cl-b-load  cl-try-suffix ;

    variable cl-wrec
    : cl-store-cross ( -- )
        cl-cross-n @ cl-crossrec% * cl-cross +
        cl-wrec !
        cl-ta @ cl-wrec @ cw-name !
        cl-tu @ cl-wrec @ cw-nlen !
        0 cl-wrec @ cw-type !
        1 cl-cross-n +! ;

    create cl-fname 64 allot
    variable cl-flen
    variable cl-ki
    : cl-find-cross ( a u -- idx|-1 )
        0 cl-ki !
        begin cl-ki @ cl-cross-n @ u< while
            cl-ki @ cl-crossrec% * cl-cross +
            dup cw-nlen @ cl-flen !
            cw-name @ cl-fname cl-flen @ cmove
            cl-fname cl-flen @ cl-ta @ cl-tu @ cl-str=
            if cl-ki @ exit then
            1 cl-ki +!
        repeat
        -1 ;

    \ Скан-токенайзер: ищет упоминания DW,/DB,/fasm-emit/dptr#,/mov-dptr#
    \ как отдельных токенов и суффиксы -cell!/-addr! у токенов.
    : cl-detect-machine ( -- )
        0 cl-emits-machine !
        cl-file-buf cl-src !
        cl-file-l @ cl-len !
        0 cl-p !
        begin
            cl-next-token 0= if exit then
            cl-ta @ cl-tu @ cl-s-dw cl-l-s-dw cl-str= if
                1 cl-emits-machine ! exit then
            cl-ta @ cl-tu @ cl-s-db cl-l-s-db cl-str= if
                1 cl-emits-machine ! exit then
            cl-ta @ cl-tu @ cl-s-fasm cl-l-s-fasm cl-str= if
                1 cl-emits-machine ! exit then
            cl-ta @ cl-tu @ cl-s-dptr cl-l-s-dptr cl-str= if
                1 cl-emits-machine ! exit then
            cl-ta @ cl-tu @ cl-s-movdptr cl-l-s-movdptr cl-str= if
                1 cl-emits-machine ! exit then
            cl-ta @ cl-tu @ cl-s-cell cl-l-s-cell cl-endswith if
                1 cl-emits-machine ! exit then
            cl-ta @ cl-tu @ cl-s-addr cl-l-s-addr cl-endswith if
                1 cl-emits-machine ! exit then
        again ;

    : cl-scan-cross-file ( -- )
        cl-file-buf cl-src !
        cl-file-l @ cl-len !
        0 cl-p !
        0 cl-found !
        begin
            cl-next-token 0= if exit then
            cl-ta @ cl-tu @ cl-s-colon cl-l-s-colon cl-str= if
                cl-next-token 0= if exit then
                cl-ta @ cl-tu @ cl-s-bx cl-l-s-bx cl-starts-with
                cl-ta @ cl-tu @ cl-s-ax cl-l-s-ax cl-starts-with or if
                    cl-note-token
                    cl-store-cross
                then
            then
            cl-ta @ cl-tu @ cl-s-hi cl-l-s-hi cl-endswith if
                cl-next-token 0= if exit then
            then
        again ;

    create cl-kpath 1024 allot

    : cl-mark-kprims ( -- )
        cl-ta @ cl-tu @ cl-sfx-call cl-l-sfx-call cl-endswith if
            cl-p-call cl-kprims @ or cl-kprims ! then
        cl-ta @ cl-tu @ cl-sfx-lit cl-l-sfx-lit cl-endswith if
            cl-p-lit cl-kprims @ or cl-kprims ! then
        cl-ta @ cl-tu @ cl-sfx-ret cl-l-sfx-ret cl-endswith if
            cl-p-ret cl-kprims @ or cl-kprims ! then
        cl-ta @ cl-tu @ cl-sfx-exit cl-l-sfx-exit cl-endswith if
            cl-p-exit cl-kprims @ or cl-kprims ! then
        cl-ta @ cl-tu @ cl-sfx-find cl-l-sfx-find cl-endswith if
            cl-p-find cl-kprims @ or cl-kprims ! then
        cl-ta @ cl-tu @ cl-sfx-comma cl-l-sfx-comma cl-endswith if
            cl-p-comma cl-kprims @ or cl-kprims ! then
        cl-ta @ cl-tu @ cl-sfx-allot cl-l-sfx-allot cl-endswith if
            cl-p-allot cl-kprims @ or cl-kprims ! then ;

    : cl-scan-kernel-file ( path-a path-u -- )
        cl-readwhole 2drop
        cl-file-buf cl-src ! cl-file-l @ cl-len ! 0 cl-p !
        0 cl-kprims !
        begin
            cl-next-token 0= if exit then
            cl-mark-kprims
        again ;

    : cl-err-missing ( a u -- ) ."   > " type cr ;

    : cl-check-call ( -- )
        cl-found @ cl-b-call and 0= if
            cl-m-misscall cl-l-m-misscall cl-err-missing
            1 cl-err-n +! exit then
        cl-emits-machine @ if exit then
        cl-kprims @ cl-p-call and 0= if
            cl-m-nocall cl-l-m-nocall cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-lit ( -- )
        cl-found @ cl-b-lit and 0= if
            cl-m-misslit cl-l-m-misslit cl-err-missing
            1 cl-err-n +! exit then
        cl-emits-machine @ if exit then
        cl-kprims @ cl-p-lit and 0= if
            cl-m-nolit cl-l-m-nolit cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-ret ( -- )
        cl-found @ cl-b-ret and 0= if
            cl-m-missret cl-l-m-missret cl-err-missing
            1 cl-err-n +! exit then
        cl-emits-machine @ if exit then
        cl-kprims @ cl-p-ret and 0= if
            cl-m-noret cl-l-m-noret cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-one ( -- )
        cl-found @ cl-b-one and 0= if
            cl-m-missone cl-l-m-missone cl-err-missing
            1 cl-err-n +! then ;
    : cl-check-find ( -- )
        cl-found @ cl-b-find and 0= if
            cl-m-missfind cl-l-m-missfind cl-err-missing
            1 cl-warn-n +! exit then
        cl-emits-machine @ if exit then
        cl-kprims @ cl-p-find and 0= if
            cl-m-nofind cl-l-m-nofind cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-comma ( -- )
        cl-emits-machine @ if exit then
        cl-found @ cl-b-comma and 0= if
            cl-m-misscomma cl-l-m-misscomma cl-err-missing
            1 cl-warn-n +! then
        cl-kprims @ cl-p-comma and 0= if
            cl-m-nocomma cl-l-m-nocomma cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-allot ( -- )
        cl-emits-machine @ if exit then
        cl-found @ cl-b-allot and 0= if
            cl-m-missallot cl-l-m-missallot cl-err-missing
            1 cl-warn-n +! then
        cl-kprims @ cl-p-allot and 0= if
            cl-m-noallot cl-l-m-noallot cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-from ( -- )
        cl-found @ cl-b-from and 0= if
            cl-m-missfrom cl-l-m-missfrom cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-load ( -- )
        cl-found @ cl-b-load and 0= if
            cl-m-missload cl-l-m-missload cl-err-missing
            1 cl-warn-n +! then ;

    \ Дивергенция с tools/cross_lint.py: проверка check_missing_kernel_primitives
    \ ("Cross word <bx-*> requires kernel primitive (<...>) but none found")
    \ здесь НЕ реализована — для каждого bx-слова она сверяет required-имена
    \ с точным множеством имён примитивов ядра. Предупреждения этой категории
    \ порт не выдаёт; ошибки (rc) и остальные предупреждения совпадают с
    \ эталоном (сверено на tests/futils/cross_lint_fixtures/*).

    : cross-lint ( cross-a cross-u kernel-a kernel-u -- rc )
        cl-kernel-u ! cl-kernel-a ! cl-cross-u ! cl-cross-a !
        cl-cross-a @ cl-cross-path cl-cross-u @ cmove
        cl-kernel-a @ cl-kernel-path cl-kernel-u @ cmove
        cl-s-kpath cl-kernel-path cl-kernel-u @ + cl-l-s-kpath cmove
        0 cl-found ! 0 cl-err-n ! 0 cl-warn-n !
        0 cl-cross-n ! 0 cl-kprims !
        cl-cross-path cl-cross-u @ cl-readwhole 2drop
        cl-detect-machine
        cl-scan-cross-file
        cl-kernel-path cl-kernel-u @ 11 + cl-scan-kernel-file
        cl-check-call cl-check-lit cl-check-ret
        cl-check-find cl-check-comma cl-check-allot
        cl-check-one cl-check-from cl-check-load
        cl-err-n @ 0= if
            cl-m-noerr cl-l-m-noerr type
        else
            cl-m-errors cl-l-m-errors type
        then cr
        cl-warn-n @ 0= if cl-m-nowarn cl-l-m-nowarn type
        else cl-m-warns cl-l-m-warns type then cr
        cl-err-n @ 0= if 0 else 1 then ;

    true constant cross-lint-loaded
[THEN]