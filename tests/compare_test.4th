\ tests/compare_test.4th — cpu-compare: one scenario, j1a and j1b.
\ Empty cycles are not a winner. Mixed synthesis toolchains are not
\ marked as a core comparison. A live j1b row is filled once its kit
\ can build an image.

s" test_common.4th" included
s" fixture.4th" included

: report-save ( body-a body-u name-a name-u -- )
    tmp-file { path-a path-u }
    2dup path-a path-u 2swap fsoc-write-file
    fjson.str-free
    path-a path-u fjson.str-free ;

: tmp-egrep? ( pat-a pat-u name-a name-u -- flag )
    2>r
    s" grep -E -q '" 2swap fjson.str-concat
    s" ' " fsoc-cat+
    2r> fsoc-cat+
    2dup in-tmp-sh -rot fjson.str-free ;

: home-file { rel-a rel-u -- c-addr u }
    cmp-home s" /" fjson.str-concat { a1 u1 }
    a1 u1 rel-a rel-u fjson.str-concat
    a1 u1 fjson.str-free ;

: home-grep? { pat-a pat-u rel-a rel-u -- flag }
    rel-a rel-u home-file { path-a path-u }
    s" grep -q '" pat-a pat-u fjson.str-concat
    s" ' " fjson.str-concat path-a path-u fjson.str-concat { cmd-a cmd-u }
    path-a path-u fjson.str-free
    cmd-a cmd-u system
    cmd-a cmd-u fjson.str-free
    $? 0= ;

: home-one? ( rel-a rel-u -- flag )
    home-file
    s" awk 'END{exit !(NR==1)}' " 2swap fjson.str-concat
    2dup system fjson.str-free
    $? 0= ;

: cmp-stop ( -- )
    #ERRORS @ IF cmp-drop test-teardown 1 (bye) THEN ;

test-setup

\ Widths stay on the row. A smaller byte count is not a better image.
\ An empty cycles cell is not filled from the other row and is not a winner.
cmp-init
s" j1a" 100 200 s" emulation" s" " cmp-note
s" j1b" 40 cmp-empty s" emulation" s" " cmp-note
cmp-text s" width.txt" report-save
s" ^j1a V V I 16 100 200 emulation -$" s" width.txt" tmp-egrep? expect-true
s" ^j1b V V I 32 40 - emulation -$" s" width.txt" tmp-egrep? expect-true
s" fewer cycles" s" width.txt" tmp-grep? expect-false
s" efficient" s" width.txt" tmp-grep? expect-false
s" core compare" s" width.txt" tmp-grep? expect-true

\ Both columns filled: the fewer cycle count wins. Bytes are still not ranked.
cmp-init
s" j1a" 100 300 s" emulation" s" " cmp-note
s" j1b" 40 150 s" emulation" s" " cmp-note
cmp-text s" win.txt" report-save
s" fewer cycles j1b" s" win.txt" tmp-grep? expect-true
s" efficient" s" win.txt" tmp-grep? expect-false
s" ^j1a V V I 16 100 300 emulation -$" s" win.txt" tmp-egrep? expect-true
s" ^j1b V V I 32 40 150 emulation -$" s" win.txt" tmp-egrep? expect-true

\ A different EX-C stays in the report and is not the winner.
cmp-init
s" j1a" 100 300 s" emulation" s" " cmp-note
s" stm8" 50 10 s" emulation" s" " cmp-note
cmp-text s" exc.txt" report-save
s" ^j1a V V I 16 100 300 emulation -$" s" exc.txt" tmp-egrep? expect-true
s" ^stm8 D S E " s" exc.txt" tmp-egrep? expect-true
s" fewer cycles" s" exc.txt" tmp-grep? expect-false
s" core compare" s" exc.txt" tmp-grep? expect-true

\ Quartus and Yosys in one report are not a comparison of cores.
cmp-init
s" j1a" 100 200 s" quartus" s" terasic_de0nano" cmp-note
s" j1b" 80 150 s" yosys" s" colorlight_5a_75e_v6_0" cmp-note
cmp-text s" mixed.txt" report-save
s" quartus" s" mixed.txt" tmp-grep? expect-true
s" yosys" s" mixed.txt" tmp-grep? expect-true
s" core compare" s" mixed.txt" tmp-grep? expect-false
s" fewer cycles" s" mixed.txt" tmp-grep? expect-false
s" LUT4" s" mixed.txt" tmp-grep? expect-false
s" Fmax" s" mixed.txt" tmp-grep? expect-false

cmp-stop

\ Live table: both kits are measured. An empty hand-built row is not.
s" j1b" cpu-find cpu-image? expect-true
s" soc" s" 1 2 + ." s" j1a j1b" s" emulation" s" " s" designs/soc_console.4th" cpu-compare
s" compare.txt" report-save
s" ^j1a V V I 16 [0-9]+ [0-9]+ emulation -$" s" compare.txt" tmp-egrep? expect-true
s" ^j1b V V I 32 [0-9]+ [0-9]+ emulation -$" s" compare.txt" tmp-egrep? expect-true
s" core compare" s" compare.txt" tmp-grep? expect-true
s" fewer cycles" s" compare.txt" tmp-grep? expect-true
s" efficient" s" compare.txt" tmp-grep? expect-false
s" LUT4" s" compare.txt" tmp-grep? expect-false
s" Fmax" s" compare.txt" tmp-grep? expect-false
s" quartus" s" compare.txt" tmp-grep? expect-false
s" yosys" s" compare.txt" tmp-grep? expect-false
s" nextpnr" s" compare.txt" tmp-grep? expect-false
s" ran.log" home-file
s" awk 'END{exit !(NR==2)}' " 2swap fjson.str-concat
2dup system fjson.str-free
$? 0= expect-true
s" fsoc --build" s" ran.log" home-grep? expect-true
s" yosys" s" ran.log" home-grep? expect-false
s" quartus" s" ran.log" home-grep? expect-false
s" nextpnr" s" ran.log" home-grep? expect-false
s" yosys" s" j1a/sim.log" home-grep? expect-false
s" quartus" s" j1a/sim.log" home-grep? expect-false
s" nextpnr" s" j1a/sim.log" home-grep? expect-false
s" LUT4" s" j1a/sim.log" home-grep? expect-false
s" Fmax" s" j1a/sim.log" home-grep? expect-false
s" 3  ok" s" j1a/sim.log" home-grep? expect-true

cmp-drop
test-teardown
test-finish
expect-stack-clean
cr ." compare_test ok" cr
