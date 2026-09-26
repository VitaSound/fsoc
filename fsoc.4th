\ fsoc.4th — CLI. Run from the project directory: fsoc --build / --load / --clean.
\ The manifest target.4th names the task, target, board, design and
\ options. The registry supplies the words; this file knows no task.

create fsoc-lib-buf 1024 allot
variable fsoc-lib-u

\ Library path is FSOC_HOME/fsoc/load.4th.
: fsoc-include-lib ( - )
    s" FSOC_HOME" getenv
    dup 0= IF true abort" FSOC_HOME unset" THEN
    dup 900 > IF true abort" FSOC_HOME too long" THEN
    dup fsoc-lib-u !
    fsoc-lib-buf swap cmove
    s" /fsoc/load.4th"
    dup >r
    fsoc-lib-buf fsoc-lib-u @ + swap cmove
    r> fsoc-lib-u @ +
    fsoc-lib-buf swap included ;

fsoc-include-lib

2VARIABLE pkg-version
s" 0.5.0" pkg-version 2!

: fsoc.help
    cr s" fsoc v" type pkg-version 2@ type cr
    s"   version" type cr
    s"   help" type cr
    s"   --build         emit, then run the target (emulation until Ctrl+C)" type cr
    s"   --load          program the board (ignored on emulation)" type cr
    s"   --build --load  emit, then program" type cr
    s"   --clean         delete build output; keep target.4th" type cr
    s" Run from the project directory (projects/<task>_<target>)." type cr ;

: fsoc.version
    cr s" fsoc v" type pkg-version 2@ type cr ;

create fsoc-arg-buf 256 allot
variable fsoc-arg-u
variable fsoc-build?
variable fsoc-load?
variable fsoc-clean?
variable fsoc-help?
variable fsoc-version?

\ next-arg's buffer is overwritten by the next call. Keep a private copy.
: fsoc-take-arg ( c-addr u - )
    dup 255 > IF true abort" argument too long" THEN
    dup fsoc-arg-u !
    fsoc-arg-buf swap move
    fsoc-arg-buf fsoc-arg-u @ s" --build" compare 0= IF 1 fsoc-build? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" --load" compare 0= IF 1 fsoc-load? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" --clean" compare 0= IF 1 fsoc-clean? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" --help" compare 0= IF 1 fsoc-help? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" help" compare 0= IF 1 fsoc-help? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" version" compare 0= IF 1 fsoc-version? ! EXIT THEN
    true abort" unknown argument" ;

: fsoc-read-args ( - )
    0 fsoc-build? !  0 fsoc-load? !  0 fsoc-clean? !
    0 fsoc-help? !  0 fsoc-version? !
    begin
        next-arg dup
    while
        fsoc-take-arg
    repeat
    2drop ;

: fsoc-dispatch ( - )
    fsoc-read-args
    fsoc-version? @ IF fsoc.version EXIT THEN
    fsoc-help? @ IF fsoc.help EXIT THEN
    fsoc-build? @ 0= fsoc-load? @ 0= and fsoc-clean? @ 0= and IF fsoc.help EXIT THEN
    fsoc-clean? @ IF fsoc-clean THEN
    fsoc-build? @ 0= fsoc-load? @ 0= and IF EXIT THEN
    fsoc-read-manifest
    fsoc-build? @ IF dup fsoc-build THEN
    fsoc-load? @ IF dup fsoc-load THEN
    drop ;

fsoc-dispatch
0 bye
