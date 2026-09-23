\ fsoc.4th — CLI

s" fsoc/load.4th" included

2VARIABLE pkg-version
s" 0.1.0" pkg-version 2!

2VARIABLE cmd-arg
2VARIABLE param-arg

: fsoc-read-args
    s" FSOC_CMD" getenv 2dup nip IF
        cmd-arg 2!
    ELSE
        2drop
        next-arg 2drop next-arg
        2dup s" -e" compare 0= IF 2drop next-arg THEN
        cmd-arg 2!
    THEN
    s" FSOC_PARAM" getenv 2dup nip IF
        param-arg 2!
    ELSE
        2drop next-arg
        dup IF param-arg 2! ELSE 2drop s" " param-arg 2! THEN
    THEN ;

: fsoc.help
    cr s" fsoc v" type pkg-version 2@ type cr
    s"   version" type cr
    s"   help" type cr
    s"   blinky   emit blinky + quartus + icarus into build/blinky" type cr
    s"   soc      emit CSR HAL into build/soc" type cr ;

: fsoc.version
    cr s" fsoc v" type pkg-version 2@ type cr ;

: fsoc.blinky
    s" boards/vitasound_ep4ce10.4th" included
    s" clk50" 0 request
    s" user_led" 0 request
    s" mkdir -p build/blinky" system
    s" build/blinky" blinky-emit-dir
    cr s" blinky emitted to build/blinky (from rtl/blinky.v)" type cr ;

: fsoc.soc
    cores-minimal-soc
    s" mkdir -p build/soc/software" system
    s" build/soc/software/csr.4th" csr-export-4th
    s" build/soc/software/csr.json" csr-export-json
    cr s" soc CSR emitted" type cr ;

: fsoc-dispatch
    fsoc-read-args
    cmd-arg 2@ nip 0= IF fsoc.help EXIT THEN
    cmd-arg 2@ s" version" compare 0= IF fsoc.version EXIT THEN
    cmd-arg 2@ s" help" compare 0= IF fsoc.help EXIT THEN
    cmd-arg 2@ s" blinky" compare 0= IF fsoc.blinky EXIT THEN
    cmd-arg 2@ s" soc" compare 0= IF fsoc.soc EXIT THEN
    s" Unknown command." type cr fsoc.help ;

fsoc-dispatch
0 bye
