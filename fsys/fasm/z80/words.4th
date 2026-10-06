\ fsys/fasm/z80/words.4th — documented Z80 opcodes as comma words.
\ Operand order matches the Intel line, TOS on the right: b c ld, is ld b,c.
\ Immediate and absolute addresses are little-endian. Relatives abort outside
\ a signed byte. The wordlist stays off the search order; put z80-wl on the
\ order only around [asm].

[IFUNDEF] z80-wl
wordlist constant z80-wl
get-current
z80-wl set-current
z80-wl >order

0 constant b
1 constant c
2 constant d
3 constant e
4 constant h
5 constant l
7 constant a

0 constant bc
1 constant de
2 constant hl
3 constant sp
3 constant af

0 constant nz
1 constant z
2 constant nc
3 constant cy
4 constant po
5 constant pe
6 constant p
7 constant m

: z80-r ( u -- u )
   dup 0 8 within 0= abort" z80: register"
   dup 6 = abort" z80: register" ;

: z80-rhl ( u -- u )
   dup 0 8 within 0= abort" z80: register" ;

: z80-rp ( u -- u )
   dup 0 4 within 0= abort" z80: pair" ;

: z80-cc ( u -- u )
   dup 0 8 within 0= abort" z80: condition" ;

: z80-u8 ( u -- u )
   dup 0 256 within 0= abort" z80: byte" ;

: z80-u16 ( u -- u )
   dup 0 65536 within 0= abort" z80: word" ;

: z80-bit ( u -- u )
   dup 0 8 within 0= abort" z80: bit" ;

: z80-disp ( n -- u )
   dup -128 128 within 0= abort" z80: displacement"
   $FF and ;

: z80-rel ( dest -- u )
   fasm-pc @ 1+ -  z80-disp ;

: z80-b, ( u -- )  z80-u8 fasm-emit ;
: z80-w, ( u -- )
   z80-u16
   dup $FF and fasm-emit
   8 rshift fasm-emit ;

: z80-op1 ( opc "name" -- )
   create ,
   does> ( -- ) @ fasm-emit ;

\ ---- one-byte fixed ----
$00 z80-op1 nop,
$76 z80-op1 halt,
$F3 z80-op1 di,
$FB z80-op1 ei,
$07 z80-op1 rlca,
$0F z80-op1 rrca,
$17 z80-op1 rla,
$1F z80-op1 rra,
$27 z80-op1 daa,
$2F z80-op1 cpl,
$37 z80-op1 scf,
$3F z80-op1 ccf,
$08 z80-op1 exaf,
$D9 z80-op1 exx,
$EB z80-op1 exde,
$E3 z80-op1 exsp,
$F9 z80-op1 sphl,
$E9 z80-op1 jphl,

: db, ( u -- ) z80-b, ;
: dw, ( u -- ) z80-w, ;

\ ---- 8-bit register / (HL) ----
: ld, ( rd rs -- )
   z80-rhl { rs }
   z80-rhl { rd }
   rd 6 = rs 6 = and abort" z80: ld (hl),(hl)"
   $40 rd 3 lshift or rs or fasm-emit ;

: ld#, ( rd n -- )
   z80-u8 { n }
   z80-rhl { rd }
   $06 rd 3 lshift or fasm-emit
   n fasm-emit ;

: incr, ( r -- )
   z80-rhl 3 lshift $04 or fasm-emit ;

: decr, ( r -- )
   z80-rhl 3 lshift $05 or fasm-emit ;

: add, ( r -- ) z80-rhl $80 or fasm-emit ;
: adc, ( r -- ) z80-rhl $88 or fasm-emit ;
: sub, ( r -- ) z80-rhl $90 or fasm-emit ;
: sbc, ( r -- ) z80-rhl $98 or fasm-emit ;
: and, ( r -- ) z80-rhl $A0 or fasm-emit ;
: xor, ( r -- ) z80-rhl $A8 or fasm-emit ;
: or,  ( r -- ) z80-rhl $B0 or fasm-emit ;
: cp,  ( r -- ) z80-rhl $B8 or fasm-emit ;

: add#, ( n -- ) $C6 fasm-emit z80-b, ;
: adc#, ( n -- ) $CE fasm-emit z80-b, ;
: sub#, ( n -- ) $D6 fasm-emit z80-b, ;
: sbc#, ( n -- ) $DE fasm-emit z80-b, ;
: and#, ( n -- ) $E6 fasm-emit z80-b, ;
: xor#, ( n -- ) $EE fasm-emit z80-b, ;
: or#,  ( n -- ) $F6 fasm-emit z80-b, ;
: cp#,  ( n -- ) $FE fasm-emit z80-b, ;

\ ---- A / BC / DE / absolute ----
: a@bc, ( -- ) $0A fasm-emit ;
: a@de, ( -- ) $1A fasm-emit ;
: bc!a, ( -- ) $02 fasm-emit ;
: de!a, ( -- ) $12 fasm-emit ;
: a@, ( nn -- ) $3A fasm-emit z80-w, ;
: !a, ( nn -- ) $32 fasm-emit z80-w, ;

\ ---- 16-bit ----
: ldw, ( rp nn -- )
   z80-u16 { nn }
   z80-rp { rp }
   $01 rp 4 lshift or fasm-emit
   nn z80-w, ;

: !hl, ( nn -- ) $22 fasm-emit z80-w, ;
: hl@, ( nn -- ) $2A fasm-emit z80-w, ;

: inc, ( rp -- ) z80-rp 4 lshift $03 or fasm-emit ;
: dec, ( rp -- ) z80-rp 4 lshift $0B or fasm-emit ;
: addhl, ( rp -- ) z80-rp 4 lshift $09 or fasm-emit ;

\ Field 3 is AF for push/pop and SP for addhl, / ldw,.
: push, ( rp -- ) z80-rp 4 lshift $C5 or fasm-emit ;
: pop,  ( rp -- ) z80-rp 4 lshift $C1 or fasm-emit ;

\ ---- jumps / calls ----
: jp, ( nn -- ) $C3 fasm-emit z80-w, ;
: jpcc, ( cc nn -- )
   z80-u16 { nn }
   z80-cc { cc }
   $C2 cc 3 lshift or fasm-emit
   nn z80-w, ;

: call, ( nn -- ) $CD fasm-emit z80-w, ;
: callcc, ( cc nn -- )
   z80-u16 { nn }
   z80-cc { cc }
   $C4 cc 3 lshift or fasm-emit
   nn z80-w, ;

: ret, ( -- ) $C9 fasm-emit ;
: retcc, ( cc -- )
   z80-cc 3 lshift $C0 or fasm-emit ;

: rst, ( n -- )
   dup 0 8 within 0= abort" z80: rst"
   3 lshift $C7 or fasm-emit ;

: jr, ( dest -- )
   $18 fasm-emit
   z80-rel fasm-emit ;

: jrnz, ( dest -- )
   $20 fasm-emit
   z80-rel fasm-emit ;

: jrz, ( dest -- )
   $28 fasm-emit
   z80-rel fasm-emit ;

: jrnc, ( dest -- )
   $30 fasm-emit
   z80-rel fasm-emit ;

: jrc, ( dest -- )
   $38 fasm-emit
   z80-rel fasm-emit ;

: djnz, ( dest -- )
   $10 fasm-emit
   z80-rel fasm-emit ;

\ ---- I/O ----
: ina, ( n -- ) $DB fasm-emit z80-b, ;
: outa, ( n -- ) $D3 fasm-emit z80-b, ;

\ ---- CB prefix ----
: z80-cb ( opc r -- )
   z80-rhl swap $CB fasm-emit or fasm-emit ;

: rlc, ( r -- )  $00 z80-cb ;
: rrc, ( r -- )  $08 z80-cb ;
: rl,  ( r -- )  $10 z80-cb ;
: rr,  ( r -- )  $18 z80-cb ;
: sla, ( r -- )  $20 z80-cb ;
: sra, ( r -- )  $28 z80-cb ;
: srl, ( r -- )  $38 z80-cb ;

: bit, ( b r -- )
   z80-rhl { r }
   z80-bit { b }
   $CB fasm-emit
   $40 b 3 lshift or r or fasm-emit ;

: res, ( b r -- )
   z80-rhl { r }
   z80-bit { b }
   $CB fasm-emit
   $80 b 3 lshift or r or fasm-emit ;

: set, ( b r -- )
   z80-rhl { r }
   z80-bit { b }
   $CB fasm-emit
   $C0 b 3 lshift or r or fasm-emit ;

\ ---- ED prefix ----
: z80-ed1 ( opc -- ) $ED fasm-emit fasm-emit ;

: neg,  ( -- ) $44 z80-ed1 ;
: retn, ( -- ) $45 z80-ed1 ;
: reti, ( -- ) $4D z80-ed1 ;
: rrd,  ( -- ) $67 z80-ed1 ;
: rld,  ( -- ) $6F z80-ed1 ;

: im, ( n -- )
   dup 0 = if drop $46 z80-ed1 exit then
   dup 1 = if drop $56 z80-ed1 exit then
   dup 2 = if drop $5E z80-ed1 exit then
   abort" z80: im" ;

: ldia, ( -- ) $47 z80-ed1 ;
: ldra, ( -- ) $4F z80-ed1 ;
: ldai, ( -- ) $57 z80-ed1 ;
: ldar, ( -- ) $5F z80-ed1 ;

: in, ( r -- )
   z80-r 3 lshift $40 or z80-ed1 ;

: out, ( r -- )
   z80-r 3 lshift $41 or z80-ed1 ;

: sbchl, ( rp -- )
   z80-rp 4 lshift $42 or z80-ed1 ;

: adchl, ( rp -- )
   z80-rp 4 lshift $4A or z80-ed1 ;

: !rr, ( rp nn -- )
   z80-u16 { nn }
   z80-rp { rp }
   $ED fasm-emit
   $43 rp 4 lshift or fasm-emit
   nn z80-w, ;

: rr@, ( rp nn -- )
   z80-u16 { nn }
   z80-rp { rp }
   $ED fasm-emit
   $4B rp 4 lshift or fasm-emit
   nn z80-w, ;

: ldi,  ( -- ) $A0 z80-ed1 ;
: ldir, ( -- ) $B0 z80-ed1 ;
: ldd,  ( -- ) $A8 z80-ed1 ;
: lddr, ( -- ) $B8 z80-ed1 ;
: cpi,  ( -- ) $A1 z80-ed1 ;
: cpir, ( -- ) $B1 z80-ed1 ;
: cpd,  ( -- ) $A9 z80-ed1 ;
: cpdr, ( -- ) $B9 z80-ed1 ;
: ini,  ( -- ) $A2 z80-ed1 ;
: inir, ( -- ) $B2 z80-ed1 ;
: ind,  ( -- ) $AA z80-ed1 ;
: indr, ( -- ) $BA z80-ed1 ;
: outi, ( -- ) $A3 z80-ed1 ;
: otir, ( -- ) $B3 z80-ed1 ;
: outd, ( -- ) $AB z80-ed1 ;
: otdr, ( -- ) $BB z80-ed1 ;

\ ---- IX / IY (documented forms) ----
: z80-ixy ( pref -- )
   fasm-emit ;

: ldix, ( rd d -- )
   z80-disp { d }
   z80-r { rd }
   $DD z80-ixy
   $46 rd 3 lshift or fasm-emit
   d fasm-emit ;

: ldiy, ( rd d -- )
   z80-disp { d }
   z80-r { rd }
   $FD z80-ixy
   $46 rd 3 lshift or fasm-emit
   d fasm-emit ;

: ixld, ( d rs -- )
   z80-r { rs }
   z80-disp { d }
   $DD z80-ixy
   $70 rs or fasm-emit
   d fasm-emit ;

: iyld, ( d rs -- )
   z80-r { rs }
   z80-disp { d }
   $FD z80-ixy
   $70 rs or fasm-emit
   d fasm-emit ;

: ldix#, ( d n -- )
   z80-u8 { n }
   z80-disp { d }
   $DD z80-ixy $36 fasm-emit d fasm-emit n fasm-emit ;

: ldiy#, ( d n -- )
   z80-u8 { n }
   z80-disp { d }
   $FD z80-ixy $36 fasm-emit d fasm-emit n fasm-emit ;

: ldixw, ( nn -- )
   $DD z80-ixy $21 fasm-emit z80-w, ;

: ldiyw, ( nn -- )
   $FD z80-ixy $21 fasm-emit z80-w, ;

: !ix, ( nn -- ) $DD z80-ixy $22 fasm-emit z80-w, ;
: !iy, ( nn -- ) $FD z80-ixy $22 fasm-emit z80-w, ;
: ix@, ( nn -- ) $DD z80-ixy $2A fasm-emit z80-w, ;
: iy@, ( nn -- ) $FD z80-ixy $2A fasm-emit z80-w, ;

: addix, ( rp -- )
   z80-rp 4 lshift $09 or
   $DD z80-ixy fasm-emit ;

: addiy, ( rp -- )
   z80-rp 4 lshift $09 or
   $FD z80-ixy fasm-emit ;

: incix, ( -- ) $DD z80-ixy $23 fasm-emit ;
: inciy, ( -- ) $FD z80-ixy $23 fasm-emit ;
: decix, ( -- ) $DD z80-ixy $2B fasm-emit ;
: deciy, ( -- ) $FD z80-ixy $2B fasm-emit ;
: pushix, ( -- ) $DD z80-ixy $E5 fasm-emit ;
: pushiy, ( -- ) $FD z80-ixy $E5 fasm-emit ;
: popix, ( -- ) $DD z80-ixy $E1 fasm-emit ;
: popiy, ( -- ) $FD z80-ixy $E1 fasm-emit ;
: jpix, ( -- ) $DD z80-ixy $E9 fasm-emit ;
: jpiy, ( -- ) $FD z80-ixy $E9 fasm-emit ;
: spix, ( -- ) $DD z80-ixy $F9 fasm-emit ;
: spiy, ( -- ) $FD z80-ixy $F9 fasm-emit ;
: exspix, ( -- ) $DD z80-ixy $E3 fasm-emit ;
: exspiy, ( -- ) $FD z80-ixy $E3 fasm-emit ;

: addix@, ( d -- )
   z80-disp $DD z80-ixy $86 fasm-emit fasm-emit ;
: addiy@, ( d -- )
   z80-disp $FD z80-ixy $86 fasm-emit fasm-emit ;

: bitix, ( b d -- )
   z80-disp { d }
   z80-bit { b }
   $DD z80-ixy $CB fasm-emit d fasm-emit
   $46 b 3 lshift or fasm-emit ;

: bitiy, ( b d -- )
   z80-disp { d }
   z80-bit { b }
   $FD z80-ixy $CB fasm-emit d fasm-emit
   $46 b 3 lshift or fasm-emit ;

\ Pass 1 only sees the comma name. Length is fixed per form.
: z80-span ( c-addr u -- n )
   2dup s" ld#," compare 0= >r
   2dup s" add#," compare 0= r> or >r
   2dup s" adc#," compare 0= r> or >r
   2dup s" sub#," compare 0= r> or >r
   2dup s" sbc#," compare 0= r> or >r
   2dup s" and#," compare 0= r> or >r
   2dup s" xor#," compare 0= r> or >r
   2dup s" or#," compare 0= r> or >r
   2dup s" cp#," compare 0= r> or >r
   2dup s" jr," compare 0= r> or >r
   2dup s" jrnz," compare 0= r> or >r
   2dup s" jrz," compare 0= r> or >r
   2dup s" jrnc," compare 0= r> or >r
   2dup s" jrc," compare 0= r> or >r
   2dup s" djnz," compare 0= r> or >r
   2dup s" ina," compare 0= r> or >r
   2dup s" outa," compare 0= r> or >r
   2dup s" dw," compare 0= r> or >r
   2dup s" rlc," compare 0= r> or >r
   2dup s" rrc," compare 0= r> or >r
   2dup s" rl," compare 0= r> or >r
   2dup s" rr," compare 0= r> or >r
   2dup s" sla," compare 0= r> or >r
   2dup s" sra," compare 0= r> or >r
   2dup s" srl," compare 0= r> or >r
   2dup s" bit," compare 0= r> or >r
   2dup s" res," compare 0= r> or >r
   2dup s" set," compare 0= r> or >r
   2dup s" neg," compare 0= r> or >r
   2dup s" retn," compare 0= r> or >r
   2dup s" reti," compare 0= r> or >r
   2dup s" rrd," compare 0= r> or >r
   2dup s" rld," compare 0= r> or >r
   2dup s" im," compare 0= r> or >r
   2dup s" ldia," compare 0= r> or >r
   2dup s" ldra," compare 0= r> or >r
   2dup s" ldai," compare 0= r> or >r
   2dup s" ldar," compare 0= r> or >r
   2dup s" in," compare 0= r> or >r
   2dup s" out," compare 0= r> or >r
   2dup s" sbchl," compare 0= r> or >r
   2dup s" adchl," compare 0= r> or >r
   2dup s" ldi," compare 0= r> or >r
   2dup s" ldir," compare 0= r> or >r
   2dup s" ldd," compare 0= r> or >r
   2dup s" lddr," compare 0= r> or >r
   2dup s" cpi," compare 0= r> or >r
   2dup s" cpir," compare 0= r> or >r
   2dup s" cpd," compare 0= r> or >r
   2dup s" cpdr," compare 0= r> or >r
   2dup s" ini," compare 0= r> or >r
   2dup s" inir," compare 0= r> or >r
   2dup s" ind," compare 0= r> or >r
   2dup s" indr," compare 0= r> or >r
   2dup s" outi," compare 0= r> or >r
   2dup s" otir," compare 0= r> or >r
   2dup s" outd," compare 0= r> or >r
   2dup s" otdr," compare 0= r> or >r
   2dup s" incix," compare 0= r> or >r
   2dup s" inciy," compare 0= r> or >r
   2dup s" decix," compare 0= r> or >r
   2dup s" deciy," compare 0= r> or >r
   2dup s" pushix," compare 0= r> or >r
   2dup s" pushiy," compare 0= r> or >r
   2dup s" popix," compare 0= r> or >r
   2dup s" popiy," compare 0= r> or >r
   2dup s" jpix," compare 0= r> or >r
   2dup s" jpiy," compare 0= r> or >r
   2dup s" spix," compare 0= r> or >r
   2dup s" spiy," compare 0= r> or >r
   2dup s" exspix," compare 0= r> or >r
   2dup s" exspiy," compare 0= r> or >r
   2dup s" addix," compare 0= r> or >r
   2dup s" addiy," compare 0= r> or
   if 2drop 2 exit then

   2dup s" ldw," compare 0= >r
   2dup s" jp," compare 0= r> or >r
   2dup s" jpcc," compare 0= r> or >r
   2dup s" call," compare 0= r> or >r
   2dup s" callcc," compare 0= r> or >r
   2dup s" a@," compare 0= r> or >r
   2dup s" !a," compare 0= r> or >r
   2dup s" !hl," compare 0= r> or >r
   2dup s" hl@," compare 0= r> or >r
   2dup s" ldix," compare 0= r> or >r
   2dup s" ldiy," compare 0= r> or >r
   2dup s" ixld," compare 0= r> or >r
   2dup s" iyld," compare 0= r> or >r
   2dup s" addix@," compare 0= r> or >r
   2dup s" addiy@," compare 0= r> or
   if 2drop 3 exit then

   2dup s" !rr," compare 0= >r
   2dup s" rr@," compare 0= r> or >r
   2dup s" ldixw," compare 0= r> or >r
   2dup s" ldiyw," compare 0= r> or >r
   2dup s" !ix," compare 0= r> or >r
   2dup s" !iy," compare 0= r> or >r
   2dup s" ix@," compare 0= r> or >r
   2dup s" iy@," compare 0= r> or >r
   2dup s" ldix#," compare 0= r> or >r
   2dup s" ldiy#," compare 0= r> or >r
   2dup s" bitix," compare 0= r> or >r
   2dup s" bitiy," compare 0= r> or
   if 2drop 4 exit then

   2drop 1 ;

previous
set-current
[THEN]

z80-wl >order
' z80-span is fasm-span
previous
