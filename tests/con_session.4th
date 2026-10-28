\ tests/con_session.4th — fsys console session helpers (emu / soft-AVR)

: j1a-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1a\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: j1b-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1b\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: avr-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\ns\" fsys\" sys:\n" tmp-manifest ;

: bcpu-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" bcpu\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: cd16-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" cd16\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: msl16-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" msl16\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: z80-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" z80\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: mcs8051-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" 8051\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: con-py ( args-a args-u -- flag )
   s" python3 " fsoc-root fjson.str-concat s" /tests/con_words.py " fsoc-cat+
   2swap fsoc-cat+
   2dup in-tmp-sh -rot fjson.str-free ;

: con-write-in ( cpu-a cpu-u -- )
   s" write " 2swap fjson.str-concat s"  uart.in" fsoc-cat+
   2dup con-py expect-true
   fjson.str-free ;

: j1-con-run ( -- flag )
   s\" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=800000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(cat uart.in)\" "
   s" --build" in-tmp-fsoc ;

: con-check ( cpu-a cpu-u log-a log-u -- )
   2>r
   s" check " 2swap fjson.str-concat
   s"  " fsoc-cat+
   2r> fsoc-cat+
   2dup con-py expect-true
   fjson.str-free ;

: j1-con-session ( cpu-a cpu-u -- )
   2dup con-write-in
   j1-con-run expect-true
   s" sim.log" con-check ;

: bcpu-con-session ( -- )
   s" bcpu" con-write-in
   j1-con-run expect-true
   s" bcpu" s" sim.log" con-check ;

: cd16-con-session ( -- )
   s" cd16" con-write-in
   j1-con-run expect-true
   s" cd16" s" sim.log" con-check ;

: msl16-con-session ( -- )
   s" msl16" con-write-in
   j1-con-run expect-true
   s" msl16" s" sim.log" con-check ;

: z80-con-session ( -- )
   s" z80" con-write-in
   j1-con-run expect-true
   s" z80" s" sim.log" con-check ;

: mcs8051-con-session ( -- )
   s" 8051" con-write-in
   j1-con-run expect-true
   s" 8051" s" sim.log" con-check ;

: avr-con-session ( -- )
   s" avr" con-write-in
   j1-con-run expect-true
   s" avr" s" sim.log" con-check ;
