\ fsoc/futils/disasm_gen.4th — generate fsys/fasm/<arch>/disasm.4th from ISA JSON.
\ Port of tools/isa_to_fasm.py DisasmGenerator. flua pilot: fsoc/flua/disasm_gen.lua.
\
\ Prerequisite: isa-load-spec already set isa-root-node.
\   s" tools/isa_specs/mcs51_isa.json" isa-load-spec drop
\   s" fsys/fasm/8051/disasm.4th" isa-gen-disasm
\
\ Emit contract: zero-operand mnemonics print assemblable `name,` (lowercase +
\ comma) so disasm text can be fed back to [asm]…[endasm] for D→A round-trip.
\ Templates with {placeholders} keep pretty text (A→D walk still checks lengths).

require ../flua/disasm_gen.4th

variable dg-fid
variable dg-instr
variable dg-op
variable dg-arr
variable dg-mnem-a
variable dg-mnem-u

: dg-w ( a u -- ) dg-fid @ write-file throw ;
: dg-nl ( -- ) s\" \n" dg-w ;
: dg-line ( a u -- ) dg-w dg-nl ;

\ Full hex like Python f"{n:02X}" — at least 2 digits, no upper bound.
create dg-hexbuf 16 allot
: dg-hex ( u -- )
   base @ >r hex
   0 <# # #s #>
   dup 16 u> abort" disasm_gen: hex too wide"
   dg-w
   r> base ! ;

\ Lowercase ASCII letter in place for assemblable name.
: dg-tolower ( c -- c )
   dup [char] A [char] Z 1+ within if 32 or then ;

: dg-has-placeholder? ( -- f )
   dg-instr @ s\" disasm" rot fjson.object-get dup if
      fjson.node-str@ s\" {" search nip nip
   else drop false then ;

: dg-mnemonic@ ( -- a u )
   dg-instr @ s\" mnemonic" rot fjson.object-get fjson.node-str@ ;

\ Write lowercase mnemonic + "," into the .4th as a Forth string literal body.
: dg-emit-asm-name ( -- )
   dg-mnemonic@ dg-mnem-u ! dg-mnem-a !
   s\"             .\" " dg-w
   dg-mnem-u @ 0 ?do
      dg-mnem-a @ i + c@ dg-tolower
      dg-hexbuf c! dg-hexbuf 1 dg-w
   loop
   s\" ,\"" dg-line ;

: dg-emit-pretty ( -- )
   s\"             .\" " dg-w
   dg-instr @ s\" disasm" rot fjson.object-get dup if
      fjson.node-str@ dg-w
   else
      drop dg-mnemonic@ dg-w
   then
   s\" \"" dg-line ;

: dg-arm ( opcode -- )
   >r
   s\"         $" dg-w r@ dg-hex s\"  of" dg-line
   s\"             .\" " dg-w r@ dg-hex
   s\" \" .\"  \"" dg-line
   dg-has-placeholder? 0= if
      dg-emit-asm-name
   else
      dg-emit-pretty
   then
   s\"             " dg-w
   dg-instr @ s\" bytes" rot fjson.object-get fjson.node-num@
   0 <# #s #> dg-w dg-nl
   s\"         endof" dg-line
   rdrop ;

: dg-one ( -- )
   dg-instr @ s\" opcode" rot fjson.object-get dup 0= if drop exit then
   fjson.node-num@ dg-op !
   dg-instr @ s\" encoding" rot fjson.object-get dup if
      fjson.node-str@ s\" rrr" search nip nip
   else drop false then
   if
      8 0 do dg-op @ i + dg-arm loop
   else
      dg-op @ dg-arm
   then ;

: isa-gen-disasm ( path-a path-u -- )
   w/o create-file throw dg-fid !
   s\" \\ auto-generated disasm.4th from ISA spec (futils disasm_gen)." dg-line
   s\" \\ Defines fasm-dis-one for the common disasm engine." dg-line
   s\" \\ Zero-operand forms print assemblable name, for D→A round-trip." dg-line
   dg-nl
   s\" include ../common/fasm-dis.4th" dg-line
   dg-nl
   s\" :noname ( pc -- pc' )" dg-line
   s\"     { pc } pc fasm@ ( opcode )" dg-line
   s\"     case" dg-line
   isa-root-node @ s\" instructions" rot fjson.object-get dg-arr !
   dg-arr @ fjson.array-len 0 ?do
      i dg-arr @ fjson.array-nth dg-instr !
      dg-one
   loop
   \ Gforth ENDCASE drops TOS on the default path; `1 dup` leaves nbytes.
   s\"         ( default ) fasm-h2 1 dup" dg-line
   s\"     endcase" dg-line
   s\"     pc swap + ( pc' )" dg-line
   s\" ; is fasm-dis-one" dg-line
   dg-fid @ close-file throw ;
