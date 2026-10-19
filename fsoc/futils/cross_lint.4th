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
    create cl-s-call    4 allot   s" call"    cl-s-call    swap cmove   4 constant cl-l-s-call
    create cl-s-lit     3 allot   s" lit"    cl-s-lit     swap cmove    3 constant cl-l-s-lit
    create cl-s-ret     3 allot   s" ret"    cl-s-ret     swap cmove    3 constant cl-l-s-ret
    create cl-s-one     3 allot   s" one"    cl-s-one     swap cmove    3 constant cl-l-s-one
    create cl-s-find    4 allot   s" find"   cl-s-find    swap cmove    4 constant cl-l-s-find
    create cl-s-comma   5 allot   s" comma"  cl-s-comma   swap cmove    5 constant cl-l-s-comma
    create cl-s-allot   5 allot   s" allot"  cl-s-allot   swap cmove    5 constant cl-l-s-allot
    create cl-s-from   10 allot   s" from-image" cl-s-from swap cmove  10 constant cl-l-s-from
    create cl-s-load    4 allot   s" load"   cl-s-load    swap cmove    4 constant cl-l-s-load
    create cl-s-exec    7 allot   s" execute" cl-s-exec   swap cmove    7 constant cl-l-s-exec

    create cl-s-bx      3 allot   s" bx-"    cl-s-bx     swap cmove     3 constant cl-l-s-bx
    create cl-s-ax      3 allot   s" ax-"    cl-s-ax     swap cmove     3 constant cl-l-s-ax
    create cl-s-hi      4 allot   s" -hi:"   cl-s-hi     swap cmove     4 constant cl-l-s-hi
    create cl-s-colon   1 allot   s" :"      cl-s-colon   swap cmove     1 constant cl-l-s-colon

    create cl-m-noerr   10 allot   s" No errors."       cl-m-noerr   swap cmove  10 constant cl-l-m-noerr
    create cl-m-errors   8 allot   s" ERRORS:"          cl-m-errors  swap cmove   8 constant cl-l-m-errors
    create cl-m-warns    9 allot   s" WARNINGS:"         cl-m-warns   swap cmove    9 constant cl-l-m-warns
    create cl-m-nowarn   11 allot   s" No warnings."     cl-m-nowarn  swap cmove   11 constant cl-l-m-nowarn
    create cl-m-misscall 27 allot   s" Missing bx-call/ax-call"        cl-m-misscall  swap cmove 27 constant cl-l-m-misscall
    create cl-m-misslit  24 allot   s" Missing bx-lit/ax-lit"           cl-m-misslit  swap cmove 24 constant cl-l-m-misslit
    create cl-m-missret  25 allot   s" Missing bx-ret/ax-ret"           cl-m-missret  swap cmove 25 constant cl-l-m-missret
    create cl-m-missone  25 allot   s" Missing bx-one/ax-one"           cl-m-missone  swap cmove 25 constant cl-l-m-missone
    create cl-m-missfind 28 allot   s" Missing bx-find/ax-find"         cl-m-missfind swap cmove 28 constant cl-l-m-missfind
    create cl-m-misscomma 31 allot   s" No bx-comma/ax-comma"           cl-m-misscomma swap cmove 31 constant cl-l-m-misscomma
    create cl-m-missallot 32 allot   s" No bx-allot/ax-allot"           cl-m-missallot swap cmove 32 constant cl-l-m-missallot
    create cl-m-missfrom 32 allot   s" Missing bx-from-image/ax-from-image" cl-m-missfrom swap cmove 32 constant cl-l-m-missfrom
    create cl-m-missload 28 allot   s" Missing bx-load/ax-load"          cl-m-missload swap cmove 28 constant cl-l-m-missload
    create cl-m-missexec 32 allot   s" Missing bx-execute/ax-execute"   cl-m-missexec swap cmove 32 constant cl-l-m-missexec
    create cl-m-nocall   20 allot   s" No k-call/jb-call primitive"     cl-m-nocall   swap cmove 20 constant cl-l-m-nocall
    create cl-m-nolit    17 allot   s" No k-lit/jb-lit primitive"       cl-m-nolit    swap cmove 17 constant cl-l-m-nolit
    create cl-m-noret    19 allot   s" No k-exit/jb-exit primitive"     cl-m-noret    swap cmove 19 constant cl-l-m-noret

    create cl-s-dw   3 allot   s" dw,"    cl-s-dw   swap cmove   3 constant cl-l-s-dw
    create cl-s-db   3 allot   s" db,"    cl-s-db   swap cmove   3 constant cl-l-s-db
    create cl-s-fasm 9 allot   s" fasm-emit" cl-s-fasm swap cmove  9 constant cl-l-s-fasm

    create cl-sfx-call  5 allot   s" -call"  cl-sfx-call swap cmove  5 constant cl-l-sfx-call
    create cl-sfx-lit   4 allot   s" -lit"   cl-sfx-lit swap cmove   4 constant cl-l-sfx-lit
    create cl-sfx-ret   4 allot   s" -ret"   cl-sfx-ret swap cmove   4 constant cl-l-sfx-ret
    create cl-sfx-exit  5 allot   s" -exit"  cl-sfx-exit swap cmove  5 constant cl-l-sfx-exit
    create cl-sfx-find  5 allot   s" -find"  cl-sfx-find swap cmove  5 constant cl-l-sfx-find
    create cl-sfx-comma 6 allot   s" -comma" cl-sfx-comma swap cmove  6 constant cl-l-sfx-comma
    create cl-sfx-allot 6 allot   s" -allot" cl-sfx-allot swap cmove  6 constant cl-l-sfx-allot

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
    512 constant cl-b-exec
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
    : cl-readwhole ( a u -- count )
        r/o open-file throw >r
        cl-file-buf 65536 r@ read-file
        drop
        dup cl-file-l !
        r> close-file throw
        ;

    : cl-str= ( a u b vb -- f )
        >r >r >r >r
        r> cl-vb !
        r> cl-b !
        r> cl-ua !
        r> cl-a !
        cl-ua @ cl-vb @ = if
            0 cl-ci ! 1 cl-cok !
            begin cl-cok @ 1 and cl-ci @ cl-ua @ u< and while
                cl-a @ cl-ci @ + c@ cl-b @ cl-ci @ + c@ =
                if 1 else 0 cl-cok ! then
                1 cl-ci +!
            repeat
            cl-cok @
        else 0 then ;

    : cl-starts-with ( a u b vb -- f )
        >r >r >r >r
        r> cl-vb !
        r> cl-b !
        r> cl-ua !
        r> cl-a !
        cl-ua @ cl-vb @ < if 0 exit then
        0 cl-ci ! 1 cl-cok !
        begin cl-cok @ 1 and cl-ci @ cl-vb @ u< and while
            cl-a @ cl-ci @ + c@ cl-b @ cl-ci @ + c@ =
            if 1 else 0 cl-cok ! then
            1 cl-ci +!
        repeat
        cl-cok @ ;

    : cl-endswith ( a u b vb -- f )
        >r >r >r >r
        r> cl-vb !
        r> cl-b !
        r> cl-ua !
        r> cl-a !
        cl-ua @ cl-vb @ < if 0 exit then
        0 cl-ci ! 1 cl-cok !
        begin cl-cok @ 1 and cl-ci @ cl-vb @ u< and while
            cl-a @ cl-ua @ cl-vb @ - cl-ci @ + c@
            cl-b @ cl-ci @ + c@
            = if 1 else 0 cl-cok ! then
            1 cl-ci +!
        repeat
        cl-cok @ ;

    \ ------------------------------------------------------------------
    variable cl-src variable cl-p variable cl-len
    variable cl-tok-f variable cl-tok-a variable cl-tok-u

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
    : cl-try-suffix ( suf-a suf-u bit -- )
        >r >r >r r> cl-bit ! r> cl-sbu ! r> cl-sba !
        cl-tok-u @ cl-sbu @ < if exit then
        cl-tok-a @ cl-tok-u @ cl-sba @ cl-sbu @ cl-starts-with if
            cl-bit cl-found @ or cl-found !
        then ;

    : cl-note-token ( -- )
        cl-s-call cl-l-s-call cl-b-call cl-try-suffix
        cl-s-lit  cl-l-s-lit  cl-b-lit  cl-try-suffix
        cl-s-ret  cl-l-s-ret  cl-b-ret  cl-try-suffix
        cl-s-one  cl-l-s-one  cl-b-one  cl-try-suffix
        cl-s-find cl-l-s-find cl-b-find  cl-try-suffix
        cl-s-comma cl-l-s-comma cl-b-comma cl-try-suffix
        cl-s-allot cl-l-s-allot cl-b-allot cl-try-suffix
        cl-s-from cl-l-s-from cl-b-from cl-try-suffix
        cl-s-load cl-l-s-load cl-b-load cl-try-suffix
        cl-s-exec cl-l-s-exec cl-b-exec cl-try-suffix ;

    variable cl-wrec
    : cl-store-cross ( -- )
        cl-cross-n @ cl-crossrec% * cl-cross +
        cl-wrec !
        cl-wrec @ dup cw-name + cl-ta rot drop !
        cl-wrec @ dup cw-nlen + cl-tu rot drop !
        cl-wrec @ dup cw-type + 0 rot drop !
        1 cl-cross-n +! ;

    create cl-fname 64 allot
    variable cl-flen
    variable cl-ki
    : cl-find-cross ( a u -- idx|-1 )
        0 cl-ki !
        begin cl-ki @ cl-cross-n @ u< while
            cl-ki @ cl-crossrec% * cl-cross +
            dup cw-name @ cw-nlen @
            cl-fname swap cmove
            cl-flen ! drop
            cl-fname cl-flen @ cl-ta @ cl-tu @ cl-str=
            if cl-ki @ exit then
            1 cl-ki +!
        repeat
        -1 ;

    : cl-detect-machine ( -- )
        0 cl-emits-machine !
        cl-file-buf cl-file-l @ cl-s-dw cl-l-s-dw cl-endswith if
            1 cl-emits-machine ! exit then
        cl-file-buf cl-file-l @ cl-s-db cl-l-s-db cl-endswith if
            1 cl-emits-machine ! exit then
        cl-file-buf cl-file-l @ cl-s-fasm cl-l-s-fasm cl-endswith if
            1 cl-emits-machine ! exit then ;

    : cl-scan-cross-file ( -- )
        cl-file-buf cl-src !
        cl-file-l @ cl-len !
        0 cl-p !
        0 cl-found !
        begin
            cl-next-token cl-tok-f @ 0= if exit then
            cl-ta @ cl-tu @ cl-s-colon cl-l-s-colon cl-str= if
                cl-next-token cl-tok-f @ 0= if exit then
                cl-ta @ cl-tu @ cl-s-bx cl-l-s-bx cl-starts-with if
                    cl-ta @ cl-tu @ 3 /string
                    >r cl-ta ! r> cl-tu !
                    cl-note-token
                    cl-store-cross
                else
                    cl-ta @ cl-tu @ cl-s-ax cl-l-s-ax cl-starts-with if
                        cl-ta @ cl-tu @ 3 /string
                        >r cl-ta ! r> cl-tu !
                        cl-note-token
                    then
                then
            then
            cl-ta @ cl-tu @ cl-s-hi cl-l-s-hi cl-endswith if
                cl-next-token cl-tok-f @ 0= if exit then
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
        cl-readwhole drop
        cl-file-buf cl-src ! cl-file-l @ cl-len ! 0 cl-p !
        0 cl-kprims !
        begin
            cl-next-token cl-tok-f @ 0= if exit then
            cl-mark-kprims
        again ;

    : cl-err-missing ( a u -- ) ."   > " type cr ;

    : cl-check-call ( -- )
        cl-found @ cl-b-call and 0= if
            cl-m-misscall cl-l-m-misscall cl-err-missing
            1 cl-err-n +! then
        cl-emits-machine @ if exit then
        cl-kprims @ cl-p-call and 0= if
            cl-m-nocall cl-l-m-nocall cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-lit ( -- )
        cl-found @ cl-b-lit and 0= if
            cl-m-misslit cl-l-m-misslit cl-err-missing
            1 cl-err-n +! then
        cl-emits-machine @ if exit then
        cl-kprims @ cl-p-lit and 0= if
            cl-m-nolit cl-l-m-nolit cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-ret ( -- )
        cl-found @ cl-b-ret and 0= if
            cl-m-missret cl-l-m-missret cl-err-missing
            1 cl-err-n +! then
        cl-emits-machine @ if exit then
        cl-kprims @ cl-p-ret and 0= if
            cl-m-noret cl-l-m-noret cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-one ( -- )
        cl-found @ cl-b-one and 0= if
            cl-m-missone cl-l-m-missone cl-err-missing
            1 cl-err-n +! then ;
    : cl-check-find ( -- )
        cl-emits-machine @ if exit then
        cl-found @ cl-b-find and 0= if
            cl-m-missfind cl-l-m-missfind cl-err-missing
            1 cl-err-n +! then
        cl-kprims @ cl-p-find and 0= if
            cl-m-missfind cl-l-m-missfind cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-comma ( -- )
        cl-emits-machine @ if exit then
        cl-found @ cl-b-comma and 0= if
            cl-m-misscomma cl-l-m-misscomma cl-err-missing
            1 cl-err-n +! then
        cl-kprims @ cl-p-comma and 0= if
            cl-m-misscomma cl-l-m-misscomma cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-allot ( -- )
        cl-emits-machine @ if exit then
        cl-found @ cl-b-allot and 0= if
            cl-m-missallot cl-l-m-missallot cl-err-missing
            1 cl-err-n +! then
        cl-kprims @ cl-p-allot and 0= if
            cl-m-missallot cl-l-m-missallot cl-err-missing
            1 cl-warn-n +! then ;
    : cl-check-from ( -- )
        cl-emits-machine @ if exit then
        cl-found @ cl-b-from and 0= if
            cl-m-missfrom cl-l-m-missfrom cl-err-missing
            1 cl-err-n +! then ;
    : cl-check-load ( -- )
        cl-emits-machine @ if exit then
        cl-found @ cl-b-load and 0= if
            cl-m-missload cl-l-m-missload cl-err-missing
            1 cl-err-n +! then ;
    : cl-check-exec ( -- )
        cl-emits-machine @ if exit then
        cl-found @ cl-b-exec and 0= if
            cl-m-missexec cl-l-m-missexec cl-err-missing
            1 cl-err-n +! then ;

    : cross-lint ( cross-a cross-u kernel-a kernel-u -- rc )
        cl-cross-a swap ! cl-cross-u swap !
        cl-kernel-a swap ! cl-kernel-u swap !
        cl-cross-path 1024 cl-cross-a @ cl-cross-u @ cmove
        cl-cross-path cl-cross-u @ +
        cl-kernel-path 1024 cl-kernel-a @ cl-kernel-u @ cmove
        cl-kernel-path cl-kernel-u @ +
        cl-kernel-path over + cl-s-kpath cl-l-s-kpath swap cmove
        cl-kernel-path cl-kernel-u @ 11 +
        0 cl-found ! 0 cl-err-n ! 0 cl-warn-n !
        0 cl-cross-n ! 0 cl-kprims !
        cl-cross-path cl-cross-u @ cl-readwhole drop
        cl-detect-machine
        cl-scan-cross-file
        cl-kernel-path cl-kernel-u @ 11 + cl-scan-kernel-file
        cl-check-call cl-check-lit cl-check-ret cl-check-one
        cl-emits-machine @ 0= if
            cl-check-find cl-check-comma cl-check-allot
            cl-check-from cl-check-load cl-check-exec
        then
        cl-err-n @ dup 0= if
            drop cl-m-noerr cl-l-m-noerr type
        else
            cl-m-errors cl-l-m-errors type
        then cr
        cl-warn-n @ 0= if cl-m-nowarn cl-l-m-nowarn type
        else cl-m-warns cl-l-m-warns type then cr
        cl-err-n @ 0= if 0 else 1 then ;

    true constant cross-lint-loaded
[THEN]