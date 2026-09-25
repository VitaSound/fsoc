\ fsoc/hdl.4th — run fhdlgen on a design of this repository.
\ extra is the flag string after the design path (--out <dir> and
\ optional --param NAME=VALUE). design is a path from FSOC_HOME.
\ Output goes to --out; the log is fhdlgen.log in the current
\ (project) directory. stdout of fhdlgen stays on the build log.

: fhdlgen-build ( extra-a extra-u design-a design-u -- )
    fsoc-path
    s" ${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen build " 2swap fsoc-+cat
    2swap fsoc-cat+
    s"  2>fhdlgen.log" fsoc-cat+
    2dup system
    fjson.str-free
    $? IF
        s" cat fhdlgen.log >&2" system
        true abort" fhdlgen build failed"
    THEN ;

\ Design path of the project; def is the task default when design: is absent.
: project.design-or ( def-a def-u project -- c-addr u )
    project.design@ dup IF 2nip ELSE 2drop THEN ;

\ Module name the generator wrote into top-module. Allocated.
: project.top-module@ ( project -- c-addr u )
    s" top-module" rot project.file
    2dup fsoc-read-line1
    2swap fjson.str-free
    dup 0= IF true abort" top-module empty" THEN ;
