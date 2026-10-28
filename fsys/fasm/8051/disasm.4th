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
        $22 of
            ." 22" ."  "
            ." ret,"
            1
        endof
        $32 of
            ." 32" ."  "
            ." reti,"
            1
        endof
        $A3 of
            ." A3" ."  "
            ." incdp,"
            1
        endof
        $E4 of
            ." E4" ."  "
            ." clra,"
            1
        endof
        $F4 of
            ." F4" ."  "
            ." cpla,"
            1
        endof
        $33 of
            ." 33" ."  "
            ." rlc_a,"
            1
        endof
        $23 of
            ." 23" ."  "
            ." rl_a,"
            1
        endof
        $03 of
            ." 03" ."  "
            ." rr_a,"
            1
        endof
        $13 of
            ." 13" ."  "
            ." rrc_a,"
            1
        endof
        $04 of
            ." 04" ."  "
            ." inca,"
            1
        endof
        $14 of
            ." 14" ."  "
            ." deca,"
            1
        endof
        $84 of
            ." 84" ."  "
            ." divab,"
            1
        endof
        $A4 of
            ." A4" ."  "
            ." mulab,"
            1
        endof
        $C4 of
            ." C4" ."  "
            ." swapa,"
            1
        endof
        $D4 of
            ." D4" ."  "
            ." daa,"
            1
        endof
        $73 of
            ." 73" ."  "
            ." jmp_a_dptr,"
            1
        endof
        $83 of
            ." 83" ."  "
            ." movc_a_pc,"
            1
        endof
        $93 of
            ." 93" ."  "
            ." movc_a_dptr,"
            1
        endof
        $E0 of
            ." E0" ."  "
            ." movx_a_dptr,"
            1
        endof
        $F0 of
            ." F0" ."  "
            ." movx_dptr_a,"
            1
        endof
        $E6 of
            ." E6" ."  "
            ." mov_a_r0,"
            1
        endof
        $F6 of
            ." F6" ."  "
            ." mov_r0_a,"
            1
        endof
        $C3 of
            ." C3" ."  "
            ." clr_c,"
            1
        endof
        $D3 of
            ." D3" ."  "
            ." setb_c,"
            1
        endof
        $E8 of
            ." E8" ."  "
            ." MOV A,R{n}"
            1
        endof
        $E9 of
            ." E9" ."  "
            ." MOV A,R{n}"
            1
        endof
        $EA of
            ." EA" ."  "
            ." MOV A,R{n}"
            1
        endof
        $EB of
            ." EB" ."  "
            ." MOV A,R{n}"
            1
        endof
        $EC of
            ." EC" ."  "
            ." MOV A,R{n}"
            1
        endof
        $ED of
            ." ED" ."  "
            ." MOV A,R{n}"
            1
        endof
        $EE of
            ." EE" ."  "
            ." MOV A,R{n}"
            1
        endof
        $EF of
            ." EF" ."  "
            ." MOV A,R{n}"
            1
        endof
        $F8 of
            ." F8" ."  "
            ." MOV R{n},A"
            1
        endof
        $F9 of
            ." F9" ."  "
            ." MOV R{n},A"
            1
        endof
        $FA of
            ." FA" ."  "
            ." MOV R{n},A"
            1
        endof
        $FB of
            ." FB" ."  "
            ." MOV R{n},A"
            1
        endof
        $FC of
            ." FC" ."  "
            ." MOV R{n},A"
            1
        endof
        $FD of
            ." FD" ."  "
            ." MOV R{n},A"
            1
        endof
        $FE of
            ." FE" ."  "
            ." MOV R{n},A"
            1
        endof
        $FF of
            ." FF" ."  "
            ." MOV R{n},A"
            1
        endof
        $28 of
            ." 28" ."  "
            ." ADD A,R{n}"
            1
        endof
        $29 of
            ." 29" ."  "
            ." ADD A,R{n}"
            1
        endof
        $2A of
            ." 2A" ."  "
            ." ADD A,R{n}"
            1
        endof
        $2B of
            ." 2B" ."  "
            ." ADD A,R{n}"
            1
        endof
        $2C of
            ." 2C" ."  "
            ." ADD A,R{n}"
            1
        endof
        $2D of
            ." 2D" ."  "
            ." ADD A,R{n}"
            1
        endof
        $2E of
            ." 2E" ."  "
            ." ADD A,R{n}"
            1
        endof
        $2F of
            ." 2F" ."  "
            ." ADD A,R{n}"
            1
        endof
        $38 of
            ." 38" ."  "
            ." ADDC A,R{n}"
            1
        endof
        $39 of
            ." 39" ."  "
            ." ADDC A,R{n}"
            1
        endof
        $3A of
            ." 3A" ."  "
            ." ADDC A,R{n}"
            1
        endof
        $3B of
            ." 3B" ."  "
            ." ADDC A,R{n}"
            1
        endof
        $3C of
            ." 3C" ."  "
            ." ADDC A,R{n}"
            1
        endof
        $3D of
            ." 3D" ."  "
            ." ADDC A,R{n}"
            1
        endof
        $3E of
            ." 3E" ."  "
            ." ADDC A,R{n}"
            1
        endof
        $3F of
            ." 3F" ."  "
            ." ADDC A,R{n}"
            1
        endof
        $98 of
            ." 98" ."  "
            ." SUBB A,R{n}"
            1
        endof
        $99 of
            ." 99" ."  "
            ." SUBB A,R{n}"
            1
        endof
        $9A of
            ." 9A" ."  "
            ." SUBB A,R{n}"
            1
        endof
        $9B of
            ." 9B" ."  "
            ." SUBB A,R{n}"
            1
        endof
        $9C of
            ." 9C" ."  "
            ." SUBB A,R{n}"
            1
        endof
        $9D of
            ." 9D" ."  "
            ." SUBB A,R{n}"
            1
        endof
        $9E of
            ." 9E" ."  "
            ." SUBB A,R{n}"
            1
        endof
        $9F of
            ." 9F" ."  "
            ." SUBB A,R{n}"
            1
        endof
        $58 of
            ." 58" ."  "
            ." ANL A,R{n}"
            1
        endof
        $59 of
            ." 59" ."  "
            ." ANL A,R{n}"
            1
        endof
        $5A of
            ." 5A" ."  "
            ." ANL A,R{n}"
            1
        endof
        $5B of
            ." 5B" ."  "
            ." ANL A,R{n}"
            1
        endof
        $5C of
            ." 5C" ."  "
            ." ANL A,R{n}"
            1
        endof
        $5D of
            ." 5D" ."  "
            ." ANL A,R{n}"
            1
        endof
        $5E of
            ." 5E" ."  "
            ." ANL A,R{n}"
            1
        endof
        $5F of
            ." 5F" ."  "
            ." ANL A,R{n}"
            1
        endof
        $48 of
            ." 48" ."  "
            ." ORL A,R{n}"
            1
        endof
        $49 of
            ." 49" ."  "
            ." ORL A,R{n}"
            1
        endof
        $4A of
            ." 4A" ."  "
            ." ORL A,R{n}"
            1
        endof
        $4B of
            ." 4B" ."  "
            ." ORL A,R{n}"
            1
        endof
        $4C of
            ." 4C" ."  "
            ." ORL A,R{n}"
            1
        endof
        $4D of
            ." 4D" ."  "
            ." ORL A,R{n}"
            1
        endof
        $4E of
            ." 4E" ."  "
            ." ORL A,R{n}"
            1
        endof
        $4F of
            ." 4F" ."  "
            ." ORL A,R{n}"
            1
        endof
        $68 of
            ." 68" ."  "
            ." XRL A,R{n}"
            1
        endof
        $69 of
            ." 69" ."  "
            ." XRL A,R{n}"
            1
        endof
        $6A of
            ." 6A" ."  "
            ." XRL A,R{n}"
            1
        endof
        $6B of
            ." 6B" ."  "
            ." XRL A,R{n}"
            1
        endof
        $6C of
            ." 6C" ."  "
            ." XRL A,R{n}"
            1
        endof
        $6D of
            ." 6D" ."  "
            ." XRL A,R{n}"
            1
        endof
        $6E of
            ." 6E" ."  "
            ." XRL A,R{n}"
            1
        endof
        $6F of
            ." 6F" ."  "
            ." XRL A,R{n}"
            1
        endof
        $C8 of
            ." C8" ."  "
            ." XCH A,R{n}"
            1
        endof
        $C9 of
            ." C9" ."  "
            ." XCH A,R{n}"
            1
        endof
        $CA of
            ." CA" ."  "
            ." XCH A,R{n}"
            1
        endof
        $CB of
            ." CB" ."  "
            ." XCH A,R{n}"
            1
        endof
        $CC of
            ." CC" ."  "
            ." XCH A,R{n}"
            1
        endof
        $CD of
            ." CD" ."  "
            ." XCH A,R{n}"
            1
        endof
        $CE of
            ." CE" ."  "
            ." XCH A,R{n}"
            1
        endof
        $CF of
            ." CF" ."  "
            ." XCH A,R{n}"
            1
        endof
        $08 of
            ." 08" ."  "
            ." INC R{n}"
            1
        endof
        $09 of
            ." 09" ."  "
            ." INC R{n}"
            1
        endof
        $0A of
            ." 0A" ."  "
            ." INC R{n}"
            1
        endof
        $0B of
            ." 0B" ."  "
            ." INC R{n}"
            1
        endof
        $0C of
            ." 0C" ."  "
            ." INC R{n}"
            1
        endof
        $0D of
            ." 0D" ."  "
            ." INC R{n}"
            1
        endof
        $0E of
            ." 0E" ."  "
            ." INC R{n}"
            1
        endof
        $0F of
            ." 0F" ."  "
            ." INC R{n}"
            1
        endof
        $18 of
            ." 18" ."  "
            ." DEC R{n}"
            1
        endof
        $19 of
            ." 19" ."  "
            ." DEC R{n}"
            1
        endof
        $1A of
            ." 1A" ."  "
            ." DEC R{n}"
            1
        endof
        $1B of
            ." 1B" ."  "
            ." DEC R{n}"
            1
        endof
        $1C of
            ." 1C" ."  "
            ." DEC R{n}"
            1
        endof
        $1D of
            ." 1D" ."  "
            ." DEC R{n}"
            1
        endof
        $1E of
            ." 1E" ."  "
            ." DEC R{n}"
            1
        endof
        $1F of
            ." 1F" ."  "
            ." DEC R{n}"
            1
        endof
        $D8 of
            ." D8" ."  "
            ." DJNZ R{n},{rel}"
            2
        endof
        $D9 of
            ." D9" ."  "
            ." DJNZ R{n},{rel}"
            2
        endof
        $DA of
            ." DA" ."  "
            ." DJNZ R{n},{rel}"
            2
        endof
        $DB of
            ." DB" ."  "
            ." DJNZ R{n},{rel}"
            2
        endof
        $DC of
            ." DC" ."  "
            ." DJNZ R{n},{rel}"
            2
        endof
        $DD of
            ." DD" ."  "
            ." DJNZ R{n},{rel}"
            2
        endof
        $DE of
            ." DE" ."  "
            ." DJNZ R{n},{rel}"
            2
        endof
        $DF of
            ." DF" ."  "
            ." DJNZ R{n},{rel}"
            2
        endof
        $E5 of
            ." E5" ."  "
            ." MOV A,{direct}"
            2
        endof
        $F5 of
            ." F5" ."  "
            ." MOV {direct},A"
            2
        endof
        $C5 of
            ." C5" ."  "
            ." XCH A,{direct}"
            2
        endof
        $05 of
            ." 05" ."  "
            ." INC {direct}"
            2
        endof
        $15 of
            ." 15" ."  "
            ." DEC {direct}"
            2
        endof
        $C0 of
            ." C0" ."  "
            ." PUSH {direct}"
            2
        endof
        $D0 of
            ." D0" ."  "
            ." POP {direct}"
            2
        endof
        $74 of
            ." 74" ."  "
            ." MOV A,#{data}"
            2
        endof
        $78 of
            ." 78" ."  "
            ." MOV R{n},#{data}"
            2
        endof
        $79 of
            ." 79" ."  "
            ." MOV R{n},#{data}"
            2
        endof
        $7A of
            ." 7A" ."  "
            ." MOV R{n},#{data}"
            2
        endof
        $7B of
            ." 7B" ."  "
            ." MOV R{n},#{data}"
            2
        endof
        $7C of
            ." 7C" ."  "
            ." MOV R{n},#{data}"
            2
        endof
        $7D of
            ." 7D" ."  "
            ." MOV R{n},#{data}"
            2
        endof
        $7E of
            ." 7E" ."  "
            ." MOV R{n},#{data}"
            2
        endof
        $7F of
            ." 7F" ."  "
            ." MOV R{n},#{data}"
            2
        endof
        $75 of
            ." 75" ."  "
            ." MOV {direct},#{data}"
            3
        endof
        $85 of
            ." 85" ."  "
            ." MOV {direct},{direct}"
            3
        endof
        $24 of
            ." 24" ."  "
            ." ADD A,#{data}"
            2
        endof
        $34 of
            ." 34" ."  "
            ." ADDC A,#{data}"
            2
        endof
        $94 of
            ." 94" ."  "
            ." SUBB A,#{data}"
            2
        endof
        $54 of
            ." 54" ."  "
            ." ANL A,#{data}"
            2
        endof
        $44 of
            ." 44" ."  "
            ." ORL A,#{data}"
            2
        endof
        $64 of
            ." 64" ."  "
            ." XRL A,#{data}"
            2
        endof
        $53 of
            ." 53" ."  "
            ." ANL {direct},#{data}"
            3
        endof
        $43 of
            ." 43" ."  "
            ." ORL {direct},#{data}"
            3
        endof
        $63 of
            ." 63" ."  "
            ." XRL {direct},#{data}"
            3
        endof
        $B4 of
            ." B4" ."  "
            ." CJNE A,#{data},{rel}"
            3
        endof
        $C2 of
            ." C2" ."  "
            ." CLR {bit}"
            2
        endof
        $D2 of
            ." D2" ."  "
            ." SETB {bit}"
            2
        endof
        $B2 of
            ." B2" ."  "
            ." CPL {bit}"
            2
        endof
        $30 of
            ." 30" ."  "
            ." JNB {bit},{rel}"
            3
        endof
        $20 of
            ." 20" ."  "
            ." JB {bit},{rel}"
            3
        endof
        $80 of
            ." 80" ."  "
            ." SJMP {rel}"
            2
        endof
        $60 of
            ." 60" ."  "
            ." JZ {rel}"
            2
        endof
        $70 of
            ." 70" ."  "
            ." JNZ {rel}"
            2
        endof
        $40 of
            ." 40" ."  "
            ." JC {rel}"
            2
        endof
        $50 of
            ." 50" ."  "
            ." JNC {rel}"
            2
        endof
        $01 of
            ." 01" ."  "
            ." AJMP {addr}"
            2
        endof
        $11 of
            ." 11" ."  "
            ." ACALL {addr}"
            2
        endof
        $02 of
            ." 02" ."  "
            ." LJMP {addr}"
            3
        endof
        $12 of
            ." 12" ."  "
            ." LCALL {addr}"
            3
        endof
        $90 of
            ." 90" ."  "
            ." MOV DPTR,#{addr}"
            3
        endof
        $20 of
            ." 20" ."  "
            ." JB {bit},{rel}"
            3
        endof
        $30 of
            ." 30" ."  "
            ." JNB {bit},{rel}"
            3
        endof
        $25 of
            ." 25" ."  "
            ." ADD A,{direct}"
            2
        endof
        $35 of
            ." 35" ."  "
            ." ADDC A,{direct}"
            2
        endof
        $95 of
            ." 95" ."  "
            ." SUBB A,{direct}"
            2
        endof
        $26 of
            ." 26" ."  "
            ." add_a_r0i,"
            1
        endof
        $27 of
            ." 27" ."  "
            ." add_a_r1i,"
            1
        endof
        $36 of
            ." 36" ."  "
            ." addc_a_r0i,"
            1
        endof
        $37 of
            ." 37" ."  "
            ." addc_a_r1i,"
            1
        endof
        $96 of
            ." 96" ."  "
            ." subb_a_r0i,"
            1
        endof
        $97 of
            ." 97" ."  "
            ." subb_a_r1i,"
            1
        endof
        $06 of
            ." 06" ."  "
            ." inc_r0i,"
            1
        endof
        $07 of
            ." 07" ."  "
            ." inc_r1i,"
            1
        endof
        $16 of
            ." 16" ."  "
            ." dec_r0i,"
            1
        endof
        $17 of
            ." 17" ."  "
            ." dec_r1i,"
            1
        endof
        $55 of
            ." 55" ."  "
            ." ANL A,{direct}"
            2
        endof
        $45 of
            ." 45" ."  "
            ." ORL A,{direct}"
            2
        endof
        $65 of
            ." 65" ."  "
            ." XRL A,{direct}"
            2
        endof
        $52 of
            ." 52" ."  "
            ." ANL {direct},A"
            2
        endof
        $42 of
            ." 42" ."  "
            ." ORL {direct},A"
            2
        endof
        $62 of
            ." 62" ."  "
            ." XRL {direct},A"
            2
        endof
        $56 of
            ." 56" ."  "
            ." anl_a_r0i,"
            1
        endof
        $57 of
            ." 57" ."  "
            ." anl_a_r1i,"
            1
        endof
        $46 of
            ." 46" ."  "
            ." orl_a_r0i,"
            1
        endof
        $47 of
            ." 47" ."  "
            ." orl_a_r1i,"
            1
        endof
        $66 of
            ." 66" ."  "
            ." xrl_a_r0i,"
            1
        endof
        $67 of
            ." 67" ."  "
            ." xrl_a_r1i,"
            1
        endof
        $E6 of
            ." E6" ."  "
            ." mov_a_r0i,"
            1
        endof
        $E7 of
            ." E7" ."  "
            ." mov_a_r1i,"
            1
        endof
        $A8 of
            ." A8" ."  "
            ." MOV R{n},{direct}"
            2
        endof
        $A9 of
            ." A9" ."  "
            ." MOV R{n},{direct}"
            2
        endof
        $AA of
            ." AA" ."  "
            ." MOV R{n},{direct}"
            2
        endof
        $AB of
            ." AB" ."  "
            ." MOV R{n},{direct}"
            2
        endof
        $AC of
            ." AC" ."  "
            ." MOV R{n},{direct}"
            2
        endof
        $AD of
            ." AD" ."  "
            ." MOV R{n},{direct}"
            2
        endof
        $AE of
            ." AE" ."  "
            ." MOV R{n},{direct}"
            2
        endof
        $AF of
            ." AF" ."  "
            ." MOV R{n},{direct}"
            2
        endof
        $88 of
            ." 88" ."  "
            ." MOV {direct},R{n}"
            2
        endof
        $89 of
            ." 89" ."  "
            ." MOV {direct},R{n}"
            2
        endof
        $8A of
            ." 8A" ."  "
            ." MOV {direct},R{n}"
            2
        endof
        $8B of
            ." 8B" ."  "
            ." MOV {direct},R{n}"
            2
        endof
        $8C of
            ." 8C" ."  "
            ." MOV {direct},R{n}"
            2
        endof
        $8D of
            ." 8D" ."  "
            ." MOV {direct},R{n}"
            2
        endof
        $8E of
            ." 8E" ."  "
            ." MOV {direct},R{n}"
            2
        endof
        $8F of
            ." 8F" ."  "
            ." MOV {direct},R{n}"
            2
        endof
        $86 of
            ." 86" ."  "
            ." MOV {direct},@R0"
            2
        endof
        $87 of
            ." 87" ."  "
            ." MOV {direct},@R1"
            2
        endof
        $F6 of
            ." F6" ."  "
            ." mov_r0i_a,"
            1
        endof
        $F7 of
            ." F7" ."  "
            ." mov_r1i_a,"
            1
        endof
        $A6 of
            ." A6" ."  "
            ." MOV @R0,{direct}"
            2
        endof
        $A7 of
            ." A7" ."  "
            ." MOV @R1,{direct}"
            2
        endof
        $76 of
            ." 76" ."  "
            ." MOV @R0,#{data}"
            2
        endof
        $77 of
            ." 77" ."  "
            ." MOV @R1,#{data}"
            2
        endof
        $E2 of
            ." E2" ."  "
            ." movx_a_r0i,"
            1
        endof
        $E3 of
            ." E3" ."  "
            ." movx_a_r1i,"
            1
        endof
        $F2 of
            ." F2" ."  "
            ." movx_r0i_a,"
            1
        endof
        $F3 of
            ." F3" ."  "
            ." movx_r1i_a,"
            1
        endof
        $C6 of
            ." C6" ."  "
            ." xch_a_r0i,"
            1
        endof
        $C7 of
            ." C7" ."  "
            ." xch_a_r1i,"
            1
        endof
        $D6 of
            ." D6" ."  "
            ." xchd_a_r0i,"
            1
        endof
        $D7 of
            ." D7" ."  "
            ." xchd_a_r1i,"
            1
        endof
        $B3 of
            ." B3" ."  "
            ." cpl_c,"
            1
        endof
        $82 of
            ." 82" ."  "
            ." ANL C,{bit}"
            2
        endof
        $B0 of
            ." B0" ."  "
            ." ANL C,/{bit}"
            2
        endof
        $72 of
            ." 72" ."  "
            ." ORL C,{bit}"
            2
        endof
        $A0 of
            ." A0" ."  "
            ." ORL C,/{bit}"
            2
        endof
        $A2 of
            ." A2" ."  "
            ." MOV C,{bit}"
            2
        endof
        $92 of
            ." 92" ."  "
            ." MOV {bit},C"
            2
        endof
        $10 of
            ." 10" ."  "
            ." JBC {bit},{rel}"
            3
        endof
        $B5 of
            ." B5" ."  "
            ." CJNE A,{direct},{rel}"
            3
        endof
        $B8 of
            ." B8" ."  "
            ." CJNE R{n},#{data},{rel}"
            3
        endof
        $B9 of
            ." B9" ."  "
            ." CJNE R{n},#{data},{rel}"
            3
        endof
        $BA of
            ." BA" ."  "
            ." CJNE R{n},#{data},{rel}"
            3
        endof
        $BB of
            ." BB" ."  "
            ." CJNE R{n},#{data},{rel}"
            3
        endof
        $BC of
            ." BC" ."  "
            ." CJNE R{n},#{data},{rel}"
            3
        endof
        $BD of
            ." BD" ."  "
            ." CJNE R{n},#{data},{rel}"
            3
        endof
        $BE of
            ." BE" ."  "
            ." CJNE R{n},#{data},{rel}"
            3
        endof
        $BF of
            ." BF" ."  "
            ." CJNE R{n},#{data},{rel}"
            3
        endof
        $B6 of
            ." B6" ."  "
            ." CJNE @R0,#{data},{rel}"
            3
        endof
        $B7 of
            ." B7" ."  "
            ." CJNE @R1,#{data},{rel}"
            3
        endof
        $D5 of
            ." D5" ."  "
            ." DJNZ {direct},{rel}"
            3
        endof
        ( default ) fasm-h2 1 dup
    endcase
    pc swap + ( pc' )
; is fasm-dis-one
