\ firmware-only emit: regenerate firmware.hex without the Verilator RTL
\ recompile (target.emit) or the interactive sim (target.run).
\ Mirrors fsoc-build's prefix, stopping after task.emit.
create fw-buf 1024 allot
variable fw-u

: fw-include-lib ( - )
    s" FSOC_HOME" getenv
    dup 0= IF true abort" FSOC_HOME unset" THEN
    dup 900 > IF true abort" FSOC_HOME too long" THEN
    dup fw-u !
    fw-buf swap cmove
    s" /fsoc/load.4th" dup >r
    fw-buf fw-u @ + swap cmove
    r> fw-u @ +
    fw-buf swap included ;

fw-include-lib

: fw-build ( project - )
    >r
    r@ task-of r@ target-of
    r@ project.board@ dup IF board-load ELSE 2drop THEN
    over task.emit @ r@ swap execute
    drop rdrop ;

: fw-main ( - )
    fsoc-read-manifest
    fw-build
    bye ;

fw-main
