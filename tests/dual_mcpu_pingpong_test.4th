\ tests/dual_mcpu_pingpong_test.4th — two MCPU images exchange ping/pong.

s" test_common.4th" included
s" fixture.4th" included

test-setup
s" baremetal/dual_mcpu_emul" tmp-use-project
s" FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-true
s" top.v" tmp-exists? expect-true
s" cpu0.hex" tmp-exists? expect-true
s" cpu1.hex" tmp-exists? expect-true
s" MCPU_0.1a.v" tmp-exists? expect-true
s" pin ping 1" s" sim.log" tmp-grep? expect-true
s" pin pong 1" s" sim.log" tmp-grep? expect-true
s" awk '/pin ping 1/{p++} /pin pong 1/{q++} END { exit !(p>=2 && q>=2) }' sim.log" in-tmp-sh expect-true
test-teardown

test-finish
expect-stack-clean
cr ." TESTS OK" cr
