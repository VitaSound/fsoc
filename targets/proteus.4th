\ targets/proteus.4th — Proteus does not run from this repository.
\ emit and load do nothing. run leaves the note that the hex is opened by hand.

: proteus-emit ( project -- ) drop ;

: proteus-run ( project -- )
   drop
   s" open firmware.hex in Proteus" fsoc-note ;

: proteus-load ( project -- ) drop ;

s" proteus" ' proteus-emit ' proteus-run ' proteus-load target-register
