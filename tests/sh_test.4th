\ tests/sh_test.4th — shell words with one exit-code check

s" test_common.4th" included
s" fixture.4th" included

test-setup

s" rtl/blinky.v" fsoc-path
s" copy.v" tmp-file
2over 2over sh-cp
fjson.str-free fjson.str-free
s" copy.v" tmp-exists? expect-true
s" rtl/blinky.v" s" copy.v" tmp-same-as-root? expect-true

s" sub/dir" tmp-file 2dup sh-mkdir fjson.str-free
s" sub/dir" tmp-exists? expect-true

s" true" s" must not print" ' sh-run catch 0= expect-true
s" false" s" sh_test: expected failure" ' sh-run catch 0<> expect-true
2drop 2drop

test-teardown
tmp-dir nip 0= expect-true

expect-stack-clean
cr ." sh_test ok" cr
