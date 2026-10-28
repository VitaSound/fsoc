\ auto-generated disasm.4th from ISA spec (futils disasm_gen).
\ Defines fasm-dis-one for the common disasm engine.
\ Zero-operand forms print assemblable name, for D→A round-trip.

include ../common/fasm-dis.4th

:noname ( pc -- pc' )
    { pc } pc fasm@ ( opcode )
    case
        $00 of
            ." 00" ."  "
            ." nop,"
            1
        endof
        $76 of
            ." 76" ."  "
            ." halt,"
            1
        endof
        $F3 of
            ." F3" ."  "
            ." di,"
            1
        endof
        $FB of
            ." FB" ."  "
            ." ei,"
            1
        endof
        $28 of
            ." 28" ."  "
            ." LD {d},{s}"
            1
        endof
        $29 of
            ." 29" ."  "
            ." LD {d},{s}"
            1
        endof
        $2A of
            ." 2A" ."  "
            ." LD {d},{s}"
            1
        endof
        $2B of
            ." 2B" ."  "
            ." LD {d},{s}"
            1
        endof
        $2C of
            ." 2C" ."  "
            ." LD {d},{s}"
            1
        endof
        $2D of
            ." 2D" ."  "
            ." LD {d},{s}"
            1
        endof
        $2E of
            ." 2E" ."  "
            ." LD {d},{s}"
            1
        endof
        $2F of
            ." 2F" ."  "
            ." LD {d},{s}"
            1
        endof
        $06 of
            ." 06" ."  "
            ." LD {d},{imm}"
            2
        endof
        $07 of
            ." 07" ."  "
            ." LD {d},{imm}"
            2
        endof
        $08 of
            ." 08" ."  "
            ." LD {d},{imm}"
            2
        endof
        $09 of
            ." 09" ."  "
            ." LD {d},{imm}"
            2
        endof
        $0A of
            ." 0A" ."  "
            ." LD {d},{imm}"
            2
        endof
        $0B of
            ." 0B" ."  "
            ." LD {d},{imm}"
            2
        endof
        $0C of
            ." 0C" ."  "
            ." LD {d},{imm}"
            2
        endof
        $0D of
            ." 0D" ."  "
            ." LD {d},{imm}"
            2
        endof
        $6A of
            ." 6A" ."  "
            ." LD {d},(HL)"
            1
        endof
        $6B of
            ." 6B" ."  "
            ." LD {d},(HL)"
            1
        endof
        $6C of
            ." 6C" ."  "
            ." LD {d},(HL)"
            1
        endof
        $6D of
            ." 6D" ."  "
            ." LD {d},(HL)"
            1
        endof
        $6E of
            ." 6E" ."  "
            ." LD {d},(HL)"
            1
        endof
        $6F of
            ." 6F" ."  "
            ." LD {d},(HL)"
            1
        endof
        $70 of
            ." 70" ."  "
            ." LD {d},(HL)"
            1
        endof
        $71 of
            ." 71" ."  "
            ." LD {d},(HL)"
            1
        endof
        $70 of
            ." 70" ."  "
            ." LD (HL),{s}"
            1
        endof
        $71 of
            ." 71" ."  "
            ." LD (HL),{s}"
            1
        endof
        $72 of
            ." 72" ."  "
            ." LD (HL),{s}"
            1
        endof
        $73 of
            ." 73" ."  "
            ." LD (HL),{s}"
            1
        endof
        $74 of
            ." 74" ."  "
            ." LD (HL),{s}"
            1
        endof
        $75 of
            ." 75" ."  "
            ." LD (HL),{s}"
            1
        endof
        $76 of
            ." 76" ."  "
            ." LD (HL),{s}"
            1
        endof
        $77 of
            ." 77" ."  "
            ." LD (HL),{s}"
            1
        endof
        $0A of
            ." 0A" ."  "
            ." ld_a_bc,"
            1
        endof
        $1A of
            ." 1A" ."  "
            ." ld_a_de,"
            1
        endof
        $02 of
            ." 02" ."  "
            ." ld_bc_a,"
            1
        endof
        $12 of
            ." 12" ."  "
            ." ld_de_a,"
            1
        endof
        $3A of
            ." 3A" ."  "
            ." LD A,({addr})"
            3
        endof
        $32 of
            ." 32" ."  "
            ." LD ({addr}),A"
            3
        endof
        $01 of
            ." 01" ."  "
            ." LD {reg16},({addr})"
            3
        endof
        $22 of
            ." 22" ."  "
            ." LD {d},({addr})"
            3
        endof
        $2A of
            ." 2A" ."  "
            ." LD ({addr}),HL"
            3
        endof
        $04 of
            ." 04" ."  "
            ." INC {d}"
            1
        endof
        $05 of
            ." 05" ."  "
            ." INC {d}"
            1
        endof
        $06 of
            ." 06" ."  "
            ." INC {d}"
            1
        endof
        $07 of
            ." 07" ."  "
            ." INC {d}"
            1
        endof
        $08 of
            ." 08" ."  "
            ." INC {d}"
            1
        endof
        $09 of
            ." 09" ."  "
            ." INC {d}"
            1
        endof
        $0A of
            ." 0A" ."  "
            ." INC {d}"
            1
        endof
        $0B of
            ." 0B" ."  "
            ." INC {d}"
            1
        endof
        $05 of
            ." 05" ."  "
            ." DEC {d}"
            1
        endof
        $06 of
            ." 06" ."  "
            ." DEC {d}"
            1
        endof
        $07 of
            ." 07" ."  "
            ." DEC {d}"
            1
        endof
        $08 of
            ." 08" ."  "
            ." DEC {d}"
            1
        endof
        $09 of
            ." 09" ."  "
            ." DEC {d}"
            1
        endof
        $0A of
            ." 0A" ."  "
            ." DEC {d}"
            1
        endof
        $0B of
            ." 0B" ."  "
            ." DEC {d}"
            1
        endof
        $0C of
            ." 0C" ."  "
            ." DEC {d}"
            1
        endof
        $03 of
            ." 03" ."  "
            ." INC {reg16}"
            1
        endof
        $0B of
            ." 0B" ."  "
            ." DEC {reg16}"
            1
        endof
        $80 of
            ." 80" ."  "
            ." ADD A,{s}"
            1
        endof
        $81 of
            ." 81" ."  "
            ." ADD A,{s}"
            1
        endof
        $82 of
            ." 82" ."  "
            ." ADD A,{s}"
            1
        endof
        $83 of
            ." 83" ."  "
            ." ADD A,{s}"
            1
        endof
        $84 of
            ." 84" ."  "
            ." ADD A,{s}"
            1
        endof
        $85 of
            ." 85" ."  "
            ." ADD A,{s}"
            1
        endof
        $86 of
            ." 86" ."  "
            ." ADD A,{s}"
            1
        endof
        $87 of
            ." 87" ."  "
            ." ADD A,{s}"
            1
        endof
        $90 of
            ." 90" ."  "
            ." SUB {s}"
            1
        endof
        $91 of
            ." 91" ."  "
            ." SUB {s}"
            1
        endof
        $92 of
            ." 92" ."  "
            ." SUB {s}"
            1
        endof
        $93 of
            ." 93" ."  "
            ." SUB {s}"
            1
        endof
        $94 of
            ." 94" ."  "
            ." SUB {s}"
            1
        endof
        $95 of
            ." 95" ."  "
            ." SUB {s}"
            1
        endof
        $96 of
            ." 96" ."  "
            ." SUB {s}"
            1
        endof
        $97 of
            ." 97" ."  "
            ." SUB {s}"
            1
        endof
        $A0 of
            ." A0" ."  "
            ." AND {s}"
            1
        endof
        $A1 of
            ." A1" ."  "
            ." AND {s}"
            1
        endof
        $A2 of
            ." A2" ."  "
            ." AND {s}"
            1
        endof
        $A3 of
            ." A3" ."  "
            ." AND {s}"
            1
        endof
        $A4 of
            ." A4" ."  "
            ." AND {s}"
            1
        endof
        $A5 of
            ." A5" ."  "
            ." AND {s}"
            1
        endof
        $A6 of
            ." A6" ."  "
            ." AND {s}"
            1
        endof
        $A7 of
            ." A7" ."  "
            ." AND {s}"
            1
        endof
        $A8 of
            ." A8" ."  "
            ." XOR {s}"
            1
        endof
        $A9 of
            ." A9" ."  "
            ." XOR {s}"
            1
        endof
        $AA of
            ." AA" ."  "
            ." XOR {s}"
            1
        endof
        $AB of
            ." AB" ."  "
            ." XOR {s}"
            1
        endof
        $AC of
            ." AC" ."  "
            ." XOR {s}"
            1
        endof
        $AD of
            ." AD" ."  "
            ." XOR {s}"
            1
        endof
        $AE of
            ." AE" ."  "
            ." XOR {s}"
            1
        endof
        $AF of
            ." AF" ."  "
            ." XOR {s}"
            1
        endof
        $B0 of
            ." B0" ."  "
            ." OR {s}"
            1
        endof
        $B1 of
            ." B1" ."  "
            ." OR {s}"
            1
        endof
        $B2 of
            ." B2" ."  "
            ." OR {s}"
            1
        endof
        $B3 of
            ." B3" ."  "
            ." OR {s}"
            1
        endof
        $B4 of
            ." B4" ."  "
            ." OR {s}"
            1
        endof
        $B5 of
            ." B5" ."  "
            ." OR {s}"
            1
        endof
        $B6 of
            ." B6" ."  "
            ." OR {s}"
            1
        endof
        $B7 of
            ." B7" ."  "
            ." OR {s}"
            1
        endof
        $B8 of
            ." B8" ."  "
            ." CP {s}"
            1
        endof
        $B9 of
            ." B9" ."  "
            ." CP {s}"
            1
        endof
        $BA of
            ." BA" ."  "
            ." CP {s}"
            1
        endof
        $BB of
            ." BB" ."  "
            ." CP {s}"
            1
        endof
        $BC of
            ." BC" ."  "
            ." CP {s}"
            1
        endof
        $BD of
            ." BD" ."  "
            ." CP {s}"
            1
        endof
        $BE of
            ." BE" ."  "
            ." CP {s}"
            1
        endof
        $BF of
            ." BF" ."  "
            ." CP {s}"
            1
        endof
        $C6 of
            ." C6" ."  "
            ." ADD A,{imm}"
            2
        endof
        $D6 of
            ." D6" ."  "
            ." SUB {imm}"
            2
        endof
        $C5 of
            ." C5" ."  "
            ." PUSH {reg16}"
            1
        endof
        $C6 of
            ." C6" ."  "
            ." PUSH {reg16}"
            1
        endof
        $C7 of
            ." C7" ."  "
            ." PUSH {reg16}"
            1
        endof
        $C8 of
            ." C8" ."  "
            ." PUSH {reg16}"
            1
        endof
        $C9 of
            ." C9" ."  "
            ." PUSH {reg16}"
            1
        endof
        $CA of
            ." CA" ."  "
            ." PUSH {reg16}"
            1
        endof
        $CB of
            ." CB" ."  "
            ." PUSH {reg16}"
            1
        endof
        $CC of
            ." CC" ."  "
            ." PUSH {reg16}"
            1
        endof
        $C1 of
            ." C1" ."  "
            ." POP {reg16}"
            1
        endof
        $C2 of
            ." C2" ."  "
            ." POP {reg16}"
            1
        endof
        $C3 of
            ." C3" ."  "
            ." POP {reg16}"
            1
        endof
        $C4 of
            ." C4" ."  "
            ." POP {reg16}"
            1
        endof
        $C5 of
            ." C5" ."  "
            ." POP {reg16}"
            1
        endof
        $C6 of
            ." C6" ."  "
            ." POP {reg16}"
            1
        endof
        $C7 of
            ." C7" ."  "
            ." POP {reg16}"
            1
        endof
        $C8 of
            ." C8" ."  "
            ." POP {reg16}"
            1
        endof
        $C3 of
            ." C3" ."  "
            ." JP {addr}"
            3
        endof
        $CD of
            ." CD" ."  "
            ." CALL {addr}"
            3
        endof
        $C9 of
            ." C9" ."  "
            ." ret,"
            1
        endof
        $18 of
            ." 18" ."  "
            ." JR {rel}"
            2
        endof
        $E9 of
            ." E9" ."  "
            ." jp_hl,"
            1
        endof
        $C2 of
            ." C2" ."  "
            ." JP {cc},{addr}"
            3
        endof
        $C4 of
            ." C4" ."  "
            ." CALL {cc},{addr}"
            3
        endof
        $C0 of
            ." C0" ."  "
            ." RET {cc}"
            1
        endof
        $10 of
            ." 10" ."  "
            ." DJNZ {rel}"
            2
        endof
        $C7 of
            ." C7" ."  "
            ." RST {vector}"
            1
        endof
        $DB of
            ." DB" ."  "
            ." IN A,({port})"
            2
        endof
        $D3 of
            ." D3" ."  "
            ." OUT ({port}),A"
            2
        endof
        $09 of
            ." 09" ."  "
            ." ADD HL,{reg16}"
            1
        endof
        $27 of
            ." 27" ."  "
            ." daa,"
            1
        endof
        $2F of
            ." 2F" ."  "
            ." cpl,"
            1
        endof
        $44 of
            ." 44" ."  "
            ." neg,"
            1
        endof
        $D9 of
            ." D9" ."  "
            ." exx,"
            1
        endof
        $EB of
            ." EB" ."  "
            ." ex_de_hl,"
            1
        endof
        $07 of
            ." 07" ."  "
            ." rlca,"
            1
        endof
        $0F of
            ." 0F" ."  "
            ." rrca,"
            1
        endof
        $17 of
            ." 17" ."  "
            ." rla,"
            1
        endof
        $1F of
            ." 1F" ."  "
            ." rra,"
            1
        endof
        $37 of
            ." 37" ."  "
            ." scf,"
            1
        endof
        $3F of
            ." 3F" ."  "
            ." ccf,"
            1
        endof
        $08 of
            ." 08" ."  "
            ." exaf,"
            1
        endof
        $EB of
            ." EB" ."  "
            ." exde,"
            1
        endof
        $E3 of
            ." E3" ."  "
            ." exsp,"
            1
        endof
        $F9 of
            ." F9" ."  "
            ." sphl,"
            1
        endof
        $E9 of
            ." E9" ."  "
            ." jphl,"
            1
        endof
        $40 of
            ." 40" ."  "
            ." LD {d},{s}"
            1
        endof
        $80 of
            ." 80" ."  "
            ." ADD A,{s}"
            1
        endof
        $81 of
            ." 81" ."  "
            ." ADD A,{s}"
            1
        endof
        $82 of
            ." 82" ."  "
            ." ADD A,{s}"
            1
        endof
        $83 of
            ." 83" ."  "
            ." ADD A,{s}"
            1
        endof
        $84 of
            ." 84" ."  "
            ." ADD A,{s}"
            1
        endof
        $85 of
            ." 85" ."  "
            ." ADD A,{s}"
            1
        endof
        $86 of
            ." 86" ."  "
            ." ADD A,{s}"
            1
        endof
        $87 of
            ." 87" ."  "
            ." ADD A,{s}"
            1
        endof
        $88 of
            ." 88" ."  "
            ." ADC A,{s}"
            1
        endof
        $89 of
            ." 89" ."  "
            ." ADC A,{s}"
            1
        endof
        $8A of
            ." 8A" ."  "
            ." ADC A,{s}"
            1
        endof
        $8B of
            ." 8B" ."  "
            ." ADC A,{s}"
            1
        endof
        $8C of
            ." 8C" ."  "
            ." ADC A,{s}"
            1
        endof
        $8D of
            ." 8D" ."  "
            ." ADC A,{s}"
            1
        endof
        $8E of
            ." 8E" ."  "
            ." ADC A,{s}"
            1
        endof
        $8F of
            ." 8F" ."  "
            ." ADC A,{s}"
            1
        endof
        $90 of
            ." 90" ."  "
            ." SUB {s}"
            1
        endof
        $91 of
            ." 91" ."  "
            ." SUB {s}"
            1
        endof
        $92 of
            ." 92" ."  "
            ." SUB {s}"
            1
        endof
        $93 of
            ." 93" ."  "
            ." SUB {s}"
            1
        endof
        $94 of
            ." 94" ."  "
            ." SUB {s}"
            1
        endof
        $95 of
            ." 95" ."  "
            ." SUB {s}"
            1
        endof
        $96 of
            ." 96" ."  "
            ." SUB {s}"
            1
        endof
        $97 of
            ." 97" ."  "
            ." SUB {s}"
            1
        endof
        $98 of
            ." 98" ."  "
            ." SBC A,{s}"
            1
        endof
        $99 of
            ." 99" ."  "
            ." SBC A,{s}"
            1
        endof
        $9A of
            ." 9A" ."  "
            ." SBC A,{s}"
            1
        endof
        $9B of
            ." 9B" ."  "
            ." SBC A,{s}"
            1
        endof
        $9C of
            ." 9C" ."  "
            ." SBC A,{s}"
            1
        endof
        $9D of
            ." 9D" ."  "
            ." SBC A,{s}"
            1
        endof
        $9E of
            ." 9E" ."  "
            ." SBC A,{s}"
            1
        endof
        $9F of
            ." 9F" ."  "
            ." SBC A,{s}"
            1
        endof
        $0A of
            ." 0A" ."  "
            ." a_a_bc,"
            1
        endof
        $1A of
            ." 1A" ."  "
            ." a_a_de,"
            1
        endof
        $02 of
            ." 02" ."  "
            ." bc!a,"
            1
        endof
        $12 of
            ." 12" ."  "
            ." de!a,"
            1
        endof
        $03 of
            ." 03" ."  "
            ." INC {reg16}"
            1
        endof
        $0B of
            ." 0B" ."  "
            ." DEC {reg16}"
            1
        endof
        $C6 of
            ." C6" ."  "
            ." ADD A,{imm}"
            2
        endof
        $CE of
            ." CE" ."  "
            ." ADC A,{imm}"
            2
        endof
        $D6 of
            ." D6" ."  "
            ." SUB {imm}"
            2
        endof
        $DE of
            ." DE" ."  "
            ." SBC A,{imm}"
            2
        endof
        $E6 of
            ." E6" ."  "
            ." AND {imm}"
            2
        endof
        $EE of
            ." EE" ."  "
            ." XOR {imm}"
            2
        endof
        $F6 of
            ." F6" ."  "
            ." OR {imm}"
            2
        endof
        $FE of
            ." FE" ."  "
            ." CP {imm}"
            2
        endof
        $18 of
            ." 18" ."  "
            ." JR {rel}"
            2
        endof
        $20 of
            ." 20" ."  "
            ." JR NZ,{rel}"
            2
        endof
        $28 of
            ." 28" ."  "
            ." JR Z,{rel}"
            2
        endof
        $30 of
            ." 30" ."  "
            ." JR NC,{rel}"
            2
        endof
        $38 of
            ." 38" ."  "
            ." JR C,{rel}"
            2
        endof
        $10 of
            ." 10" ."  "
            ." DJNZ {rel}"
            2
        endof
        $DB of
            ." DB" ."  "
            ." IN A,({port})"
            2
        endof
        $D3 of
            ." D3" ."  "
            ." OUT ({port}),A"
            2
        endof
        $06 of
            ." 06" ."  "
            ." LD {d},{imm}"
            2
        endof
        $07 of
            ." 07" ."  "
            ." LD {d},{imm}"
            2
        endof
        $08 of
            ." 08" ."  "
            ." LD {d},{imm}"
            2
        endof
        $09 of
            ." 09" ."  "
            ." LD {d},{imm}"
            2
        endof
        $0A of
            ." 0A" ."  "
            ." LD {d},{imm}"
            2
        endof
        $0B of
            ." 0B" ."  "
            ." LD {d},{imm}"
            2
        endof
        $0C of
            ." 0C" ."  "
            ." LD {d},{imm}"
            2
        endof
        $0D of
            ." 0D" ."  "
            ." LD {d},{imm}"
            2
        endof
        $01 of
            ." 01" ."  "
            ." LD {reg16},{imm}"
            3
        endof
        $C2 of
            ." C2" ."  "
            ." JP {cc},{addr}"
            3
        endof
        $C4 of
            ." C4" ."  "
            ." CALL {cc},{addr}"
            3
        endof
        $DD of
            ." DD" ."  "
            ." LD {d},(IX+d)"
            3
        endof
        $DE of
            ." DE" ."  "
            ." LD {d},(IX+d)"
            3
        endof
        $DF of
            ." DF" ."  "
            ." LD {d},(IX+d)"
            3
        endof
        $E0 of
            ." E0" ."  "
            ." LD {d},(IX+d)"
            3
        endof
        $E1 of
            ." E1" ."  "
            ." LD {d},(IX+d)"
            3
        endof
        $E2 of
            ." E2" ."  "
            ." LD {d},(IX+d)"
            3
        endof
        $E3 of
            ." E3" ."  "
            ." LD {d},(IX+d)"
            3
        endof
        $E4 of
            ." E4" ."  "
            ." LD {d},(IX+d)"
            3
        endof
        $FD of
            ." FD" ."  "
            ." LD {d},(IY+d)"
            3
        endof
        $FE of
            ." FE" ."  "
            ." LD {d},(IY+d)"
            3
        endof
        $FF of
            ." FF" ."  "
            ." LD {d},(IY+d)"
            3
        endof
        $100 of
            ." 100" ."  "
            ." LD {d},(IY+d)"
            3
        endof
        $101 of
            ." 101" ."  "
            ." LD {d},(IY+d)"
            3
        endof
        $102 of
            ." 102" ."  "
            ." LD {d},(IY+d)"
            3
        endof
        $103 of
            ." 103" ."  "
            ." LD {d},(IY+d)"
            3
        endof
        $104 of
            ." 104" ."  "
            ." LD {d},(IY+d)"
            3
        endof
        $DD of
            ." DD" ."  "
            ." LD (IX+d),{s}"
            3
        endof
        $DE of
            ." DE" ."  "
            ." LD (IX+d),{s}"
            3
        endof
        $DF of
            ." DF" ."  "
            ." LD (IX+d),{s}"
            3
        endof
        $E0 of
            ." E0" ."  "
            ." LD (IX+d),{s}"
            3
        endof
        $E1 of
            ." E1" ."  "
            ." LD (IX+d),{s}"
            3
        endof
        $E2 of
            ." E2" ."  "
            ." LD (IX+d),{s}"
            3
        endof
        $E3 of
            ." E3" ."  "
            ." LD (IX+d),{s}"
            3
        endof
        $E4 of
            ." E4" ."  "
            ." LD (IX+d),{s}"
            3
        endof
        $FD of
            ." FD" ."  "
            ." LD (IY+d),{s}"
            3
        endof
        $FE of
            ." FE" ."  "
            ." LD (IY+d),{s}"
            3
        endof
        $FF of
            ." FF" ."  "
            ." LD (IY+d),{s}"
            3
        endof
        $100 of
            ." 100" ."  "
            ." LD (IY+d),{s}"
            3
        endof
        $101 of
            ." 101" ."  "
            ." LD (IY+d),{s}"
            3
        endof
        $102 of
            ." 102" ."  "
            ." LD (IY+d),{s}"
            3
        endof
        $103 of
            ." 103" ."  "
            ." LD (IY+d),{s}"
            3
        endof
        $104 of
            ." 104" ."  "
            ." LD (IY+d),{s}"
            3
        endof
        $DD of
            ." DD" ."  "
            ." ADD IX,{reg16}"
            2
        endof
        $FD of
            ." FD" ."  "
            ." ADD IY,{reg16}"
            2
        endof
        $00 of
            ." 00" ."  "
            ." RLC {r}"
            2
        endof
        $01 of
            ." 01" ."  "
            ." RLC {r}"
            2
        endof
        $02 of
            ." 02" ."  "
            ." RLC {r}"
            2
        endof
        $03 of
            ." 03" ."  "
            ." RLC {r}"
            2
        endof
        $04 of
            ." 04" ."  "
            ." RLC {r}"
            2
        endof
        $05 of
            ." 05" ."  "
            ." RLC {r}"
            2
        endof
        $06 of
            ." 06" ."  "
            ." RLC {r}"
            2
        endof
        $07 of
            ." 07" ."  "
            ." RLC {r}"
            2
        endof
        $08 of
            ." 08" ."  "
            ." RRC {r}"
            2
        endof
        $09 of
            ." 09" ."  "
            ." RRC {r}"
            2
        endof
        $0A of
            ." 0A" ."  "
            ." RRC {r}"
            2
        endof
        $0B of
            ." 0B" ."  "
            ." RRC {r}"
            2
        endof
        $0C of
            ." 0C" ."  "
            ." RRC {r}"
            2
        endof
        $0D of
            ." 0D" ."  "
            ." RRC {r}"
            2
        endof
        $0E of
            ." 0E" ."  "
            ." RRC {r}"
            2
        endof
        $0F of
            ." 0F" ."  "
            ." RRC {r}"
            2
        endof
        $10 of
            ." 10" ."  "
            ." RL {r}"
            2
        endof
        $11 of
            ." 11" ."  "
            ." RL {r}"
            2
        endof
        $12 of
            ." 12" ."  "
            ." RL {r}"
            2
        endof
        $13 of
            ." 13" ."  "
            ." RL {r}"
            2
        endof
        $14 of
            ." 14" ."  "
            ." RL {r}"
            2
        endof
        $15 of
            ." 15" ."  "
            ." RL {r}"
            2
        endof
        $16 of
            ." 16" ."  "
            ." RL {r}"
            2
        endof
        $17 of
            ." 17" ."  "
            ." RL {r}"
            2
        endof
        $18 of
            ." 18" ."  "
            ." RR {r}"
            2
        endof
        $19 of
            ." 19" ."  "
            ." RR {r}"
            2
        endof
        $1A of
            ." 1A" ."  "
            ." RR {r}"
            2
        endof
        $1B of
            ." 1B" ."  "
            ." RR {r}"
            2
        endof
        $1C of
            ." 1C" ."  "
            ." RR {r}"
            2
        endof
        $1D of
            ." 1D" ."  "
            ." RR {r}"
            2
        endof
        $1E of
            ." 1E" ."  "
            ." RR {r}"
            2
        endof
        $1F of
            ." 1F" ."  "
            ." RR {r}"
            2
        endof
        $20 of
            ." 20" ."  "
            ." SLA {r}"
            2
        endof
        $21 of
            ." 21" ."  "
            ." SLA {r}"
            2
        endof
        $22 of
            ." 22" ."  "
            ." SLA {r}"
            2
        endof
        $23 of
            ." 23" ."  "
            ." SLA {r}"
            2
        endof
        $24 of
            ." 24" ."  "
            ." SLA {r}"
            2
        endof
        $25 of
            ." 25" ."  "
            ." SLA {r}"
            2
        endof
        $26 of
            ." 26" ."  "
            ." SLA {r}"
            2
        endof
        $27 of
            ." 27" ."  "
            ." SLA {r}"
            2
        endof
        $28 of
            ." 28" ."  "
            ." SRA {r}"
            2
        endof
        $29 of
            ." 29" ."  "
            ." SRA {r}"
            2
        endof
        $2A of
            ." 2A" ."  "
            ." SRA {r}"
            2
        endof
        $2B of
            ." 2B" ."  "
            ." SRA {r}"
            2
        endof
        $2C of
            ." 2C" ."  "
            ." SRA {r}"
            2
        endof
        $2D of
            ." 2D" ."  "
            ." SRA {r}"
            2
        endof
        $2E of
            ." 2E" ."  "
            ." SRA {r}"
            2
        endof
        $2F of
            ." 2F" ."  "
            ." SRA {r}"
            2
        endof
        $38 of
            ." 38" ."  "
            ." SRL {r}"
            2
        endof
        $39 of
            ." 39" ."  "
            ." SRL {r}"
            2
        endof
        $3A of
            ." 3A" ."  "
            ." SRL {r}"
            2
        endof
        $3B of
            ." 3B" ."  "
            ." SRL {r}"
            2
        endof
        $3C of
            ." 3C" ."  "
            ." SRL {r}"
            2
        endof
        $3D of
            ." 3D" ."  "
            ." SRL {r}"
            2
        endof
        $3E of
            ." 3E" ."  "
            ." SRL {r}"
            2
        endof
        $3F of
            ." 3F" ."  "
            ." SRL {r}"
            2
        endof
        $CB of
            ." CB" ."  "
            ." BIT {b},{r}"
            2
        endof
        $CC of
            ." CC" ."  "
            ." BIT {b},{r}"
            2
        endof
        $CD of
            ." CD" ."  "
            ." BIT {b},{r}"
            2
        endof
        $CE of
            ." CE" ."  "
            ." BIT {b},{r}"
            2
        endof
        $CF of
            ." CF" ."  "
            ." BIT {b},{r}"
            2
        endof
        $D0 of
            ." D0" ."  "
            ." BIT {b},{r}"
            2
        endof
        $D1 of
            ." D1" ."  "
            ." BIT {b},{r}"
            2
        endof
        $D2 of
            ." D2" ."  "
            ." BIT {b},{r}"
            2
        endof
        $CB of
            ." CB" ."  "
            ." RES {b},{r}"
            2
        endof
        $CC of
            ." CC" ."  "
            ." RES {b},{r}"
            2
        endof
        $CD of
            ." CD" ."  "
            ." RES {b},{r}"
            2
        endof
        $CE of
            ." CE" ."  "
            ." RES {b},{r}"
            2
        endof
        $CF of
            ." CF" ."  "
            ." RES {b},{r}"
            2
        endof
        $D0 of
            ." D0" ."  "
            ." RES {b},{r}"
            2
        endof
        $D1 of
            ." D1" ."  "
            ." RES {b},{r}"
            2
        endof
        $D2 of
            ." D2" ."  "
            ." RES {b},{r}"
            2
        endof
        $CB of
            ." CB" ."  "
            ." SET {b},{r}"
            2
        endof
        $CC of
            ." CC" ."  "
            ." SET {b},{r}"
            2
        endof
        $CD of
            ." CD" ."  "
            ." SET {b},{r}"
            2
        endof
        $CE of
            ." CE" ."  "
            ." SET {b},{r}"
            2
        endof
        $CF of
            ." CF" ."  "
            ." SET {b},{r}"
            2
        endof
        $D0 of
            ." D0" ."  "
            ." SET {b},{r}"
            2
        endof
        $D1 of
            ." D1" ."  "
            ." SET {b},{r}"
            2
        endof
        $D2 of
            ." D2" ."  "
            ." SET {b},{r}"
            2
        endof
        $45 of
            ." 45" ."  "
            ." retn,"
            2
        endof
        $4D of
            ." 4D" ."  "
            ." reti,"
            2
        endof
        $67 of
            ." 67" ."  "
            ." rrd,"
            2
        endof
        $6F of
            ." 6F" ."  "
            ." rld,"
            2
        endof
        $5E of
            ." 5E" ."  "
            ." IM {imm}"
            2
        endof
        $47 of
            ." 47" ."  "
            ." ldia,"
            2
        endof
        $4F of
            ." 4F" ."  "
            ." ldra,"
            2
        endof
        $57 of
            ." 57" ."  "
            ." ldai,"
            2
        endof
        $5F of
            ." 5F" ."  "
            ." ldar,"
            2
        endof
        $40 of
            ." 40" ."  "
            ." IN {d},(C)"
            2
        endof
        $41 of
            ." 41" ."  "
            ." IN {d},(C)"
            2
        endof
        $42 of
            ." 42" ."  "
            ." IN {d},(C)"
            2
        endof
        $43 of
            ." 43" ."  "
            ." IN {d},(C)"
            2
        endof
        $44 of
            ." 44" ."  "
            ." IN {d},(C)"
            2
        endof
        $45 of
            ." 45" ."  "
            ." IN {d},(C)"
            2
        endof
        $46 of
            ." 46" ."  "
            ." IN {d},(C)"
            2
        endof
        $47 of
            ." 47" ."  "
            ." IN {d},(C)"
            2
        endof
        $41 of
            ." 41" ."  "
            ." OUT (C),{s}"
            2
        endof
        $42 of
            ." 42" ."  "
            ." OUT (C),{s}"
            2
        endof
        $43 of
            ." 43" ."  "
            ." OUT (C),{s}"
            2
        endof
        $44 of
            ." 44" ."  "
            ." OUT (C),{s}"
            2
        endof
        $45 of
            ." 45" ."  "
            ." OUT (C),{s}"
            2
        endof
        $46 of
            ." 46" ."  "
            ." OUT (C),{s}"
            2
        endof
        $47 of
            ." 47" ."  "
            ." OUT (C),{s}"
            2
        endof
        $48 of
            ." 48" ."  "
            ." OUT (C),{s}"
            2
        endof
        $42 of
            ." 42" ."  "
            ." SBC HL,{reg16}"
            2
        endof
        $4A of
            ." 4A" ."  "
            ." ADC HL,{reg16}"
            2
        endof
        $A0 of
            ." A0" ."  "
            ." ldi,"
            2
        endof
        $B0 of
            ." B0" ."  "
            ." ldir,"
            2
        endof
        $A8 of
            ." A8" ."  "
            ." ldd,"
            2
        endof
        $B8 of
            ." B8" ."  "
            ." lddr,"
            2
        endof
        $A1 of
            ." A1" ."  "
            ." cpi,"
            2
        endof
        $B1 of
            ." B1" ."  "
            ." cpir,"
            2
        endof
        $A9 of
            ." A9" ."  "
            ." cpd,"
            2
        endof
        $B9 of
            ." B9" ."  "
            ." cpdr,"
            2
        endof
        $A2 of
            ." A2" ."  "
            ." ini,"
            2
        endof
        $B2 of
            ." B2" ."  "
            ." inir,"
            2
        endof
        $AA of
            ." AA" ."  "
            ." ind,"
            2
        endof
        $BA of
            ." BA" ."  "
            ." indr,"
            2
        endof
        $A3 of
            ." A3" ."  "
            ." outi,"
            2
        endof
        $B3 of
            ." B3" ."  "
            ." otir,"
            2
        endof
        $AB of
            ." AB" ."  "
            ." outd,"
            2
        endof
        $BB of
            ." BB" ."  "
            ." otdr,"
            2
        endof
        $23 of
            ." 23" ."  "
            ." incix,"
            2
        endof
        $23 of
            ." 23" ."  "
            ." inciy,"
            2
        endof
        $2B of
            ." 2B" ."  "
            ." decix,"
            2
        endof
        $2B of
            ." 2B" ."  "
            ." deciy,"
            2
        endof
        $E5 of
            ." E5" ."  "
            ." pushix,"
            2
        endof
        $E5 of
            ." E5" ."  "
            ." pushiy,"
            2
        endof
        $E1 of
            ." E1" ."  "
            ." popix,"
            2
        endof
        $E1 of
            ." E1" ."  "
            ." popiy,"
            2
        endof
        $E9 of
            ." E9" ."  "
            ." jpix,"
            2
        endof
        $E9 of
            ." E9" ."  "
            ." jpiy,"
            2
        endof
        $F9 of
            ." F9" ."  "
            ." spix,"
            2
        endof
        $F9 of
            ." F9" ."  "
            ." spiy,"
            2
        endof
        $E3 of
            ." E3" ."  "
            ." exspix,"
            2
        endof
        $E3 of
            ." E3" ."  "
            ." exspiy,"
            2
        endof
        $3A of
            ." 3A" ."  "
            ." LD A,({addr})"
            3
        endof
        $32 of
            ." 32" ."  "
            ." LD ({addr}),A"
            3
        endof
        $22 of
            ." 22" ."  "
            ." LD ({addr}),HL"
            3
        endof
        $2A of
            ." 2A" ."  "
            ." LD HL,({addr})"
            3
        endof
        $86 of
            ." 86" ."  "
            ." addix_a_,"
            3
        endof
        $86 of
            ." 86" ."  "
            ." addiy_a_,"
            3
        endof
        $C3 of
            ." C3" ."  "
            ." JP {addr}"
            3
        endof
        $CD of
            ." CD" ."  "
            ." CALL {addr}"
            3
        endof
        $ED of
            ." ED" ."  "
            ." LD ({addr}),{reg16}"
            4
        endof
        $ED of
            ." ED" ."  "
            ." LD {reg16},({addr})"
            4
        endof
        $36 of
            ." 36" ."  "
            ." LD (IX+d),{imm}"
            4
        endof
        $36 of
            ." 36" ."  "
            ." LD (IY+d),{imm}"
            4
        endof
        $21 of
            ." 21" ."  "
            ." LD IX,{imm}"
            4
        endof
        $21 of
            ." 21" ."  "
            ." LD IY,{imm}"
            4
        endof
        $22 of
            ." 22" ."  "
            ." LD ({addr}),IX"
            4
        endof
        $22 of
            ." 22" ."  "
            ." LD ({addr}),IY"
            4
        endof
        $2A of
            ." 2A" ."  "
            ." LD IX,({addr})"
            4
        endof
        $2A of
            ." 2A" ."  "
            ." LD IY,({addr})"
            4
        endof
        $CB of
            ." CB" ."  "
            ." BIT {b},(IX+d)"
            4
        endof
        $CB of
            ." CB" ."  "
            ." BIT {b},(IY+d)"
            4
        endof
        ( default ) fasm-h2 1 dup
    endcase
    pc swap + ( pc' )
; is fasm-dis-one
