\ tests/avr_words_test.4th — words on soft-AVR fsys console (replaces multi -m simavr).

s" test_common.4th" included
s" fixture.4th" included
s" con_session.4th" included

test-setup
avr-fsys-manifest
s" avr" con-write-in
j1-con-run expect-true
s" avr" s" sim.log" con-check
test-teardown

test-finish
expect-stack-clean
cr ." avr_words_test ok" cr
