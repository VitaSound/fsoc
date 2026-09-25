\ Lamp loop stored in 'BOOT. The next reset runs it and does not return.
include csr.fs
hex
: lamp
    begin
        decimal 1 hex IO-LED io!
        ." lamp on" cr
        decimal 30 hex IO-TIMER io!
        begin IO-TIMER io@ 0= until
        decimal 0 hex IO-LED io!
        ." lamp off" cr
        decimal 30 hex IO-TIMER io!
        begin IO-TIMER io@ 0= until
    again
;
' lamp 'BOOT !
