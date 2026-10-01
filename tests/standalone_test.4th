\ tests/standalone_test.4th — core-only projects. Synthesis is not part of this run.

s" test_common.4th" included
s" fixture.4th" included

s" lfe5u25f_cabga256" board-load
plat.device@ s" LFE5U-25F-6BG256C" expect-str-eq
plat.package@ s" CABGA256" expect-str-eq
plat-clock io.pins$ @ fsoc-fetch s" P6" expect-str-eq
plat-clock io.clock-hz@ 25000000 expect=
s" pad" 0 io-find io.pins$ @ fsoc-fetch s" A2" expect-str-eq
s" pad" 144 io-find io.pins$ @ fsoc-fetch s" C7" expect-str-eq
plat.ios-len 146 expect=

: sa-shape ( n leaf-a leaf-u -- )
    { n leaf-a leaf-u }
    s" FSOC_SYNTH_SKIP=1" s" --build" in-tmp-fsoc expect-true
    s" uart.v" tmp-exists? expect-false
    s" timer.v" tmp-exists? expect-false
    s" j1_wrap.v" tmp-exists? expect-false
    s" firmware.hex" tmp-exists? expect-false
    leaf-a leaf-u tmp-exists? expect-true
    s\" SITE \"P6\"" s" standalone.lpf" tmp-grep? expect-true
    s" test $(grep -c 'LOCATE COMP' standalone.lpf) -eq " n fjson.u>str fsoc-+cat
    in-tmp-sh expect-true ;

test-setup
s" standalone_j1a" tmp-use-project
82 s" stack2.v" sa-shape
s" j1.v" tmp-exists? expect-true
s" stack2.v" s" top.v" tmp-grep? expect-true
test-teardown

test-setup
s" standalone_j1abs" tmp-use-project
82 s" stacks.v" sa-shape
s" rom_init.vh" tmp-exists? expect-true
s" alu_rom" s" j1.v" tmp-grep? expect-true
test-teardown

test-setup
s" standalone_j1b" tmp-use-project
146 s" stack.v" sa-shape
s" j1b.v" tmp-exists? expect-true
s" common.h" tmp-exists? expect-true
s" mem_din" s" top.v" tmp-grep? expect-true
test-teardown

test-finish
expect-stack-clean
cr ." standalone_test ok" cr
