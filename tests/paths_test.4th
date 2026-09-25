\ tests/paths_test.4th — repository paths come from FSOC_HOME only

s" test_common.4th" included
s" load.4th" included

s" rtl/blinky.v" fsoc-path 2dup file-exists? expect-true fjson.str-free
s" nosuch/file" fsoc-path 2dup file-exists? expect-false fjson.str-free

s" a/b/c.v" fsoc-basename s" c.v" expect-str-eq
s" c.v" fsoc-basename s" c.v" expect-str-eq
s" a/b/" fsoc-basename s" b" expect-str-eq
s" a/b/c.v" fsoc-dirname s" a/b" expect-str-eq

\ Without a root the word aborts instead of guessing.
fsoc-root 2>r
0 0 fsoc-root$ 2!
' fsoc-root catch 0<> expect-true
2r> fsoc-root!
s" rtl/blinky.v" fsoc-path 2dup file-exists? expect-true fjson.str-free

expect-stack-clean
cr ." paths_test ok" cr
