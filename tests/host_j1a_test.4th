\ tests/host_j1a_test.4th — j1a host image stays the same size

s" test_common.4th" included
s" fixture.4th" included

s" fsys/kernel/j1a/kernel.4th" fsoc-path 2dup included fjson.str-free
s" fsys/host/cross.4th" fsoc-path 2dup included fjson.str-free

: j1a-xc ( c-addr u -- )
    fsoc-path 2dup xc-load fjson.str-free ;

s" fsys/common/common.4th" j1a-xc
s" fsys/common/core.4th" j1a-xc
xc-here@ 7550 expect=
s" fsys/j1a/extra-min.4th" j1a-xc
xc-here@ 8008 expect=

test-finish
cr ." host_j1a_test ok" cr
