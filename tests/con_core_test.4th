\ tests/con_core_test.4th — fsys console core + words + behavior on j1a, j1b, avr, bcpu

s" test_common.4th" included
s" fixture.4th" included
s" con_session.4th" included

test-setup
j1a-fsys-manifest
s" j1a" j1-con-session
test-teardown

test-setup
j1b-fsys-manifest
s" j1b" j1-con-session
test-teardown

test-setup
bcpu-fsys-manifest
bcpu-con-session
test-teardown

avr-con-ready? 0= [IF]
   cr ." con_core_test avr skip: sudo apt install simavr libsimavr-dev gcc" cr
[ELSE]
   test-setup
   avr-fsys-manifest
   avr-con-session
   test-teardown
[THEN]

test-finish
expect-stack-clean
cr ." con_core_test ok" cr
