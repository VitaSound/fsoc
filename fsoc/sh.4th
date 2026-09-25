\ fsoc/sh.4th — shell commands with one exit-code check.

\ Runs cmd. A non-zero status prints msg and aborts. cmd is not freed.
: sh-run ( cmd-a cmd-u msg-a msg-u -- )
    2swap system
    $? 0= IF 2drop EXIT THEN
    type cr
    true abort" command failed" ;

\ Same, but cmd is an allocated string and is freed here.
: sh-run+ ( cmd-a cmd-u msg-a msg-u -- )
    2swap 2dup 2>r 2swap sh-run
    2r> fjson.str-free ;

: sh-mkdir ( dir-a dir-u -- )
    s" mkdir -p " 2swap fjson.str-concat
    s" mkdir failed" sh-run+ ;

: sh-cp ( src-a src-u dst-a dst-u -- )
    2swap s" cp -f " 2swap fjson.str-concat
    s"  " fsoc-cat+
    2swap fsoc-cat+
    s" copy failed" sh-run+ ;

: sh-rm ( path-a path-u -- )
    s" rm -f " 2swap fjson.str-concat
    s" rm failed" sh-run+ ;
