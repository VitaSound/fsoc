\ tests/j1_prompt_test.4th — Icarus must print Forth prompt

s" test_common.4th" included

s" iverilog -o /tmp/fsoc-j1 cpu/j1/j1_prompt.v cpu/j1/tb_prompt.v && /tmp/fsoc-j1 > /tmp/fsoc-j1.log" system
$? 0= expect-true
s" grep -q ok /tmp/fsoc-j1.log" system
$? 0= expect-true

cr ." j1_prompt_test ok" cr
