\ tests/fixture.4th — temporary project directories for builder tests.
\ Tests never write into projects/*. test-setup makes a fresh directory
\ under /tmp, test-teardown removes it.

s" load.4th" included

2variable tmp-dir$
0 0 tmp-dir$ 2!

: tmp-dir ( -- c-addr u ) tmp-dir$ 2@ ;

: tmp-new ( -- )
    tmp-dir fjson.str-free
    s" /tmp/fsoc-test-" utime drop fjson.u>str fsoc-+cat
    tmp-dir$ 2!
    tmp-dir sh-mkdir ;

: tmp-drop ( -- )
    s" rm -rf " tmp-dir fjson.str-concat s" rm failed" sh-run+
    tmp-dir fjson.str-free
    0 0 tmp-dir$ 2! ;

' tmp-new is test-setup
' tmp-drop is test-teardown

\ <tmp>/<name>, allocated.
: tmp-file ( name-a name-u -- c-addr u )
    tmp-dir s" /" fjson.str-concat 2swap fsoc-cat+ ;

: tmp-exists? ( name-a name-u -- flag )
    tmp-file 2dup file-exists? -rot fjson.str-free ;

\ Manifest of projects/<name> copied into the temp dir.
: tmp-use-project ( name-a name-u -- )
    s" projects/" 2swap fjson.str-concat s" /target.4th" fsoc-cat+
    fsoc-path+
    s" target.4th" tmp-file
    2over 2over sh-cp
    fjson.str-free fjson.str-free ;

\ Write a manifest from a string.
: tmp-manifest ( text-a text-u -- )
    s" target.4th" tmp-file 2dup 2>r 2swap fsoc-write-file 2r> fjson.str-free ;

\ Append a line to the manifest.
: tmp-manifest+ ( text-a text-u -- )
    s" target.4th" tmp-file
    2dup 2>r r/w open-file throw >r
    r@ file-size throw r@ reposition-file throw
    2dup r@ write-line throw
    r> close-file throw
    2r> fjson.str-free 2drop ;

\ cd <tmp> && <cmd>; true when the exit code is 0.
: in-tmp-sh ( cmd-a cmd-u -- flag )
    s" cd " tmp-dir fjson.str-concat s"  && " fsoc-cat+
    2swap fsoc-cat+
    2dup system fjson.str-free
    $? 0= ;

\ env <prefix> FSOC_HOME=<root> <root>/bin/fsoc <args> > sim.log, in the temp dir.
: in-tmp-fsoc ( prefix-a prefix-u args-a args-u -- flag )
    2>r
    s" env " 2swap fjson.str-concat
    s"  FSOC_HOME=" fsoc-cat+ fsoc-root fsoc-cat+
    s"  " fsoc-cat+ fsoc-root fsoc-cat+
    s" /bin/fsoc " fsoc-cat+ 2r> fsoc-cat+
    s"  > sim.log 2>&1" fsoc-cat+
    2dup in-tmp-sh -rot fjson.str-free ;

\ grep -q '<pattern>' <name> in the temp dir.
: tmp-grep? ( pattern-a pattern-u name-a name-u -- flag )
    2>r
    s" grep -q '" 2swap fjson.str-concat s" ' " fsoc-cat+
    2r> fsoc-cat+
    2dup in-tmp-sh -rot fjson.str-free ;

\ cmp -s <root>/<rel> <tmp>/<name>
: tmp-same-as-root? ( rel-a rel-u name-a name-u -- flag )
    2>r
    s" cmp -s " 2swap fsoc-path fsoc-+cat s"  " fsoc-cat+
    2r> fsoc-cat+
    2dup in-tmp-sh -rot fjson.str-free ;

\ Exit with 1 when any expectation failed, so fmix sees the failure.
: test-finish ( -- )
    #ERRORS @ IF 1 (bye) THEN ;
