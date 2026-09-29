\ Release filter for kernel names.
\ No names stored yet: keep-name? accepts every name, which is the debug image.
\ A release build loads s" <name>" keep-name lines before the kernel.

64 constant keep-slot
256 constant keep-max
create keep-mem keep-max keep-slot * allot
variable keep-count
0 keep-count !

: keep-name ( c-addr u -- )
    keep-count @ keep-max >= if 2drop exit then
    keep-slot 1- min
    keep-count @ keep-slot * keep-mem + { slot }
    dup slot c!
    slot 1+ swap move
    1 keep-count +! ;

: keep-name? ( c-addr u -- f )
    keep-count @ 0= if 2drop true exit then
    keep-count @ 0 ?do
        keep-mem i keep-slot * + count
        2over compare 0= if 2drop unloop true exit then
    loop
    2drop false ;
