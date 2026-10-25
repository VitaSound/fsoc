\ tests/futils/isa_fixtures/drift_words.4th — намеренный дрейф для --check:
\ mov-a-rn=0xE9 (spec 0xE8) и add-a-rn=0x29 (spec 0x28) расходятся со спекой,
\ nolabel, без опкода уходит в (no-opcode). Эталон: tools/isa_to_fasm.py --check.
$00 mcs-op1 nop,
$E9 mcs-op1 mov-a-rn,
$29 mcs-op1 add-a-rn,
: nolabel, ( a -- ) drop ;
