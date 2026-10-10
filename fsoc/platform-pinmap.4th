\ fsoc/platform-pinmap.4th — board pin helpers for tasks.
\ Loaded after targets/quartus.4th (see core.4th). Without a platform the
\ words exit quietly (emulation). quartus-project / top / clock stay in the task.
\ Stack-only (no locals): soc-map-board keeps project under >r.

2variable bm-tx
2variable bm-rx

: board-map-clock ( sig-a sig-u -- )
    current-platform @ 0= IF 2drop EXIT THEN
    2>r
    plat-clock
    dup io.name$ @ fsoc-fetch
    rot io.index @
    >r 2dup r@ request r>
    2r> quartus-map ;

: board-map-led ( sig-a sig-u -- )
    current-platform @ 0= IF 2drop EXIT THEN
    2>r
    s" user_led" 0 request
    s" user_led" 0 2r> quartus-map ;

: board-map-uart ( tx-a tx-u rx-a rx-u -- )
    current-platform @ 0= IF 2drop 2drop EXIT THEN
    bm-rx 2!
    bm-tx 2!
    s" serial" 0 io-find ?dup 0= IF EXIT THEN drop
    s" serial" 0 request
    s" serial" 0 s" tx" bm-tx 2@ quartus-map-sub
    s" serial" 0 s" rx" bm-rx 2@ quartus-map-sub ;

: pin-map ( res-a res-u index sig-a sig-u -- )
    current-platform @ 0= IF 2drop drop 2drop EXIT THEN
    2>r >r
    2dup r@ request
    r> 2r> quartus-map ;
