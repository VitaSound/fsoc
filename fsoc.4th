\ fsoc.4th — CLI. Run from the project directory: fsoc --build / --load.

create fsoc-lib-buf 1024 allot
variable fsoc-lib-u

\ Library path is FSOC_HOME/fsoc/load.4th. Offset is the measured prefix length.
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
s" 0.1.1" pkg-version 2!

create fsoc-task-buf 64 allot
variable fsoc-task-u
create fsoc-target-buf 64 allot
variable fsoc-target-u

\ Copy now. The next s" in target.4th reuses the transient string.
: fsoc-task! ( c-addr u - )
    dup 63 > IF true abort" task name too long" THEN
    dup fsoc-task-u !
    dup 0= IF 2drop EXIT THEN
    fsoc-task-buf swap move ;

: fsoc-target! ( c-addr u - )
    dup 63 > IF true abort" target name too long" THEN
    dup fsoc-target-u !
    dup 0= IF 2drop EXIT THEN
    fsoc-target-buf swap move ;

: fsoc-board! ( c-addr u - ) blinky-board! ;

\ Path of the fhdlgen design for this project. That file is the chip composition.
: fsoc-design! ( c-addr u - )
    dup 255 > IF true abort" design path too long" THEN
    dup fsoc-design-u !
    dup 0= IF 2drop EXIT THEN
    fsoc-design-buf swap move ;

: fsoc.help
    cr s" fsoc v" type pkg-version 2@ type cr
    s"   version" type cr
    s"   help" type cr
    s"   --build         emit, then run emulation until Ctrl+C" type cr
    s"   --load          program the board (ignored on emulation)" type cr
    s"   --build --load  emit, then program" type cr
    s" Run from the project directory (projects/<task>_<target>)." type cr ;

: fsoc.version
    cr s" fsoc v" type pkg-version 2@ type cr ;

create fsoc-arg-buf 256 allot
variable fsoc-arg-u
variable fsoc-build?
variable fsoc-load?
variable fsoc-help?
variable fsoc-version?

\ next-arg's buffer is overwritten by the next call. Keep a private copy.
: fsoc-take-arg ( c-addr u - )
    dup 255 > IF true abort" argument too long" THEN
    dup fsoc-arg-u !
    fsoc-arg-buf swap move
    fsoc-arg-buf fsoc-arg-u @ s" --build" compare 0= IF 1 fsoc-build? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" --load" compare 0= IF 1 fsoc-load? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" --help" compare 0= IF 1 fsoc-help? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" help" compare 0= IF 1 fsoc-help? ! EXIT THEN
    fsoc-arg-buf fsoc-arg-u @ s" version" compare 0= IF 1 fsoc-version? ! EXIT THEN
    true abort" unknown argument" ;

: fsoc-read-args ( - )
    0 fsoc-build? !  0 fsoc-load? !
    0 fsoc-help? !  0 fsoc-version? !
    begin
        next-arg dup
    while
        fsoc-take-arg
    repeat
    2drop ;

: fsoc-fields-clear ( - )
    0 fsoc-task-u !  0 fsoc-target-u !  0 fsoc-design-u !  0 blinky-board-u ! ;

\ included resolves names from the source file, not cwd. Absolute path via get-dir.
\ included can leave extra stack items. Nothing else is on the stack here.
: fsoc-read-target ( - )
    fsoc-fields-clear
    s" target.4th" blinky-abs included
    fsoc-task-u @ 0= IF true abort" target.4th has no task" THEN
    fsoc-target-u @ 0= IF true abort" target.4th has no target" THEN ;

: fsoc-emulation? ( - flag )
    fsoc-target-buf fsoc-target-u @ s" emulation" compare 0= ;

\ <task>-emit-emulation or <task>-on-board. Length comes from fsoc-append.
: fsoc-word-name ( - c-addr u )
    fsoc-emulation? IF
        fsoc-task-buf fsoc-task-u @ s" -emit-emulation" fsoc-append
    ELSE
        fsoc-task-buf fsoc-task-u @ s" -on-board" fsoc-append
    THEN ;

: fsoc-task-xt ( c-addr u - xt )
    find-name dup 0= IF true abort" unknown task" THEN
    name>interpret ;

\ Pass the project directory ".". Missing word aborts before any emit.
: fsoc-exec-build ( - )
    fsoc-word-name fsoc-task-xt
    s" ." rot execute ;

\ system status is the wait code: 0, or 130<<8 / signal 2 when Ctrl+C
\ stops the realtime viewer. That stop is not a build error.
: fsoc-sim-ok? ( n -- flag )
    dup 0= IF drop true EXIT THEN
    dup 256 / 130 = IF drop true EXIT THEN
    127 and 2 = ;

: fsoc-do-build ( - )
    fsoc-exec-build
    fsoc-emulation? IF
        soc-cwd-buf 1024 get-dir nip soc-cwd-a !
        s" Start emulation" soc-note
        s" sh sim.sh" system
        $? dup 0= IF drop EXIT THEN
        dup fsoc-sim-ok? 0= IF drop true abort" sim.sh failed" THEN
        drop
        s" Emulation stopped" soc-note
    THEN ;

\ Emulation ignores --load. A board runs load.sh; quartus_pgm errors stay visible.
: fsoc-do-load ( - )
    fsoc-emulation? IF EXIT THEN
    s" sh load.sh" system
    $? 0= 0= IF true abort" load.sh failed" THEN ;

: fsoc-dispatch ( - )
    fsoc-read-args
    fsoc-version? @ IF fsoc.version EXIT THEN
    fsoc-help? @ IF fsoc.help EXIT THEN
    fsoc-build? @ 0= fsoc-load? @ 0= and IF fsoc.help EXIT THEN
    fsoc-read-target
    fsoc-build? @ IF fsoc-do-build THEN
    fsoc-load? @ IF fsoc-do-load THEN ;

fsoc-dispatch
0 bye
