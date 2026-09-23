\ tests/builder_test.4th — fsoc --build / --load from the project directory
\ fmix cwd is the repo root. FSOC_HOME from a project dir is ../..

s" test_common.4th" included

s" cd projects/blinky_rz_easyfpga && FSOC_HOME=../.. ../../bin/fsoc --build" system
$? 0= expect-true

s" grep -q 'PIN_87 -to led' projects/blinky_rz_easyfpga/blinky.qsf" system
$? 0= expect-true

s" cd projects/blinky_emul && FSOC_HOME=../.. ../../bin/fsoc --load" system
$? 0= expect-true

s" rm -rf projects/builder_unknown && mkdir -p projects/builder_unknown" system
$? 0= expect-true

s\" cat > projects/builder_unknown/target.4th <<'EOF'\ns\" nosuch\" fsoc-task!\ns\" emulation\" fsoc-target!\n0 0 fsoc-board!\nEOF\n" system
$? 0= expect-true

s" cd projects/builder_unknown && FSOC_HOME=../.. ../../bin/fsoc --build" system
$? 0= expect-false

s" test -f projects/builder_unknown/top.v" system
$? 0= expect-false

s" rm -rf projects/builder_unknown" system
$? 0= expect-true

: builder-fail-exit ( - )
    #ERRORS @ IF 1 (bye) THEN ;

builder-fail-exit
cr ." builder_test ok" cr
