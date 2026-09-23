\ firmware/hex2readmem.4th — swapforth-style hex words → $readmemh lines

variable hx-fd

: hex2readmem ( c-addr-in u c-addr-out u - )
    2swap r/o open-file throw >r
    w/o create-file throw hx-fd !
    begin
        pad 80 r@ read-line throw
    while
        pad swap
        dup 0> IF
            hx-fd @ write-line throw
        ELSE 2drop THEN
    repeat
    drop
    r> close-file throw
    hx-fd @ close-file throw ;
