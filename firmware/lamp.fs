\ Lamp loop stored in 'BOOT. The next reset runs it and does not return.
hex
: lamp
    begin
        decimal 1 hex 400 io!
        ." lamp on" cr
        decimal 30 hex 800 io!
        begin 800 io@ 0= until
        decimal 0 hex 400 io!
        ." lamp off" cr
        decimal 30 hex 800 io!
        begin 800 io@ 0= until
    again
;
' lamp 'BOOT !
