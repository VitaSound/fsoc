\ targets/yosys.4th — Yosys / nextpnr-ecp5 / ecppack target.
\ The task fills the same project, top, verilog file, clock, and pin
\ records as Quartus. This file writes <project>.lpf, build.sh and
\ load.sh. Package, speed, and density come from the loaded platform.
\ run executes build.sh. A non-empty FSOC_SYNTH_SKIP skips that run.
\ Tools already on PATH are used as they are. Otherwise the run
\ sources $HOME/oss-cad-suite/environment when that install exists.
\ The cable for openFPGALoader is a project option, not a board fact.

: yosys-check ( - )
    qproj$ @ 0= IF true abort" yosys: no project" THEN
    qtop$ @ 0= IF true abort" yosys: no top" THEN
    qvfile$ @ 0= IF true abort" yosys: no verilog file" THEN
    qclk$ @ 0= IF true abort" yosys: no clock" THEN
    current-platform @ 0= IF true abort" yosys: no board" THEN
    plat.package@ nip 0= IF true abort" yosys: board has no package" THEN
    plat.speed@ nip 0= IF true abort" yosys: board has no speed" THEN
    plat.density@ nip 0= IF true abort" yosys: board has no density" THEN ;

\ No locals: these run under ulist-each, which keeps an xt on the return stack.
: yosys-locate ( map - )
    qmap-cur !
    s\" LOCATE COMP \""
    qmap-cur @ qmap.port$ @ fsoc-fetch fjson.str-concat
    s\" \" SITE \"" fsoc-cat+
    qmap-cur @ qmap.pin$ @ fsoc-fetch fsoc-cat+
    s\" \";" fsoc-cat+
    fsoc-emit-free ;

: yosys-iobuf ( map - )
    dup qmap.iostd$ @ fsoc-fetch nip 0= IF drop EXIT THEN
    qmap-cur !
    s\" IOBUF PORT \""
    qmap-cur @ qmap.port$ @ fsoc-fetch fjson.str-concat
    s\" \" IO_TYPE=" fsoc-cat+
    qmap-cur @ qmap.iostd$ @ fsoc-fetch fsoc-cat+
    s" ;" fsoc-cat+
    fsoc-emit-free ;

: yosys-clk? ( map - flag )
    qmap.port$ @ fsoc-fetch qclk$ @ fsoc-fetch compare 0= ;

: yosys-freq ( map - )
    dup yosys-clk? 0= IF drop EXIT THEN
    drop
    s\" FREQUENCY PORT \""
    qclk$ @ fsoc-fetch fjson.str-concat
    s\" \" " fsoc-cat+
    plat-clock io.clock-hz@ 1000000 / fjson.u>str fsoc-cat++
    s" .000 MHz;" fsoc-cat+
    fsoc-emit-free ;

: yosys-map-emit ( map - )
    dup yosys-locate
    dup yosys-iobuf
    yosys-freq ;

: yosys-lpf ( c-addr-path u - )
    fjson.emit-to-file
    ['] yosys-map-emit qmaps-do
    fsoc-emit-close ;

: yosys-build-sh ( c-addr-path u - )
    fjson.emit-to-file
    s" #!/bin/sh" fsoc-emit-line
    s" set -e" fsoc-emit-line
    s\" yosys -p \"read_verilog "
    qvfile$ @ fsoc-fetch fjson.str-concat
    s" ; synth_ecp5 -top " fsoc-cat+
    qtop$ @ fsoc-fetch fsoc-cat+
    s"  -json " fsoc-cat+
    qproj$ @ fsoc-fetch fsoc-cat+
    s\" .json\"" fsoc-cat+
    fsoc-emit-free
    s" nextpnr-ecp5 --"
    plat.density@ fjson.str-concat
    s"  --package " fsoc-cat+
    plat.package@ fsoc-cat+
    s"  --speed " fsoc-cat+
    plat.speed@ fsoc-cat+
    s"  --json " fsoc-cat+
    qproj$ @ fsoc-fetch fsoc-cat+
    s" .json --lpf " fsoc-cat+
    qproj$ @ fsoc-fetch fsoc-cat+
    s" .lpf --textcfg " fsoc-cat+
    qproj$ @ fsoc-fetch fsoc-cat+
    s" .cfg" fsoc-cat+
    fsoc-emit-free
    s" ecppack "
    qproj$ @ fsoc-fetch fjson.str-concat
    s" .cfg " fsoc-cat+
    qproj$ @ fsoc-fetch fsoc-cat+
    s" .bit" fsoc-cat+
    fsoc-emit-free
    fsoc-emit-close ;

\ cable is the project option. An empty cable makes the script fail.
: yosys-load-sh ( path-a path-u cable-a cable-u - )
    2swap fjson.emit-to-file
    s" #!/bin/sh" fsoc-emit-line
    s" set -e" fsoc-emit-line
    dup 0= IF
        2drop
        s" echo 'yosys: no cable option' >&2" fsoc-emit-line
        s" exit 1" fsoc-emit-line
    ELSE
        s" openFPGALoader -c " 2swap fjson.str-concat
        s"  " fsoc-cat+
        qproj$ @ fsoc-fetch fsoc-cat+
        s" .bit" fsoc-cat+
        fsoc-emit-free
    THEN
    fsoc-emit-close ;

: yosys-emit { project -- }
    yosys-check
    qproj$ @ fsoc-fetch s" .lpf" fjson.str-concat project project.file
    2dup yosys-lpf fjson.str-free
    s" build.sh" project project.file 2dup yosys-build-sh fjson.str-free
    s" load.sh" project project.file
    s" cable" project project.opt@ yosys-load-sh
    quartus-reset ;

\ --build runs the tools. Tests set FSOC_SYNTH_SKIP.
: yosys-skip? ( -- flag )
    s" FSOC_SYNTH_SKIP" getenv nip 0<> ;

: yosys-on-path? ( -- flag )
    s" command -v yosys >/dev/null && command -v nextpnr-ecp5 >/dev/null" system
    $? 0= ;

: yosys-suite? ( -- flag )
    s\" test -x \"$HOME/oss-cad-suite/bin/nextpnr-ecp5\"" system
    $? 0= ;

: yosys-run ( project - )
    drop
    yosys-skip? IF EXIT THEN
    yosys-on-path? IF
        s" sh build.sh" s" yosys build failed" sh-run
        EXIT
    THEN
    yosys-suite? 0= IF true abort" yosys: add Yosys/nextpnr to PATH" THEN
    s" oss-cad-suite" fsoc-note
    s\" bash -c '. \"$HOME/oss-cad-suite/environment\" && sh build.sh'"
    s" yosys build failed" sh-run ;

: yosys-load ( project - )
    drop s" sh load.sh" s" load.sh failed" sh-run ;

s" yosys" ' yosys-emit ' yosys-run ' yosys-load target-register
