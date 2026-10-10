\ tests/pre_push_test.4th — long core tests are selected from changed paths.
\ pre-commit and pre-push share tools/long-core-select.sh (--list).

s" test_common.4th" included
s" fixture.4th" included

: pp-list-script { path-a path-u script-a script-u -- }
   s" printf '%s\n' '" path-a path-u fjson.str-concat
   s" ' | " fjson.str-concat
   fsoc-root fjson.str-concat
   s" /tools/" fjson.str-concat
   script-a script-u fjson.str-concat
   s"  --list > pp.out" fjson.str-concat
   in-tmp-sh expect-true ;

: pp-list ( c-addr u -- )
   s" pre-push.sh" pp-list-script ;

: pc-list ( c-addr u -- )
   s" pre-commit.sh" pp-list-script ;

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
s" README.md" pc-list
pp-empty

s" cpu/mcpu/MCPU_0.1a.v" pp-list
pp-empty

s" cpu/mcpu/dual_pingpong.v" pp-list
s" tests/dual_mcpu_pingpong_test.4th" pp-has
s" tests/standalone_test.4th" pp-lacks

s" fsys/kernel/avr/kernel.4th" pp-list
s" tests/con_core_test.4th" pp-has
s" tests/avr_dict_test.4th" pp-has
s" tests/avr_words_test.4th" pp-has
s" tests/avr_soc_blink_test.4th" pp-has
s" tests/j1abs_test.4th" pp-lacks

s" fsys/kernel/avr/kernel.4th" pc-list
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

s" cpu/cd16/cd16.v" pp-list
s" tests/cd16_test.4th" pp-has
s" tests/con_core_test.4th" pp-has

s" cpu/msl16/msl16.v" pp-list
s" tests/msl16_test.4th" pp-has
s" tests/con_core_test.4th" pp-has

s" cpu/z80/tv80s.v" pp-list
s" tests/z80_test.4th" pp-has
s" tests/con_core_test.4th" pp-has

test-teardown
test-finish
expect-stack-clean
cr ." pre_push_test ok" cr
