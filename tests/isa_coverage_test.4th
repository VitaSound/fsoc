\ tests/isa_coverage_test.4th — П5: spec ↔ fasm coverage via futils isa-check.

s" test_common.4th" included
s" fixture.4th" included
fsoc-root s" /fsoc/futils/isa_to_fasm.4th" fjson.str-concat 2dup included fjson.str-free

: cov-check ( spec-a spec-u words-a words-u -- )
   ic-check 0<> if true abort" isa_coverage: ic-check failed" then ;

s" tools/isa_specs/avr_isa.json"   s" fsys/fasm/avr/words.4th"   cov-check
s" tools/isa_specs/z80_isa.json"   s" fsys/fasm/z80/words.4th"   cov-check
s" tools/isa_specs/mcs51_isa.json" s" fsys/fasm/8051/words.4th"  cov-check

." isa_coverage ok" cr
test-finish
