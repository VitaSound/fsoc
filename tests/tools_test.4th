\ tests/tools_test.4th — AI-assisted CPU tools across the board (Forth entry).

s" test_common.4th" included
s" fixture.4th" included

\ Primary gate: futils run-all-tools (Python tools/run_all_tools.py is a
\ legacy mirror for scaffolding new features, not the CI entry).
\ run_all_tools already requires isa_to_fasm — do not include it twice.
fsoc-root s" /fsoc/futils/run_all_tools.4th" fjson.str-concat
2dup included fjson.str-free
run-all-tools 0= expect-true

\ Extra isa-check on the three hand-written fasm wordlists.
: tools-isa-check ( spec-a spec-u words-a words-u -- )
   ic-check 0= expect-true ;

s" tools/isa_specs/mcs51_isa.json" s" fsys/fasm/8051/words.4th" tools-isa-check
s" tools/isa_specs/avr_isa.json"   s" fsys/fasm/avr/words.4th"   tools-isa-check
s" tools/isa_specs/z80_isa.json"   s" fsys/fasm/z80/words.4th"   tools-isa-check

test-finish
