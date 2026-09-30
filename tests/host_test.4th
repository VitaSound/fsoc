\ tests/host_test.4th — j1b host compiler packs two instructions per cell

s" test_common.4th" included
s" fixture.4th" included

s" fsys/kernel/j1b/kernel.4th" fsoc-path 2dup included fjson.str-free
s" fsys/host/cross.4th" fsoc-path 2dup included fjson.str-free

: host-load ( c-addr u -- )
    s" /tmp/fsoc-host.4th" w/o create-file throw { fd }
    fd write-file throw
    fd close-file throw
    s" /tmp/fsoc-host.4th" xc-load ;

: cfa-of ( c-addr u -- cfa )
    xc-find 0= abort" host_test: missing"
    drop ;

variable seen
: hw@ ( cfa off -- u ) + xc-hw ;

: j1b-xc ( c-addr u -- )
    fsoc-path 2dup xc-load fjson.str-free ;

s" fsys/common/common.4th" j1b-xc
s" fsys/common/core.4th" j1b-xc
xc-here@ 8324 expect=
s" fsys/j1b/extra.4th" j1b-xc
xc-here@ 8978 expect=

s" : pack 1 2 + ;" host-load
s" pack" cfa-of seen !
seen @ 0 hw@ $8001 expect=
seen @ 2 hw@ $8002 expect=
seen @ 2 hw@ $6000 = expect-false
seen @ 4 hw@ $e000 and 0 expect=

s" : br 1 if 2 else 3 then ;" host-load
s" br" cfa-of seen !
seen @ 0 hw@ $8001 expect=
seen @ 2 hw@ $e000 and $2000 expect=
seen @ 2 hw@ $1fff and 2* seen @ 8 + expect=
seen @ 4 hw@ $8002 expect=
seen @ 6 hw@ $e000 and 0 expect=
seen @ 6 hw@ $1fff and 2* seen @ 10 + expect=
seen @ 8 hw@ $8003 expect=
seen @ 10 hw@ $608c expect=

s" 5 constant ka  : rd ka @ ;" host-load
s" ka" cfa-of seen !
seen @ 0 hw@ $8005 expect=
seen @ 2 hw@ $6000 expect=
seen @ 4 hw@ $608c expect=
s" rd" cfa-of seen !
seen @ 0 hw@ $8005 expect=
seen @ 2 hw@ $6c8c expect=

s" : da dup @ ;" host-load
s" da" cfa-of xc-hw $6c9d expect=

\ store is two ALU ops, so inlining ! would be longer than the two calls.
s" variable vx  : sv vx ! ;" host-load
s" sv" cfa-of seen !
seen @ 0 hw@ $e000 and $4000 expect=
seen @ 2 hw@ $e000 and 0 expect=
xc-here@ seen @ - 4 expect=

: host-far ( -- ) 16384 xc-here! ;
' host-far catch 0<> expect-true

s" : sr 2dup rshift ;" host-load
s" sr" cfa-of xc-hw $699d expect=
s" : sl 2dup lshift ;" host-load
s" sl" cfa-of xc-hw $6a9d expect=

test-finish
cr ." host_test ok" cr
