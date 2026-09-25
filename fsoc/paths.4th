\ fsoc/paths.4th — repository paths come from FSOC_HOME only.
\ Nothing here guesses the caller's directory.

2variable fsoc-root$
0 0 fsoc-root$ 2!

\ Tests set the root from the current directory; the CLI gets it from the env.
: fsoc-root! ( c-addr u -- )
    fsoc-root$ 2@ fjson.str-free
    fjson.str-dup fsoc-root$ 2! ;

: fsoc-root-from-env ( -- )
    s" FSOC_HOME" getenv dup IF fsoc-root! ELSE 2drop THEN ;

fsoc-root-from-env

: fsoc-root ( -- c-addr u )
    fsoc-root$ 2@ dup 0= IF true abort" FSOC_HOME unset" THEN ;

\ Allocated string. Caller frees.
: fsoc-path ( rel-a rel-u -- abs-a abs-u )
    fsoc-root s" /" fjson.str-concat
    2swap fsoc-cat+ ;

\ Same for an allocated rel; rel is freed.
: fsoc-path+ ( rel-a rel-u -- abs-a abs-u )
    2dup 2>r fsoc-path 2r> fjson.str-free ;

create fsoc-cwd-buf 1024 allot

\ Static buffer; valid until the next call.
: cwd@ ( -- c-addr u )
    fsoc-cwd-buf 1024 get-dir ;

: fsoc-strip-slash ( c-addr u -- c-addr u )
    begin
        dup 0= IF EXIT THEN
        2dup + 1- c@ [char] / = IF 1- ELSE EXIT THEN
    again ;

variable fsoc-slash

: fsoc-basename ( c-addr u -- c-addr u )
    fsoc-strip-slash
    -1 fsoc-slash !
    dup 0 ?do
        over i + c@ [char] / = if i fsoc-slash ! then
    loop
    fsoc-slash @ 0< if exit then
    fsoc-slash @ 1+ /string ;

: file-exists? ( c-addr u -- flag )
    file-status nip 0= ;
