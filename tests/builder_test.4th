\ tests/builder_test.4th — fsoc --build / --load from a project directory.
\ Every run happens in a temporary copy of the manifest.

s" test_common.4th" included
s" fixture.4th" included

\ --- board build writes Quartus files and does not run Quartus ---
test-setup
s" blinky_rz_easyfpga" tmp-use-project
s" " s" --build" in-tmp-fsoc expect-true
s" PIN_87 -to led" s" blinky.qsf" tmp-grep? expect-true
s\" FAMILY \"Cyclone IV E\"" s" blinky.qsf" tmp-grep? expect-true
s" blinky.sdc" tmp-exists? expect-true
s" build.sh" tmp-exists? expect-true
s" load.sh" tmp-exists? expect-true
s" top.v" tmp-exists? expect-true
s" Start build" s" sim.log" tmp-grep? expect-true
s" obj_dir" tmp-exists? expect-false
test-teardown

\ --- clean keeps the manifest and removes the build ---
test-setup
s" blinky_rz_easyfpga" tmp-use-project
s" " s" --build" in-tmp-fsoc expect-true
s" top.v" tmp-exists? expect-true
s" mkdir -p obj_dir && touch obj_dir/x extra.log" in-tmp-sh expect-true
s" " s" --clean" in-tmp-fsoc expect-true
s" top.v" tmp-exists? expect-false
s" blinky.qsf" tmp-exists? expect-false
s" obj_dir" tmp-exists? expect-false
s" extra.log" tmp-exists? expect-false
s" target.4th" tmp-exists? expect-true
s" rz_easyfpga" s" target.4th" tmp-grep? expect-true
s" " s" --clean --build" in-tmp-fsoc expect-true
s" top.v" tmp-exists? expect-true
s" target.4th" tmp-exists? expect-true
test-teardown

\ --- clean without a manifest leaves the directory alone ---
test-setup
s" touch keep.txt" in-tmp-sh expect-true
s" " s" --clean" in-tmp-fsoc expect-false
s" no target.4th" s" sim.log" tmp-grep? expect-true
s" keep.txt" tmp-exists? expect-true
test-teardown

\ --- emulation ignores --load ---
test-setup
s" blinky_emul" tmp-use-project
s" " s" --load" in-tmp-fsoc expect-true
s" top.v" tmp-exists? expect-false
test-teardown

\ --- unknown task: nothing is written ---
test-setup
s\" s\" nosuch\" task:\ns\" emulation\" target:\n" tmp-manifest
s" " s" --build" in-tmp-fsoc expect-false
s" top.v" tmp-exists? expect-false
test-teardown

\ --- unknown target ---
test-setup
s\" s\" blinky\" task:\ns\" nosuch\" target:\n" tmp-manifest
s" " s" --build" in-tmp-fsoc expect-false
s" top.v" tmp-exists? expect-false
test-teardown

\ --- manifest without a target ---
test-setup
s\" s\" blinky\" task:\n" tmp-manifest
s" " s" --build" in-tmp-fsoc expect-false
s" top.v" tmp-exists? expect-false
test-teardown

\ --- the old task-named manifest words are gone ---
test-setup
s\" s\" blinky\" fsoc-task!\ns\" emulation\" fsoc-target!\n" tmp-manifest
s" " s" --build" in-tmp-fsoc expect-false
test-teardown

\ --- FSOC_HOME unset: the CLI itself stops (bin/fsoc would default it) ---
test-setup
s" blinky_emul" tmp-use-project
s" env -u FSOC_HOME gforth " fsoc-root fjson.str-concat
s" /fsoc.4th --build > sim.log 2>&1" fsoc-cat+
2dup in-tmp-sh expect-false fjson.str-free
s" FSOC_HOME unset" s" sim.log" tmp-grep? expect-true
s" top.v" tmp-exists? expect-false
test-teardown

test-finish
expect-stack-clean
cr ." builder_test ok" cr
