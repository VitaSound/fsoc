\ fsys/fasm/mcs51/disasm.4th — auto-generated from ISA spec.
\ Defines fasm-dis-one for the common disasm engine.

include ../common/fasm-dis.4th

:noname ( pc -- pc' )
    { pc } pc fasm@ ( opcode )
    case
        $00 of
            ." 00" ."  "
            ." NOP"
            1
        endof
        $22 of
            ." 22" ."  "
            ." RET"
            1
        endof
        $32 of
            ." 32" ."  "
            ." RETI"
            1
        endof
        $A3 of
            ." A3" ."  "
            ." INC DPTR"
            1
        endof
        $E4 of
            ." E4" ."  "
            ." CLR A"
            1
        endof
        $F4 of
            ." F4" ."  "
            ." CPL A"
            1
        endof
        $33 of
            ." 33" ."  "
            ." RLC A"
            1
        endof
        $23 of
            ." 23" ."  "
            ." RL A"
            1
        endof
        $03 of
            ." 03" ."  "
            ." RR A"
            1
        endof
        $13 of
            ." 13" ."  "
            ." RRC A"
            1
        endof
        $04 of
            ." 04" ."  "
            ." INC A"
            1
        endof
        $14 of
            ." 14" ."  "
            ." DEC A"
            1
        endof
        $84 of
            ." 84" ."  "
            ." DIV AB"
            1
        endof
        $A4 of
            ." A4" ."  "
            ." MUL AB"
            1
        endof
        $C4 of
            ." C4" ."  "
            ." SWAP A"
            1
        endof
        $D4 of
            ." D4" ."  "
            ." DA A"
            1
        endof
        $73 of
            ." 73" ."  "
            ." JMP @A+DPTR"
            1
        endof
        $83 of
            ." 83" ."  "
            ." MOVC A,@A+PC"
            1
        endof
        $93 of
            ." 93" ."  "
            ." MOVC A,@A+DPTR"
            1
        endof
        $E0 of
            ." E0" ."  "
            ." MOVX A,@DPTR"
            1
        endof
        $F0 of
            ." F0" ."  "
            ." MOVX @DPTR,A"
            1
        endof
        $E6 of
            ." E6" ."  "
            ." MOV A,@R0"
            1
        endof
        $F6 of
            ." F6" ."  "
            ." MOV @R0,A"
            1
        endof
        $C3 of
            ." C3" ."  "
            ." CLR C"
            1
        endof
        $D3 of
            ." D3" ."  "
            ." SETB C"
            1
        endof
        $E8 of
            ." E8" ."  "
            ." MOV A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $E9 of
            ." E9" ."  "
            ." MOV A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $EA of
            ." EA" ."  "
            ." MOV A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $EB of
            ." EB" ."  "
            ." MOV A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $EC of
            ." EC" ."  "
            ." MOV A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $ED of
            ." ED" ."  "
            ." MOV A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $EE of
            ." EE" ."  "
            ." MOV A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $EF of
            ." EF" ."  "
            ." MOV A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $F8 of
            ." F8" ."  "
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,A"
            1
        endof
        $F9 of
            ." F9" ."  "
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,A"
            1
        endof
        $FA of
            ." FA" ."  "
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,A"
            1
        endof
        $FB of
            ." FB" ."  "
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,A"
            1
        endof
        $FC of
            ." FC" ."  "
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,A"
            1
        endof
        $FD of
            ." FD" ."  "
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,A"
            1
        endof
        $FE of
            ." FE" ."  "
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,A"
            1
        endof
        $FF of
            ." FF" ."  "
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,A"
            1
        endof
        $28 of
            ." 28" ."  "
            ." ADD A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $29 of
            ." 29" ."  "
            ." ADD A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $2A of
            ." 2A" ."  "
            ." ADD A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $2B of
            ." 2B" ."  "
            ." ADD A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $2C of
            ." 2C" ."  "
            ." ADD A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $2D of
            ." 2D" ."  "
            ." ADD A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $2E of
            ." 2E" ."  "
            ." ADD A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $2F of
            ." 2F" ."  "
            ." ADD A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $38 of
            ." 38" ."  "
            ." ADDC A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $39 of
            ." 39" ."  "
            ." ADDC A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $3A of
            ." 3A" ."  "
            ." ADDC A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $3B of
            ." 3B" ."  "
            ." ADDC A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $3C of
            ." 3C" ."  "
            ." ADDC A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $3D of
            ." 3D" ."  "
            ." ADDC A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $3E of
            ." 3E" ."  "
            ." ADDC A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $3F of
            ." 3F" ."  "
            ." ADDC A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $98 of
            ." 98" ."  "
            ." SUBB A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $99 of
            ." 99" ."  "
            ." SUBB A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $9A of
            ." 9A" ."  "
            ." SUBB A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $9B of
            ." 9B" ."  "
            ." SUBB A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $9C of
            ." 9C" ."  "
            ." SUBB A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $9D of
            ." 9D" ."  "
            ." SUBB A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $9E of
            ." 9E" ."  "
            ." SUBB A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $9F of
            ." 9F" ."  "
            ." SUBB A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $58 of
            ." 58" ."  "
            ." ANL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $59 of
            ." 59" ."  "
            ." ANL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $5A of
            ." 5A" ."  "
            ." ANL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $5B of
            ." 5B" ."  "
            ." ANL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $5C of
            ." 5C" ."  "
            ." ANL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $5D of
            ." 5D" ."  "
            ." ANL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $5E of
            ." 5E" ."  "
            ." ANL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $5F of
            ." 5F" ."  "
            ." ANL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $48 of
            ." 48" ."  "
            ." ORL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $49 of
            ." 49" ."  "
            ." ORL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $4A of
            ." 4A" ."  "
            ." ORL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $4B of
            ." 4B" ."  "
            ." ORL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $4C of
            ." 4C" ."  "
            ." ORL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $4D of
            ." 4D" ."  "
            ." ORL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $4E of
            ." 4E" ."  "
            ." ORL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $4F of
            ." 4F" ."  "
            ." ORL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $68 of
            ." 68" ."  "
            ." XRL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $69 of
            ." 69" ."  "
            ." XRL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $6A of
            ." 6A" ."  "
            ." XRL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $6B of
            ." 6B" ."  "
            ." XRL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $6C of
            ." 6C" ."  "
            ." XRL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $6D of
            ." 6D" ."  "
            ." XRL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $6E of
            ." 6E" ."  "
            ." XRL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $6F of
            ." 6F" ."  "
            ." XRL A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $C8 of
            ." C8" ."  "
            ." XCH A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $C9 of
            ." C9" ."  "
            ." XCH A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $CA of
            ." CA" ."  "
            ." XCH A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $CB of
            ." CB" ."  "
            ." XCH A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $CC of
            ." CC" ."  "
            ." XCH A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $CD of
            ." CD" ."  "
            ." XCH A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $CE of
            ." CE" ."  "
            ." XCH A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $CF of
            ." CF" ."  "
            ." XCH A,R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $08 of
            ." 08" ."  "
            ." INC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $09 of
            ." 09" ."  "
            ." INC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $0A of
            ." 0A" ."  "
            ." INC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $0B of
            ." 0B" ."  "
            ." INC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $0C of
            ." 0C" ."  "
            ." INC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $0D of
            ." 0D" ."  "
            ." INC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $0E of
            ." 0E" ."  "
            ." INC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $0F of
            ." 0F" ."  "
            ." INC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $18 of
            ." 18" ."  "
            ." DEC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $19 of
            ." 19" ."  "
            ." DEC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $1A of
            ." 1A" ."  "
            ." DEC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $1B of
            ." 1B" ."  "
            ." DEC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $1C of
            ." 1C" ."  "
            ." DEC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $1D of
            ." 1D" ."  "
            ." DEC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $1E of
            ." 1E" ."  "
            ." DEC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $1F of
            ." 1F" ."  "
            ." DEC R"
            pc fasm@ 7 and [char] 0 + emit
            1
        endof
        $D8 of
            ." D8" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DJNZ R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $D9 of
            ." D9" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DJNZ R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $DA of
            ." DA" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DJNZ R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $DB of
            ." DB" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DJNZ R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $DC of
            ." DC" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DJNZ R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $DD of
            ." DD" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DJNZ R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $DE of
            ." DE" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DJNZ R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $DF of
            ." DF" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DJNZ R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $E5 of
            ." E5" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV A,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $F5 of
            ." F5" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,A"
            2
        endof
        $C5 of
            ." C5" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." XCH A,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $05 of
            ." 05" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." INC "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $15 of
            ." 15" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." DEC "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $C0 of
            ." C0" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." PUSH "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $D0 of
            ." D0" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." POP "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $74 of
            ." 74" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV A,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $78 of
            ." 78" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $79 of
            ." 79" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $7A of
            ." 7A" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $7B of
            ." 7B" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $7C of
            ." 7C" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $7D of
            ." 7D" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $7E of
            ." 7E" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $7F of
            ." 7F" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $75 of
            ." 75" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,#"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $85 of
            ." 85" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $24 of
            ." 24" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ADD A,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $34 of
            ." 34" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ADDC A,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $94 of
            ." 94" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." SUBB A,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $54 of
            ." 54" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ANL A,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $44 of
            ." 44" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ORL A,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $64 of
            ." 64" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." XRL A,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $53 of
            ." 53" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." ANL "
            pc 1 + fasm@ fasm-h2
            ." ,#"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $43 of
            ." 43" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." ORL "
            pc 1 + fasm@ fasm-h2
            ." ,#"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $63 of
            ." 63" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." XRL "
            pc 1 + fasm@ fasm-h2
            ." ,#"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $B4 of
            ." B4" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE A,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $C2 of
            ." C2" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." CLR "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $D2 of
            ." D2" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." SETB "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $B2 of
            ." B2" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." CPL "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $30 of
            ." 30" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." JNB "
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $20 of
            ." 20" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." JB "
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $80 of
            ." 80" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." SJMP "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $60 of
            ." 60" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." JZ "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $70 of
            ." 70" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." JNZ "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $40 of
            ." 40" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." JC "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $50 of
            ." 50" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." JNC "
            pc 1 + fasm@ fasm-h2
            2
        endof
        $01 of
            ." 01" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." AJMP "
            pc 1 + fasm@ 8 lshift pc 2 + fasm@ or fasm-h4
            2
        endof
        $11 of
            ." 11" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." ACALL "
            pc 1 + fasm@ 8 lshift pc 2 + fasm@ or fasm-h4
            2
        endof
        $02 of
            ." 02" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." LJMP "
            pc 1 + fasm@ 8 lshift pc 2 + fasm@ or fasm-h4
            3
        endof
        $12 of
            ." 12" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." LCALL "
            pc 1 + fasm@ 8 lshift pc 2 + fasm@ or fasm-h4
            3
        endof
        $90 of
            ." 90" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." MOV DPTR,#"
            pc 1 + fasm@ 8 lshift pc 2 + fasm@ or fasm-h4
            3
        endof
        $20 of
            ." 20" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." JB "
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $30 of
            ." 30" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." JNB "
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $25 of
            ." 25" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ADD A,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $35 of
            ." 35" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ADDC A,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $95 of
            ." 95" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." SUBB A,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $26 of
            ." 26" ."  "
            ." ADD A,@R0"
            1
        endof
        $27 of
            ." 27" ."  "
            ." ADD A,@R1"
            1
        endof
        $36 of
            ." 36" ."  "
            ." ADDC A,@R0"
            1
        endof
        $37 of
            ." 37" ."  "
            ." ADDC A,@R1"
            1
        endof
        $96 of
            ." 96" ."  "
            ." SUBB A,@R0"
            1
        endof
        $97 of
            ." 97" ."  "
            ." SUBB A,@R1"
            1
        endof
        $06 of
            ." 06" ."  "
            ." INC @R0"
            1
        endof
        $07 of
            ." 07" ."  "
            ." INC @R1"
            1
        endof
        $16 of
            ." 16" ."  "
            ." DEC @R0"
            1
        endof
        $17 of
            ." 17" ."  "
            ." DEC @R1"
            1
        endof
        $55 of
            ." 55" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ANL A,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $45 of
            ." 45" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ORL A,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $65 of
            ." 65" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." XRL A,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $52 of
            ." 52" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ANL "
            pc 1 + fasm@ fasm-h2
            ." ,A"
            2
        endof
        $42 of
            ." 42" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ORL "
            pc 1 + fasm@ fasm-h2
            ." ,A"
            2
        endof
        $62 of
            ." 62" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." XRL "
            pc 1 + fasm@ fasm-h2
            ." ,A"
            2
        endof
        $56 of
            ." 56" ."  "
            ." ANL A,@R0"
            1
        endof
        $57 of
            ." 57" ."  "
            ." ANL A,@R1"
            1
        endof
        $46 of
            ." 46" ."  "
            ." ORL A,@R0"
            1
        endof
        $47 of
            ." 47" ."  "
            ." ORL A,@R1"
            1
        endof
        $66 of
            ." 66" ."  "
            ." XRL A,@R0"
            1
        endof
        $67 of
            ." 67" ."  "
            ." XRL A,@R1"
            1
        endof
        $E6 of
            ." E6" ."  "
            ." MOV A,@R0"
            1
        endof
        $E7 of
            ." E7" ."  "
            ." MOV A,@R1"
            1
        endof
        $A8 of
            ." A8" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $A9 of
            ." A9" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $AA of
            ." AA" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $AB of
            ." AB" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $AC of
            ." AC" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $AD of
            ." AD" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $AE of
            ." AE" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $AF of
            ." AF" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $88 of
            ." 88" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,R"
            pc fasm@ 7 and [char] 0 + emit
            2
        endof
        $89 of
            ." 89" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,R"
            pc fasm@ 7 and [char] 0 + emit
            2
        endof
        $8A of
            ." 8A" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,R"
            pc fasm@ 7 and [char] 0 + emit
            2
        endof
        $8B of
            ." 8B" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,R"
            pc fasm@ 7 and [char] 0 + emit
            2
        endof
        $8C of
            ." 8C" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,R"
            pc fasm@ 7 and [char] 0 + emit
            2
        endof
        $8D of
            ." 8D" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,R"
            pc fasm@ 7 and [char] 0 + emit
            2
        endof
        $8E of
            ." 8E" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,R"
            pc fasm@ 7 and [char] 0 + emit
            2
        endof
        $8F of
            ." 8F" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,R"
            pc fasm@ 7 and [char] 0 + emit
            2
        endof
        $86 of
            ." 86" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,@R0"
            2
        endof
        $87 of
            ." 87" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,@R1"
            2
        endof
        $F6 of
            ." F6" ."  "
            ." MOV @R0,A"
            1
        endof
        $F7 of
            ." F7" ."  "
            ." MOV @R1,A"
            1
        endof
        $A6 of
            ." A6" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV @R0,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $A7 of
            ." A7" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV @R1,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $76 of
            ." 76" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV @R0,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $77 of
            ." 77" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV @R1,#"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $E2 of
            ." E2" ."  "
            ." MOVX A,@R0"
            1
        endof
        $E3 of
            ." E3" ."  "
            ." MOVX A,@R1"
            1
        endof
        $F2 of
            ." F2" ."  "
            ." MOVX @R0,A"
            1
        endof
        $F3 of
            ." F3" ."  "
            ." MOVX @R1,A"
            1
        endof
        $C6 of
            ." C6" ."  "
            ." XCH A,@R0"
            1
        endof
        $C7 of
            ." C7" ."  "
            ." XCH A,@R1"
            1
        endof
        $D6 of
            ." D6" ."  "
            ." XCHD A,@R0"
            1
        endof
        $D7 of
            ." D7" ."  "
            ." XCHD A,@R1"
            1
        endof
        $B3 of
            ." B3" ."  "
            ." CPL C"
            1
        endof
        $82 of
            ." 82" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ANL C,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $B0 of
            ." B0" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ANL C,/"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $72 of
            ." 72" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ORL C,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $A0 of
            ." A0" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." ORL C,/"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $A2 of
            ." A2" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV C,"
            pc 1 + fasm@ fasm-h2
            2
        endof
        $92 of
            ." 92" ."  "
            pc 1 + fasm@ fasm-h2 space
            ." MOV "
            pc 1 + fasm@ fasm-h2
            ." ,C"
            2
        endof
        $10 of
            ." 10" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." JBC "
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $B5 of
            ." B5" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE A,"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $B8 of
            ." B8" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $B9 of
            ." B9" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $BA of
            ." BA" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $BB of
            ." BB" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $BC of
            ." BC" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $BD of
            ." BD" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $BE of
            ." BE" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $BF of
            ." BF" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE R"
            pc fasm@ 7 and [char] 0 + emit
            ." ,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $B6 of
            ." B6" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE @R0,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $B7 of
            ." B7" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." CJNE @R1,#"
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        $D5 of
            ." D5" ."  "
            pc 1 + fasm@ fasm-h2 space
            pc 2 + fasm@ fasm-h2 space
            ." DJNZ "
            pc 1 + fasm@ fasm-h2
            ." ,"
            pc 2 + fasm@ fasm-h2
            3
        endof
        ( default ) pc fasm@ fasm-h2 1
    endcase
    pc swap + ( pc' )
; is fasm-dis-one
