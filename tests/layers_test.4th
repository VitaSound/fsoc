\ tests/layers_test.4th — layer boundaries checked by loading, not by grep
\ of task files. The core loads without tasks; a design builds without fsoc.

s" test_common.4th" included
s" fixture.4th" included

\ The core alone knows no task; targets register themselves in the core.
s\" gforth fsoc/core.4th -e 's\" blinky\" task-find 0= s\" emulation\" target-find 0<> and 0= (bye)' > /dev/null 2>&1" system
$? 0= expect-true

\ The CLI names no task: no blinky-/soc- words, no suffix glue, no scripts.
s" grep -Eq 'blinky-|(^|[^f])soc-|-emit-emulation|-on-board|sim\.sh|load\.sh' fsoc.4th fsoc/build.4th" system
$? 0= expect-false

\ No task guesses the caller's directory; no code walks list nodes.
s" grep -rEq 'pick3|ulist-head|unode-' fsoc/ targets/ designs/" system
$? 0= expect-false

\ Targets carry no FPGA family literal; boards do.
s" grep -q Cyclone targets/emulation.4th targets/quartus.4th" system
$? 0= expect-false

\ A design builds with fhdlgen alone, without the builder.
test-setup
s" ${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen version" system
$? 0= expect-true
s" ${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen version | grep -Eq 'v0\.[5-9]|v[1-9]'" system
$? 0= expect-true
s" ${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen build " fjson.str-dup
s" designs/blinky_top.4th" fsoc-path fsoc-cat++
s"  --out " fsoc-cat+ tmp-dir fjson.str-concat
s"  > /dev/null 2>&1" fsoc-cat+
2dup system fjson.str-free
$? 0= expect-true
s" top.v" tmp-exists? expect-true
s" includes.lst" tmp-exists? expect-true
test-teardown

expect-stack-clean
cr ." layers_test ok" cr
