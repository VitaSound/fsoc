\ tests/registry_test.4th — registry and the build order

s" test_common.4th" included
s" load.4th" included

variable trace
: trace+ ( n project -- ) drop trace @ 10 * + trace ! ;
: fake-task-emit ( project -- ) 1 swap trace+ ;
: fake-target-emit ( project -- ) 2 swap trace+ ;
: fake-target-run ( project -- ) 3 swap trace+ ;
: fake-target-load ( project -- ) 4 swap trace+ ;

s" faketask" ' fake-task-emit task-register
s" faketarget" ' fake-target-emit ' fake-target-run ' fake-target-load target-register

s" faketask" task-find 0<> expect-true
s" faketask" task-find task.name$ @ fsoc-fetch s" faketask" expect-str-eq
s" faketarget" target-find 0<> expect-true
s" nosuch" task-find 0= expect-true
s" nosuch" target-find 0= expect-true
s" blinky" task-find 0<> expect-true
s" soc" task-find 0<> expect-true
s" emulation" target-find 0<> expect-true
s" quartus" target-find 0<> expect-true
s" yosys" target-find 0<> expect-true

project-new
s" faketask" task:
s" faketarget" target:
0 trace !
project@ fsoc-build
trace @ 123 expect=
project@ fsoc-load
trace @ 1234 expect=

\ Unknown names stop before any emit.
project-new
s" nosuch" task:
s" faketarget" target:
0 trace !
project@ ' fsoc-build catch 0<> expect-true
drop
trace @ 0 expect=

project-new
s" faketask" task:
s" nosuch" target:
project@ ' fsoc-build catch 0<> expect-true
drop
trace @ 0 expect=

expect-stack-clean
cr ." registry_test ok" cr
