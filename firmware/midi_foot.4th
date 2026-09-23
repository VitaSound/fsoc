\ firmware/midi_foot.4th — FOOTSWITCH-SCAN host/target Forth
\ Host test captures MIDI-EMIT bytes. On J1 the same words talk UART.

create midi-log 32 allot
variable midi-log-n

: midi-log-reset ( - )
    0 midi-log-n ! ;

: MIDI-EMIT ( byte - )
    midi-log midi-log-n @ + c!
    1 midi-log-n +! ;

: MIDI-NOTE-ON ( note vel - )
    $90 MIDI-EMIT
    swap MIDI-EMIT
    MIDI-EMIT ;

: MIDI-NOTE-OFF ( note vel - )
    $80 MIDI-EMIT
    swap MIDI-EMIT
    MIDI-EMIT ;

create btn-prev 4 allot
create btn-now  4 allot
create note-map 4 allot

: midi-foot-init ( - )
    0 btn-prev 4 erase
    0 btn-now  4 erase
    60 note-map c!
    61 note-map 1+ c!
    62 note-map 2 + c!
    63 note-map 3 + c!
    midi-log-reset ;

: BUTTON? ( n - flag )
    btn-now + c@ ;

: FOOTSWITCH-SCAN ( - )
    4 0 DO
        I BUTTON? I btn-prev + c@ = 0= IF
            I BUTTON? IF
                I note-map + c@ $7F MIDI-NOTE-ON
            ELSE
                I note-map + c@ $00 MIDI-NOTE-OFF
            THEN
            I BUTTON? I btn-prev + c!
        THEN
    LOOP ;

: btn-press ( n - )
    1 swap btn-now + c! ;

: btn-release ( n - )
    0 swap btn-now + c! ;
