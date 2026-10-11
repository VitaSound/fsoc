\ fsys/fasm/8051/words.4th — MCS-51 opcodes as comma words.
\ Rn are 0..7. Direct addresses are byte constants (SFR or IRAM).

[IFUNDEF] mcs-wl
wordlist constant mcs-wl
get-current
mcs-wl set-current
mcs-wl >order

0 constant r0
1 constant r1
2 constant r2
3 constant r3
4 constant r4
5 constant r5
6 constant r6
7 constant r7

$80 constant P0
$81 constant SP
$82 constant DPL
$83 constant DPH
$87 constant PCON
$88 constant TCON
$89 constant TMOD
$8A constant TL0
$8C constant TH0
$90 constant P1
$98 constant SCON
$99 constant SBUF
$A8 constant IE
$B0 constant P3
$D0 constant PSW
$E0 constant ACC
$F0 constant B

: mcs-u8 ( u -- u )
   dup 0 256 within 0= abort" mcs: byte" ;

: mcs-rn ( u -- u )
   dup 0 8 within 0= abort" mcs: Rn" ;

: mcs-rel ( dest -- u )
   fasm-pc @ 1+ - 
   dup -128 128 within 0= abort" mcs: rel"
   $FF and ;

: db, ( u -- ) mcs-u8 fasm-emit ;
: dw, ( u -- )
   dup $FF and fasm-emit
   8 rshift fasm-emit ;

: mcs-op1 ( opc "name" -- )
   create ,
   does> ( -- ) @ fasm-emit ;

$00 mcs-op1 nop,
$22 mcs-op1 ret,
$32 mcs-op1 reti,
$A3 mcs-op1 incdp,
$E4 mcs-op1 clra,
$F4 mcs-op1 cpla,
$33 mcs-op1 rlc-a,
$23 mcs-op1 rl-a,
$03 mcs-op1 rr-a,
$13 mcs-op1 rrc-a,
$04 mcs-op1 inca,
$14 mcs-op1 deca,
$84 mcs-op1 divab,
$A4 mcs-op1 mulab,
$C4 mcs-op1 swapa,
$D4 mcs-op1 daa,
$73 mcs-op1 jmp@a+dptr,
$83 mcs-op1 movc@a+pc,
$93 mcs-op1 movc@a+dptr,
$E0 mcs-op1 movxa@dptr,
$F0 mcs-op1 movx@dptr-a,

: ljmp, ( addr -- )
   $02 fasm-emit
   dup 8 rshift fasm-emit
   $FF and fasm-emit ;

: lcall, ( addr -- )
   $12 fasm-emit
   dup 8 rshift fasm-emit
   $FF and fasm-emit ;

: sjmp, ( dest -- )
   $80 fasm-emit
   mcs-rel fasm-emit ;

: ajmp, ( addr -- )
   dup $F800 and abort" mcs: ajmp page"
   dup 8 rshift 5 lshift $01 or fasm-emit
   $FF and fasm-emit ;

: acall, ( addr -- )
   dup $F800 and abort" mcs: acall page"
   dup 8 rshift 5 lshift $11 or fasm-emit
   $FF and fasm-emit ;

: jz, ( dest -- )  $60 fasm-emit mcs-rel fasm-emit ;
: jnz, ( dest -- ) $70 fasm-emit mcs-rel fasm-emit ;
: jc, ( dest -- )  $40 fasm-emit mcs-rel fasm-emit ;
: jnc, ( dest -- ) $50 fasm-emit mcs-rel fasm-emit ;

: djnz-rn, ( rn dest -- )
   swap mcs-rn $D8 + fasm-emit
   mcs-rel fasm-emit ;

: mov-a#, ( u -- ) $74 fasm-emit mcs-u8 fasm-emit ;
: mov-rn#, ( rn u -- )
   swap mcs-rn $78 + fasm-emit mcs-u8 fasm-emit ;
: mov-di#, ( di u -- )
   $75 fasm-emit swap mcs-u8 fasm-emit mcs-u8 fasm-emit ;
: mov-a-rn, ( rn -- ) mcs-rn $E8 + fasm-emit ;
: mov-rn-a, ( rn -- ) mcs-rn $F8 + fasm-emit ;
: mov-a-di, ( di -- ) $E5 fasm-emit mcs-u8 fasm-emit ;
: mov-di-a, ( di -- ) $F5 fasm-emit mcs-u8 fasm-emit ;
: mov-di-di, ( dsrc ddst -- )
   $85 fasm-emit swap mcs-u8 fasm-emit mcs-u8 fasm-emit ;
: mov-dptr#, ( addr -- )
   $90 fasm-emit
   dup 8 rshift fasm-emit
   $FF and fasm-emit ;

: push, ( di -- ) $C0 fasm-emit mcs-u8 fasm-emit ;
: pop, ( di -- )  $D0 fasm-emit mcs-u8 fasm-emit ;

: clr-c, ( -- ) $C3 fasm-emit ;
: setb-c, ( -- ) $D3 fasm-emit ;

: add-a#, ( u -- ) $24 fasm-emit mcs-u8 fasm-emit ;
: add-a-rn, ( rn -- ) mcs-rn $28 + fasm-emit ;
: addc-a#, ( u -- ) $34 fasm-emit mcs-u8 fasm-emit ;
: addc-a-rn, ( rn -- ) mcs-rn $38 + fasm-emit ;
: subb-a#, ( u -- ) $94 fasm-emit mcs-u8 fasm-emit ;
: subb-a-rn, ( rn -- ) mcs-rn $98 + fasm-emit ;
: anl-a#, ( u -- ) $54 fasm-emit mcs-u8 fasm-emit ;
: anl-a-rn, ( rn -- ) mcs-rn $58 + fasm-emit ;
: orl-a#, ( u -- ) $44 fasm-emit mcs-u8 fasm-emit ;
: orl-a-rn, ( rn -- ) mcs-rn $48 + fasm-emit ;
: xrl-a#, ( u -- ) $64 fasm-emit mcs-u8 fasm-emit ;
: xrl-a-rn, ( rn -- ) mcs-rn $68 + fasm-emit ;
: xrl-di#, ( di u -- )
   $63 fasm-emit swap mcs-u8 fasm-emit mcs-u8 fasm-emit ;
: orl-di#, ( di u -- )
   $43 fasm-emit swap mcs-u8 fasm-emit mcs-u8 fasm-emit ;
: anl-di#, ( di u -- )
   $53 fasm-emit swap mcs-u8 fasm-emit mcs-u8 fasm-emit ;

: clr-bit, ( bit -- ) $C2 fasm-emit mcs-u8 fasm-emit ;
: setb-bit, ( bit -- ) $D2 fasm-emit mcs-u8 fasm-emit ;
: cpl-bit, ( bit -- ) $B2 fasm-emit mcs-u8 fasm-emit ;
: jnb, ( bit dest -- )
   swap $30 fasm-emit mcs-u8 fasm-emit mcs-rel fasm-emit ;
: jb, ( bit dest -- )
   swap $20 fasm-emit mcs-u8 fasm-emit mcs-rel fasm-emit ;

: cjne-a#, ( u dest -- )
   swap $B4 fasm-emit mcs-u8 fasm-emit mcs-rel fasm-emit ;

: xch-a-rn, ( rn -- ) mcs-rn $C8 + fasm-emit ;
: xch-a-di, ( di -- ) $C5 fasm-emit mcs-u8 fasm-emit ;

: inc-rn, ( rn -- ) mcs-rn $08 + fasm-emit ;
: dec-rn, ( rn -- ) mcs-rn $18 + fasm-emit ;
: inc-di, ( di -- ) $05 fasm-emit mcs-u8 fasm-emit ;
: dec-di, ( di -- ) $15 fasm-emit mcs-u8 fasm-emit ;

\ Bit addresses for P1.0 / SCON.
$90 constant P1_0
$98 constant SCON_RI
$99 constant SCON_TI

set-current
previous
[THEN]
