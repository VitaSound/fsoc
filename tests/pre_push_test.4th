\ tests/pre_push_test.4th — long core tests are selected from changed paths.

s" test_common.4th" included
s" fixture.4th" included

: pp-list ( c-addr u -- )
   s" printf '%s\n' '" 2swap fjson.str-concat
   s" ' | " fjson.str-concat
   fsoc-root fjson.str-concat
   s" /tools/pre-push.sh --list > pp.out" fjson.str-concat
   in-tmp-sh expect-true ;

: pp-has ( c-addr u -- )
   s" grep -qx '" 2swap fjson.str-concat
   s" ' pp.out" fjson.str-concat
   in-tmp-sh expect-true ;

: pp-lacks ( c-addr u -- )
   s" grep -qx '" 2swap fjson.str-concat
   s" ' pp.out" fjson.str-concat
   in-tmp-sh 0= expect-true ;

: pp-empty ( -- )
   s" test ! -s pp.out" in-tmp-sh expect-true ;

test-setup

s" README.md" pp-list
pp-empty

s" cpu/mcpu/MCPU_0.1a.v" pp-list
pp-empty

s" fsys/kernel/avr/kernel.4th" pp-list
s" tests/con_core_test.4th" pp-has
s" tests/avr_dict_test.4th" pp-has
s" tests/avr_words_test.4th" pp-has
s" tests/avr_soc_blink_test.4th" pp-has
s" tests/j1abs_test.4th" pp-lacks

s" cpu/j1/j1abs/j1.v" pp-list
s" tests/j1abs_test.4th" pp-has
s" tests/con_core_test.4th" pp-lacks

s" fsys/kernel/j1a/kernel.4th" pp-list
s" tests/con_core_test.4th" pp-has
s" tests/common_test.4th" pp-has
s" tests/j1abs_test.4th" pp-has

s" cpu/bcpu/bcpu.v" pp-list
s" tests/bcpu_test.4th" pp-has
s" tests/con_core_test.4th" pp-has

test-teardown
test-finish
expect-stack-clean
cr ." pre_push_test ok" cr
