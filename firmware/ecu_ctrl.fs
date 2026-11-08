\ ECU control loop for j1b — tables only, no angle waits.
\ Writes setpoints to ECU CSR via indexed IO (when USE_ECU wrap is present).
\ Until MMIO is wired in wrap, this still demonstrates the control structure
\ on UART (BOOT prints table outputs).

include csr.fs
hex

\ --- tiny 8-point tables (RPM axis 0..7 ~ 0,1k..7k) ---
create VE-TAB
  decimal 40 c, 55 c, 70 c, 80 c, 85 c, 82 c, 75 c, 65 c, hex
create IGN-TAB
  decimal 8 c, 12 c, 18 c, 22 c, 28 c, 30 c, 28 c, 24 c, hex
create DWELL-TAB
  decimal 4 c, 4 c, 3 c, 3 c, 3 c, 2 c, 2 c, 2 c, hex
create WUE-TAB
  decimal 150 c, 130 c, 115 c, 105 c, 100 c, 100 c, 100 c, 100 c, hex

decimal
: clamp7 ( n -- n ) dup 0< if drop 0 then dup 7 > if drop 7 then ;
: rpm>idx ( rpm -- i ) 1000 / clamp7 ;
: ve@ ( rpm -- ve ) rpm>idx VE-TAB + c@ ;
: ign@ ( rpm -- deg ) rpm>idx IGN-TAB + c@ ;
: dwell@ ( rpm -- ms ) rpm>idx DWELL-TAB + c@ ;
: wue@ ( clt-bucket -- % ) clamp7 WUE-TAB + c@ ;

\ Required fuel baseline (µs) for the stand engine
2000 constant REQ-FUEL

: pw-calc ( rpm clt-b -- pw-us )
  swap ve@          ( clt ve )
  REQ-FUEL * 100 /  ( clt pw )
  swap wue@ * 100 / ;

\ Mock sensors until CSR STATUS is live
variable sim-rpm
variable sim-clt
1500 sim-rpm !
4 sim-clt !   \ warm bucket

: ecu-tick ( -- )
  sim-rpm @
  dup ign@                 ( rpm btdc )
  over dwell@ 1000 *       ( rpm btdc dwell-us )
  sim-rpm @ sim-clt @ pw-calc
  ( rpm btdc dwell pw )
  ." rpm=" 3 pick .
  ." btdc=" 2 pick .
  ." dwell=" over .
  ." pw=" . cr
  2drop 2drop
  sim-rpm @ 50 + dup 6000 > if drop 1500 then sim-rpm !
;

: ecu
  begin
    ecu-tick
    decimal 200 hex IO-TIMER io!
    begin IO-TIMER io@ 0= until
  again
;
' ecu 'BOOT !
