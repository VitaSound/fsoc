\ tests/con_session.4th — fsys console session helpers (j1 emu / avr-con)

: j1a-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1a\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: j1b-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1b\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: avr-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\ns\" fsys\" sys:\n" tmp-manifest ;

: bcpu-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" bcpu\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: cd16-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" cd16\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

: msl16-fsys-manifest ( -- )
   s\" s\" soc\" task:\ns\" emulation\" target:\ns\" msl16\" cpu:\ns\" fsys\" sys:\n" tmp-manifest ;

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

: avr-con-ready? ( -- flag )
   s" test -f /usr/lib/x86_64-linux-gnu/libsimavr.so.2" system
   $? 0= 0= if false exit then
   s" test -d /usr/include/simavr -o -d /tmp/simavr-dev/usr/include/simavr" system
   $? 0= ;

: avr-con-file ( -- flag )
   fsoc-root s" /tools/avr-con ./firmware.hex -f uart.in > con.log 2>con.err" fjson.str-concat
   2dup in-tmp-sh -rot fjson.str-free ;

: avr-con-alive ( -- )
   s" PC past image" s" con.err" tmp-grep? expect-false
   s" crash pc" s" con.err" tmp-grep? expect-false ;

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

: avr-con-session ( -- )
   s" avr" con-write-in
   s" " s" --build" in-tmp-fsoc expect-true
   s" firmware.hex" tmp-exists? expect-true
   avr-con-file expect-true
   avr-con-alive
   s" avr" s" con.log" con-check ;
