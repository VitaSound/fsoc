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
        $9508 of
            ." 9508" ."  "
            ." ret,"
            1
        endof
        $9518 of
            ." 9518" ."  "
            ." reti,"
            1
        endof
        $C000 of
            ." C000" ."  "
            ." RJMP {rel}"
            1
        endof
        $D000 of
            ." D000" ."  "
            ." RCALL {rel}"
            1
        endof
        $C00 of
            ." C00" ."  "
            ." ADD R{d},{r}"
            1
        endof
        $1C00 of
            ." 1C00" ."  "
            ." ADC R{d},{r}"
            1
        endof
        $1800 of
            ." 1800" ."  "
            ." SUB R{d},{r}"
            1
        endof
        $800 of
            ." 800" ."  "
            ." SBC R{d},{r}"
            1
        endof
        $2000 of
            ." 2000" ."  "
            ." AND R{d},{r}"
            1
        endof
        $2800 of
            ." 2800" ."  "
            ." OR R{d},{r}"
            1
        endof
        $2400 of
            ." 2400" ."  "
            ." EOR R{d},{r}"
            1
        endof
        $2C00 of
            ." 2C00" ."  "
            ." MOV R{d},{r}"
            1
        endof
        $1400 of
            ." 1400" ."  "
            ." CP R{d},{r}"
            1
        endof
        $9C00 of
            ." 9C00" ."  "
            ." MUL R{d},{r}"
            1
        endof
        $E000 of
            ." E000" ."  "
            ." LDI R{d},{imm}"
            1
        endof
        $3000 of
            ." 3000" ."  "
            ." CPI R{d},{imm}"
            1
        endof
        $9600 of
            ." 9600" ."  "
            ." ADIW R{d},{imm}"
            1
        endof
        $9700 of
            ." 9700" ."  "
            ." SBIW R{d},{imm}"
            1
        endof
        $9000 of
            ." 9000" ."  "
            ." LDS R{d},{addr}"
            2
        endof
        $9200 of
            ." 9200" ."  "
            ." STS {addr},R{r}"
            2
        endof
        $8000 of
            ." 8000" ."  "
            ." LDD R{d},Y+{q}"
            1
        endof
        $8200 of
            ." 8200" ."  "
            ." STD Y+{q},R{r}"
            1
        endof
        $900C of
            ." 900C" ."  "
            ." LD R{d},Y"
            1
        endof
        $9009 of
            ." 9009" ."  "
            ." LD R{d},Y+"
            1
        endof
        $900E of
            ." 900E" ."  "
            ." LD R{d},-Y"
            1
        endof
        $8000 of
            ." 8000" ."  "
            ." LD R{d},Z"
            1
        endof
        $9001 of
            ." 9001" ."  "
            ." LD R{d},Z+"
            1
        endof
        $9002 of
            ." 9002" ."  "
            ." LD R{d},-Z"
            1
        endof
        $8200 of
            ." 8200" ."  "
            ." ST Z,R{r}"
            1
        endof
        $9201 of
            ." 9201" ."  "
            ." ST Z+,R{r}"
            1
        endof
        $9202 of
            ." 9202" ."  "
            ." ST -Z,R{r}"
            1
        endof
        $9403 of
            ." 9403" ."  "
            ." INC R{d}"
            1
        endof
        $940A of
            ." 940A" ."  "
            ." DEC R{d}"
            1
        endof
        $C00 of
            ." C00" ."  "
            ." LSL R{d}"
            1
        endof
        $9406 of
            ." 9406" ."  "
            ." LSR R{d}"
            1
        endof
        $9405 of
            ." 9405" ."  "
            ." ASR R{d}"
            1
        endof
        $1C00 of
            ." 1C00" ."  "
            ." ROL R{d}"
            1
        endof
        $9407 of
            ." 9407" ."  "
            ." ROR R{d}"
            1
        endof
        $9400 of
            ." 9400" ."  "
            ." COM R{d}"
            1
        endof
        $9401 of
            ." 9401" ."  "
            ." NEG R{d}"
            1
        endof
        $2000 of
            ." 2000" ."  "
            ." TST R{d}"
            1
        endof
        $920F of
            ." 920F" ."  "
            ." PUSH R{r}"
            1
        endof
        $900F of
            ." 900F" ."  "
            ." POP R{d}"
            1
        endof
        $B000 of
            ." B000" ."  "
            ." IN R{d},{port}"
            1
        endof
        $B800 of
            ." B800" ."  "
            ." OUT {port},R{r}"
            1
        endof
        $9A00 of
            ." 9A00" ."  "
            ." SBI {port},{b}"
            1
        endof
        $9800 of
            ." 9800" ."  "
            ." CBI {port},{b}"
            1
        endof
        $9900 of
            ." 9900" ."  "
            ." SBIC {port},{b}"
            1
        endof
        $9B00 of
            ." 9B00" ."  "
            ." SBIS {port},{b}"
            1
        endof
        $F400 of
            ." F400" ."  "
            ." BRBC {b},{rel}"
            1
        endof
        $F000 of
            ." F000" ."  "
            ." BRBS {b},{rel}"
            1
        endof
        $F000 of
            ." F000" ."  "
            ." BREQ {rel}"
            1
        endof
        $F400 of
            ." F400" ."  "
            ." BRNE {rel}"
            1
        endof
        $F000 of
            ." F000" ."  "
            ." BRCS {rel}"
            1
        endof
        $F400 of
            ." F400" ."  "
            ." BRCC {rel}"
            1
        endof
        $F000 of
            ." F000" ."  "
            ." BRMI {rel}"
            1
        endof
        $F400 of
            ." F400" ."  "
            ." BRPL {rel}"
            1
        endof
        $F000 of
            ." F000" ."  "
            ." BRLT {rel}"
            1
        endof
        $F400 of
            ." F400" ."  "
            ." BRGE {rel}"
            1
        endof
        $F000 of
            ." F000" ."  "
            ." BRLO {rel}"
            1
        endof
        $F400 of
            ." F400" ."  "
            ." BRSH {rel}"
            1
        endof
        $9408 of
            ." 9408" ."  "
            ." sei,"
            1
        endof
        $9488 of
            ." 9488" ."  "
            ." cli,"
            1
        endof
        $9588 of
            ." 9588" ."  "
            ." sleep,"
            1
        endof
        $95A8 of
            ." 95A8" ."  "
            ." wdr,"
            1
        endof
        $95C8 of
            ." 95C8" ."  "
            ." LPM R{d},Z"
            1
        endof
        $1000 of
            ." 1000" ."  "
            ." CPSE R{d},{r}"
            1
        endof
        $100 of
            ." 100" ."  "
            ." MOVW R{d},{r}"
            1
        endof
        $400 of
            ." 400" ."  "
            ." cpc,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." clr,"
            2
        endof
        $7000 of
            ." 7000" ."  "
            ." andi,"
            2
        endof
        $6000 of
            ." 6000" ."  "
            ." ori,"
            2
        endof
        $5000 of
            ." 5000" ."  "
            ." subi,"
            2
        endof
        $4000 of
            ." 4000" ."  "
            ." sbci,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." sbr,"
            2
        endof
        $FF of
            ." FF" ."  "
            ." cbr,"
            2
        endof
        $FF of
            ." FF" ."  "
            ." ser,"
            2
        endof
        $200 of
            ." 200" ."  "
            ." muls,"
            2
        endof
        $300 of
            ." 300" ."  "
            ." mulsu,"
            2
        endof
        $308 of
            ." 308" ."  "
            ." fmul,"
            2
        endof
        $380 of
            ." 380" ."  "
            ." fmuls,"
            2
        endof
        $388 of
            ." 388" ."  "
            ." fmulsu,"
            2
        endof
        $9402 of
            ." 9402" ."  "
            ." swap,"
            2
        endof
        $9409 of
            ." 9409" ."  "
            ." ijmp,"
            2
        endof
        $9509 of
            ." 9509" ."  "
            ." icall,"
            2
        endof
        $9419 of
            ." 9419" ."  "
            ." eijmp,"
            2
        endof
        $9519 of
            ." 9519" ."  "
            ." eicall,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." brvs,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." brvc,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." brhs,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." brhc,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." brts,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." brtc,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." brie,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." brid,"
            2
        endof
        $900C of
            ." 900C" ."  "
            ." ldx,"
            2
        endof
        $900D of
            ." 900D" ."  "
            ." ldxi,"
            2
        endof
        $900E of
            ." 900E" ."  "
            ." ldxd,"
            2
        endof
        $900A of
            ." 900A" ."  "
            ." ldyd,"
            2
        endof
        $920C of
            ." 920C" ."  "
            ." stx,"
            2
        endof
        $920D of
            ." 920D" ."  "
            ." stxi,"
            2
        endof
        $920E of
            ." 920E" ."  "
            ." stxd,"
            2
        endof
        $9209 of
            ." 9209" ."  "
            ." styi,"
            2
        endof
        $920A of
            ." 920A" ."  "
            ." styd,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." lddy,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." lddz,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." stdy,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." stdz,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." sty,"
            2
        endof
        $9004 of
            ." 9004" ."  "
            ." lpmz,"
            2
        endof
        $9005 of
            ." 9005" ."  "
            ." lpmzi,"
            2
        endof
        $95D8 of
            ." 95D8" ."  "
            ." elpm,"
            2
        endof
        $9006 of
            ." 9006" ."  "
            ." elpmz,"
            2
        endof
        $9007 of
            ." 9007" ."  "
            ." elpmzi,"
            2
        endof
        $95E8 of
            ." 95E8" ."  "
            ." spm,"
            2
        endof
        $95F8 of
            ." 95F8" ."  "
            ." spmi,"
            2
        endof
        $FC00 of
            ." FC00" ."  "
            ." sbrc,"
            2
        endof
        $FE00 of
            ." FE00" ."  "
            ." sbrs,"
            2
        endof
        $F800 of
            ." F800" ."  "
            ." bld,"
            2
        endof
        $FA00 of
            ." FA00" ."  "
            ." bst,"
            2
        endof
        $9408 of
            ." 9408" ."  "
            ." bset,"
            2
        endof
        $9488 of
            ." 9488" ."  "
            ." bclr,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." sec,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." sez,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." sen,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." sev,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." ses,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." seh,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." set,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." clc,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." clz,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." cln,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." clv,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." cls,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." clh,"
            2
        endof
        $00 of
            ." 00" ."  "
            ." clt,"
            2
        endof
        $9598 of
            ." 9598" ."  "
            ." break,"
            2
        endof
        $940B of
            ." 940B" ."  "
            ." des,"
            2
        endof
        $9204 of
            ." 9204" ."  "
            ." xch,"
            2
        endof
        $9205 of
            ." 9205" ."  "
            ." las,"
            2
        endof
        $9206 of
            ." 9206" ."  "
            ." lac,"
            2
        endof
        $9207 of
            ." 9207" ."  "
            ." lat,"
            2
        endof
        ( default ) fasm-h2 1 dup
    endcase
    pc swap + ( pc' )
; is fasm-dis-one
