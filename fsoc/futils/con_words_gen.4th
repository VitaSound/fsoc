\ fsoc/futils/con_words_gen.4th — ANS names from kernel*.4th → RUN/COLON/SKIP
\ Python mirror: tools/con_words_gen.py (parity target for emit shape).
\
\   s" <cpu>" s" <kernel-file-or-dir>" con-words-gen ( -- )
[IFUNDEF] con-words-gen-loaded

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    variable cwg-ta variable cwg-tu
    variable cwg-ci variable cwg-cok
    variable cwg-a variable cwg-ua variable cwg-b variable cwg-vb
    variable cwg-src variable cwg-p variable cwg-len
    variable cwg-ts
    variable cwg-last-s-a variable cwg-last-s-u
    variable cwg-kw-n
    create cwg-kw-names 16384 allot
    create cwg-kw-lens-arr 256 allot
    create cwg-file-buf 32768 allot
    variable cwg-file-l

    : cwg-str= ( a u b vb -- f )
        >r >r >r >r
        r> cwg-a !   r> cwg-ua !   r> cwg-b !   r> cwg-vb !
        cwg-ua @ cwg-vb @ = if
            0 cwg-ci ! 1 cwg-cok !
            begin cwg-cok @ 1 and cwg-ci @ cwg-ua @ u< and while
                cwg-a @ cwg-ci @ + c@ cwg-b @ cwg-ci @ + c@ <> if 0 cwg-cok ! then
                1 cwg-ci +!
            repeat
            cwg-cok @
        else 0 then ;

    : cwg-starts-with ( a u b vb -- f )
        >r >r >r >r
        r> cwg-a !   r> cwg-ua !   r> cwg-b !   r> cwg-vb !
        cwg-ua @ cwg-vb @ < if 0 exit then
        0 cwg-ci ! 1 cwg-cok !
        begin cwg-cok @ 1 and cwg-ci @ cwg-vb @ u< and while
            cwg-a @ cwg-ci @ + c@ cwg-b @ cwg-ci @ + c@ <> if 0 cwg-cok ! then
            1 cwg-ci +!
        repeat
        cwg-cok @ ;

    : cwg-contains ( hay-a hay-u ndl-a ndl-u -- f )
        search >r 2drop r> ;

    create cwg-s-kword 6 allot   s" k-word"   cwg-s-kword swap cmove   6 constant cwg-l-s-kword
    create cwg-s-jbword 6 allot  s" jb-word"  cwg-s-jbword swap cmove  6 constant cwg-l-s-jbword
    create cwg-s-dq    2 allot   115 cwg-s-dq c!   34 cwg-s-dq 1+ c!   2 constant cwg-l-s-dq

    variable cwg-ki
    : cwg-kw-has ( name-a name-u -- f )
        cwg-tu ! cwg-ta !
        0 cwg-ki !
        begin cwg-ki @ cwg-kw-n @ u< while
            cwg-ki @ 64 * cwg-kw-names +
            cwg-ki @ cwg-kw-lens-arr + c@
            cwg-ta @ cwg-tu @ cwg-str=
            if -1 exit then
            1 cwg-ki +!
        repeat
        0 ;

    : cwg-store-kw ( name-a name-u -- )
        cwg-tu !   cwg-ta !
        cwg-tu @ 0= if exit then            \ empty pending
        cwg-tu @ 1- cwg-ta @ + c@ 34 = if   \ strip closing "
            cwg-tu @ 1- cwg-tu !
        then
        cwg-ta @ cwg-tu @ cwg-kw-has if exit then
        cwg-kw-n @ 255 u>= if exit then
        cwg-ta @ cwg-kw-n @ 64 * cwg-kw-names + cwg-tu @ cmove
        cwg-tu @ cwg-kw-n @ cwg-kw-lens-arr + c!
        1 cwg-kw-n +! ;

    : cwg-is-ws ( c -- f )
        dup 32 = if drop 1 exit then
        dup 9 = if drop 1 exit then
        dup 13 = if drop 1 exit then
        dup 10 = if drop 1 exit then
        drop 0 ;

    : cwg-cpeek ( -- c )
        cwg-p @ cwg-src @ + c@ ;

    : cwg-skip-comment ( -- )
        begin
            cwg-p @ cwg-len @ u< while
                cwg-cpeek 10 = if exit then
                1 cwg-p +!
        repeat ;

    : cwg-skip-ws ( -- )
        begin
            cwg-p @ cwg-len @ u< 0= if exit then
            cwg-cpeek
            dup cwg-is-ws if
                dup 10 = if
                    drop
                    0 cwg-last-s-a !   0 cwg-last-s-u !
                else
                    drop
                then
                1 cwg-p +!
            else
                dup 92 = if
                    drop
                    cwg-skip-comment
                else
                    drop
                    exit
                then
            then
        again ;

    : cwg-read-token ( -- a u f )
        cwg-skip-ws
        cwg-p @ cwg-len @ u< if
            cwg-p @ cwg-ts !
            begin
                cwg-p @ cwg-len @ u< while
                    cwg-cpeek
                    dup cwg-is-ws if
                        drop
                        cwg-file-buf cwg-ts @ +
                        cwg-p @ cwg-ts @ -
                        1 exit
                    then
                    drop
                    1 cwg-p +!
                repeat
                cwg-file-buf cwg-ts @ +
                cwg-p @ cwg-ts @ -
                1
            else
                0 0 0
            then ;

    : cwg-next-token ( -- f )
        cwg-read-token >r cwg-tu ! cwg-ta ! r> ;

    : cwg-scan-loop ( -- )
        begin
            cwg-next-token 0= if exit then
            cwg-ta @ cwg-tu @ cwg-s-dq cwg-l-s-dq cwg-str= if
                cwg-next-token 0= if exit then
                cwg-last-s-u @ 0= if
                    cwg-ta @ cwg-last-s-a !   cwg-tu @ cwg-last-s-u !
                    cwg-last-s-u @ 1- cwg-last-s-a @ + c@ 34 = if
                        cwg-last-s-u @ 1- cwg-last-s-u !
                    then
                then
            else
                cwg-ta @ cwg-tu @ cwg-s-kword cwg-l-s-kword cwg-str= if
                    cwg-last-s-a @ cwg-last-s-u @ cwg-store-kw
                    0 cwg-last-s-a !   0 cwg-last-s-u !
                then
                cwg-ta @ cwg-tu @ cwg-s-jbword cwg-l-s-jbword cwg-str= if
                    cwg-last-s-a @ cwg-last-s-u @ cwg-store-kw
                    0 cwg-last-s-a !   0 cwg-last-s-u !
                then
            then
        again ;

    : cwg-readwhole ( a u -- count )
        r/o open-file throw >r
        cwg-file-buf 32768 r@ read-file drop
        dup cwg-file-l !
        r> close-file throw ;

    : cwg-scan-file-append ( path-a path-u -- )
        cwg-readwhole drop
        cwg-file-buf cwg-src ! cwg-file-l @ cwg-len ! 0 cwg-p !
        0 cwg-last-s-a ! 0 cwg-last-s-u !
        cwg-scan-loop ;

    : cwg-scan-kernel-file ( path-a path-u -- )
        0 cwg-kw-n !
        cwg-scan-file-append ;

    \ ---- recipes ----
    variable cwg-recipe-n
    create cwg-recipe-names 8192 allot
    create cwg-recipe-lines 8192 allot
    create cwg-recipe-hashes 8192 allot
    create cwg-recipe-types 128 allot
    create cwg-recipe-nlens 128 allot
    create cwg-recipe-llens 128 allot
    create cwg-recipe-hlens 128 allot

    : cwg-add-recipe ( name-a name-u line-a line-u has-a has-u type -- )
        cwg-recipe-n @ cwg-recipe-types + c!
        cwg-tu ! cwg-ta !
        cwg-ta @ cwg-recipe-n @ 64 * cwg-recipe-hashes + cwg-tu @ move
        cwg-tu @ cwg-recipe-n @ cwg-recipe-hlens + c!
        cwg-tu ! cwg-ta !
        cwg-ta @ cwg-recipe-n @ 64 * cwg-recipe-lines + cwg-tu @ move
        cwg-tu @ cwg-recipe-n @ cwg-recipe-llens + c!
        cwg-tu ! cwg-ta !
        cwg-ta @ cwg-recipe-n @ 64 * cwg-recipe-names + cwg-tu @ move
        cwg-tu @ cwg-recipe-n @ cwg-recipe-nlens + c!
        1 cwg-recipe-n +! ;

    create cwg-rname 64 allot
    variable cwg-rnlen
    variable cwg-ri
    : cwg-find-recipe ( name-a name-u -- idx|-1 )
        cwg-tu ! cwg-ta !
        0 cwg-ri !
        begin cwg-ri @ cwg-recipe-n @ u< while
            cwg-ri @ 64 * cwg-recipe-names +
            cwg-ri @ cwg-recipe-nlens + c@
            cwg-ta @ cwg-tu @ cwg-str=
            if cwg-ri @ exit then
            1 cwg-ri +!
        repeat
        -1 ;

    \ ---- skips ----
    variable cwg-skip-n
    create cwg-skip-patterns 8192 allot
    create cwg-skip-reasons 8192 allot
    create cwg-skip-plens 128 allot
    create cwg-skip-rlens 128 allot
    create cwg-skip-kinds 128 allot

    : cwg-add-skip-k ( pat-a pat-u rea-a rea-u kind -- )
        cwg-skip-n @ cwg-skip-kinds + c!
        cwg-tu ! cwg-ta !
        cwg-ta @ cwg-skip-n @ 64 * cwg-skip-reasons + cwg-tu @ move
        cwg-tu @ cwg-skip-n @ cwg-skip-rlens + c!
        cwg-tu ! cwg-ta !
        cwg-ta @ cwg-skip-n @ 64 * cwg-skip-patterns + cwg-tu @ move
        cwg-tu @ cwg-skip-n @ cwg-skip-plens + c!
        1 cwg-skip-n +! ;

    create cwg-lowbuf 64 allot
    : cwg-tolower ( a u -- a2 u )
        dup 64 min cwg-rnlen !
        0 cwg-ci !
        begin cwg-ci @ cwg-rnlen @ u< while
            over cwg-ci @ + c@
            dup [char] A [char] Z 1+ within if 32 + then
            cwg-lowbuf cwg-ci @ + c!
            1 cwg-ci +!
        repeat
        2drop cwg-lowbuf cwg-rnlen @ ;

    variable cwg-ska variable cwg-sku
    : cwg-infer-skip ( name-a name-u -- reason-a reason-u | 0 0 )
        cwg-tolower cwg-sku ! cwg-ska !
        0 cwg-ri !
        begin cwg-ri @ cwg-skip-n @ u< while
            cwg-ri @ 64 * cwg-skip-patterns +
            cwg-ri @ cwg-skip-plens + c@           \ ( pa pu )
            cwg-ska @ cwg-sku @                     \ ( pa pu ha hu )
            cwg-ri @ cwg-skip-kinds + c@ >r         \ ( pa pu ha hu ) R:kind
            2swap                                   \ ( ha hu pa pu )
            r@ 0= if cwg-str=
            else r@ 1 = if cwg-starts-with
            else cwg-contains
            then then
            rdrop
            if
                cwg-ri @ 64 * cwg-skip-reasons +
                cwg-ri @ cwg-skip-rlens + c@ exit
            then
            1 cwg-ri +!
        repeat
        0 0 ;

    \ ---- classify / emit ----
    create cwg-cpu-buf 32 allot
    variable cwg-cpu-u
    : cwg-cpu-a ( -- a ) cwg-cpu-buf ;
    create cwg-kern-buf 512 allot
    variable cwg-kern-u
    : cwg-kern-a ( -- a ) cwg-kern-buf ;
    create cwg-cpu-up 32 allot
    variable cwg-cpu-up-u
    variable cwg-run-n variable cwg-col-n variable cwg-sk-n
    create cwg-cls-type 256 allot
    create cwg-cls-idx 256 cells allot
    \ for SKIP without recipe: stash reason into side arrays
    create cwg-sk-ra 256 cells allot
    create cwg-sk-ru 256 allot

    : cwg-kw@ ( i -- a u )
        dup 64 * cwg-kw-names + swap cwg-kw-lens-arr + c@ ;

    : cwg-classify-one ( i -- )
        >r
        r@ cwg-kw@ 2dup cwg-infer-skip dup if
            \ ( na nu ra ru ) skip — store reason then drop name
            r@ cwg-sk-ru + c!
            r@ cells cwg-sk-ra + !
            2drop
            2 r@ cwg-cls-type + c!
            1 cwg-sk-n +!
        else
            2drop
            cwg-find-recipe dup 0< if
                drop
                s" unknown word - no test recipe"
                r@ cwg-sk-ru + c!
                r@ cells cwg-sk-ra + !
                2 r@ cwg-cls-type + c!
                1 cwg-sk-n +!
            else
                dup r@ cells cwg-cls-idx + !
                cwg-recipe-types + c@
                dup r@ cwg-cls-type + c!
                if 1 cwg-col-n +! else 1 cwg-run-n +! then
            then
        then
        rdrop ;

    : cwg-classify-all ( -- )
        0 cwg-run-n ! 0 cwg-col-n ! 0 cwg-sk-n !
        cwg-kw-n @ 0 ?do i cwg-classify-one loop ;

    \ simple bubble sort by name (stable enough for emit order)
    create cwg-tmpn 64 allot
    variable cwg-tmpu
    : cwg-sort-kw ( -- ) ; \ order not required for run_all; Python sorts for pretty emit

    : cwg-emit-jstr ( a u -- )
        [char] " emit
        bounds ?do
            i c@
            dup [char] " = if drop [char] \ emit [char] " emit
            else dup [char] \ = if drop [char] \ emit [char] \ emit
            else emit then then
        loop
        [char] " emit ;

    : cwg-cpu-upper! ( -- )
        cwg-cpu-u @ 32 min cwg-cpu-up-u !
        0 cwg-ci !
        begin cwg-ci @ cwg-cpu-up-u @ u< while
            cwg-cpu-a cwg-ci @ + c@
            dup [char] a [char] z 1+ within if 32 - then
            cwg-cpu-up cwg-ci @ + c!
            1 cwg-ci +!
        repeat ;

    : cwg-emit-header ( -- )
        ." # Auto-generated " cwg-cpu-a cwg-cpu-u @ type
        ."  entries for con_words.py" cr
        ." # Source: " cwg-kern-a cwg-kern-u @ type cr
        cr ;

    : cwg-emit-run ( -- )
        cwg-cpu-up cwg-cpu-up-u @ type ." _RUN = {" cr
        cwg-kw-n @ 0 ?do
            i cwg-cls-type + c@ 0= if
                ."     " i cwg-kw@ cwg-emit-jstr ." : ("
                i cells cwg-cls-idx + @ >r
                r@ 64 * cwg-recipe-lines +
                r@ cwg-recipe-llens + c@ cwg-emit-jstr
                ." , "
                r@ 64 * cwg-recipe-hashes +
                r> cwg-recipe-hlens + c@ type
                ." )," cr
            then
        loop
        ." }" cr cr ;

    : cwg-emit-colon ( -- )
        cwg-cpu-up cwg-cpu-up-u @ type ." _COLON = {" cr
        cwg-kw-n @ 0 ?do
            i cwg-cls-type + c@ 1 = if
                ."     " i cwg-kw@ cwg-emit-jstr ." : ("
                i cells cwg-cls-idx + @ >r
                r@ 64 * cwg-recipe-lines +
                r@ cwg-recipe-llens + c@ cwg-emit-jstr
                ." , "
                r@ 64 * cwg-recipe-hashes +
                r> cwg-recipe-hlens + c@ type
                ." )," cr
            then
        loop
        ." }" cr cr ;

    : cwg-emit-skip ( -- )
        cwg-cpu-up cwg-cpu-up-u @ type ." _SKIP = {" cr
        cwg-kw-n @ 0 ?do
            i cwg-cls-type + c@ 2 = if
                ."     " i cwg-kw@ cwg-emit-jstr ." : "
                i cells cwg-sk-ra + @
                i cwg-sk-ru + c@
                cwg-emit-jstr ." ," cr
            then
        loop
        ." }" cr cr ;

    : cwg-emit-core-has ( -- )
        cwg-cpu-up cwg-cpu-up-u @ type ." _CORE_HAS = [" cr
        ."     " s" 3" cwg-emit-jstr ." ," cr
        ."     " s"  ok" cwg-emit-jstr ." ," cr
        ."     " s" 13" cwg-emit-jstr ." ," cr
        ."     " s" ?" cwg-emit-jstr ." ," cr
        ."     " s" 7" cwg-emit-jstr ." ," cr
        ."     " s" <0>" cwg-emit-jstr ." ," cr
        ."     " s" <3> 1 2 3" cwg-emit-jstr ." ," cr
        ."     " s" 42" cwg-emit-jstr ." ," cr
        ." ]" cr ;

    : cwg-emit-summary ( -- )
        cr ." Summary for " cwg-cpu-a cwg-cpu-u @ type ." :" cr
        ."  Total words: " cwg-kw-n @ . cr
        ."  RUN: " cwg-run-n @ 0 .r cr
        ."  COLON: " cwg-col-n @ 0 .r cr
        ."  SKIP: " cwg-sk-n @ 0 .r cr ;

    : cwg-emit-all ( -- )
        cwg-cpu-upper!
        cwg-sort-kw
        cwg-classify-all
        cwg-emit-header
        cwg-emit-run
        cwg-emit-colon
        cwg-emit-skip
        cwg-emit-core-has
        cwg-emit-summary ;

    \ ---- path: file or directory of kernel*.4th ----
    \ read-dir ( c-addr u1 dirid -- u2 ior ) — like run_all_tools
    variable cwg-did
    create cwg-dbuf 512 allot
    create cwg-path 512 allot
    variable cwg-path-l
    : cwg-path-reset ( -- ) 0 cwg-path-l ! ;
    : cwg-path-add ( a u -- )
        dup cwg-path-l @ + 512 u>= abort" con_words_gen: path too long"
        >r cwg-path cwg-path-l @ + r@ move r> cwg-path-l +! ;
    : cwg-path@ ( -- a u ) cwg-path cwg-path-l @ ;

    : cwg-kernel-name? ( a u -- f )
        dup 10 < if 2drop 0 exit then
        over 6 s" kernel" compare if 2drop 0 exit then
        2dup + 4 - 4 s" .4th" compare 0= >r 2drop r> ;

    : cwg-read-dirent ( -- a u f )
        cwg-dbuf 512 cwg-did @ read-dir throw
        over 0= if 2drop 0 0 0 exit then
        drop cwg-dbuf swap -1 ;

    : cwg-scan-dir ( a u -- )
        0 cwg-kw-n !
        open-dir if drop exit then
        cwg-did !
        begin cwg-read-dirent while
            2dup cwg-kernel-name? if
                cwg-path-reset
                cwg-kern-a cwg-kern-u @ cwg-path-add
                s" /" cwg-path-add
                cwg-path-add
                cwg-path@ cwg-scan-file-append
            else 2drop then
        repeat
        cwg-did @ close-dir drop ;

    : cwg-scan-path ( a u -- )
        2dup open-dir 0= if
            close-dir drop
            cwg-scan-dir
        else
            drop
            cwg-scan-kernel-file
        then ;

    : cwg-print-word ( idx -- )
        cwg-kw@ type cr ;
    : cwg-list-words ( -- )
        cwg-kw-n @ 0 ?do i cwg-print-word loop ;

    : con-words-gen ( cpu-a cpu-u kern-a kern-u -- )
        \ copy transient s" strings into module buffers
        2swap                           \ ( kern-a kern-u cpu-a cpu-u )
        32 min dup cwg-cpu-u !
        cwg-cpu-buf swap move
        512 min dup cwg-kern-u !
        cwg-kern-buf swap move
        cwg-kern-a cwg-kern-u @ cwg-scan-path
        cwg-emit-all ;


    \ AUTO-generated — tools/con_words_gen.py; strings via save-mem
    : cwg-load-recipes ( -- )
        0 cwg-recipe-n !
        s" !" save-mem s" here 7 over ! @ ." save-mem s\" [\"7\"]" save-mem 0 cwg-add-recipe
        s" '" save-mem s" ' + execute 3 4 + drop 1 2 ' + execute ." save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" *" save-mem s" 6 7 * ." save-mem s\" [\"42\"]" save-mem 0 cwg-add-recipe
        s" +" save-mem s" 1 2 + ." save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" +loop" save-mem s" : tpl 0 5 0 do 1+ 2 +loop . ; tpl" save-mem s\" [\"3\"]" save-mem 1 cwg-add-recipe
        s" ," save-mem s" here 9 , @ ." save-mem s\" [\"9\"]" save-mem 0 cwg-add-recipe
        s" -" save-mem s" 5 2 - ." save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" ." save-mem s" 11 ." save-mem s\" [\"11\"]" save-mem 0 cwg-add-recipe
        s\" .\"" save-mem s\" : thi .\" hi\" ; thi" save-mem s\" [\"hi\"]" save-mem 1 cwg-add-recipe
        s" .s" save-mem s" 1 2 3 .s 2drop drop" save-mem s\" [\"<3> 1 2 3\"]" save-mem 0 cwg-add-recipe
        s" /" save-mem s" 10 3 / ." save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" /mod" save-mem s" 10 3 /mod . ." save-mem s\" [\"3\", \"1\"]" save-mem 0 cwg-add-recipe
        s" 0<" save-mem s" 1 negate 0< ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" 0=" save-mem s" 0 0= ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" 0>" save-mem s" 1 0> ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" 1+" save-mem s" 4 1+ ." save-mem s\" [\"5\"]" save-mem 0 cwg-add-recipe
        s" 1-" save-mem s" 4 1- ." save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" 2*" save-mem s" 5 2* ." save-mem s\" [\"10\"]" save-mem 0 cwg-add-recipe
        s" 2/" save-mem s" 10 2/ ." save-mem s\" [\"5\"]" save-mem 0 cwg-add-recipe
        s" 2drop" save-mem s" 1 2 3 2drop ." save-mem s\" [\"1\"]" save-mem 0 cwg-add-recipe
        s" 2dup" save-mem s" 4 5 2dup . . . ." save-mem s\" [\"5\", \"4\", \"5\", \"4\"]" save-mem 0 cwg-add-recipe
        s" :" save-mem s" : tplus 1 2 + . ; tplus" save-mem s\" [\"3\"]" save-mem 1 cwg-add-recipe
        s" ;" save-mem s" : tsemi 9 . ; tsemi" save-mem s\" [\"9\"]" save-mem 1 cwg-add-recipe
        s" <" save-mem s" 2 5 < ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" <>" save-mem s" 3 4 <> ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" =" save-mem s" 3 3 = ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" >" save-mem s" 5 2 > ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" >r" save-mem s" : ttr 5 >r r> . ; ttr" save-mem s\" [\"5\"]" save-mem 1 cwg-add-recipe
        s" ?do" save-mem s" : tqd 4 0 0 ?do 7 + loop . ; tqd" save-mem s\" [\"4\"]" save-mem 1 cwg-add-recipe
        s" ?dup" save-mem s" 0 ?dup ." save-mem s\" [\"0\"]" save-mem 0 cwg-add-recipe
        s" @" save-mem s" here 8 over ! @ ." save-mem s\" [\"8\"]" save-mem 0 cwg-add-recipe
        s" [" save-mem s" : tbr [ 7 . ] ; tbr" save-mem s\" [\"7\"]" save-mem 1 cwg-add-recipe
        s" [']" save-mem s" : trn ['] + execute . ; 1 2 trn" save-mem s\" [\"3\"]" save-mem 1 cwg-add-recipe
        s" [char]" save-mem s" : star [char] Q emit ; star" save-mem s\" [\"Q\"]" save-mem 1 cwg-add-recipe
        s" [compile]" save-mem s" : bng 33 emit ; immediate : cry2 [compile] bng ; cry2" save-mem s\" [\"!\"]" save-mem 1 cwg-add-recipe
        s" ]" save-mem s" : tbr2 [ 8 . ] ; tbr2" save-mem s\" [\"8\"]" save-mem 1 cwg-add-recipe
        s" abs" save-mem s" 5 negate abs ." save-mem s\" [\"5\"]" save-mem 0 cwg-add-recipe
        s" again" save-mem s" : tag 5 . exit begin again ; tag" save-mem s\" [\"5\"]" save-mem 1 cwg-add-recipe
        s" allot" save-mem s" here 1 allot here swap - ." save-mem s\" [\"1\"]" save-mem 0 cwg-add-recipe
        s" and" save-mem s" 3 1 and ." save-mem s\" [\"1\"]" save-mem 0 cwg-add-recipe
        s" base" save-mem s" base @ ." save-mem s\" [\"10\"]" save-mem 0 cwg-add-recipe
        s" begin" save-mem s" : tbe 0 begin 1+ dup 3 = until . ; tbe" save-mem s\" [\"3\"]" save-mem 1 cwg-add-recipe
        s" c!" save-mem s" here 66 over c! c@ ." save-mem s\" [\"66\"]" save-mem 0 cwg-add-recipe
        s" c," save-mem s" here 65 c, c@ ." save-mem s\" [\"65\"]" save-mem 0 cwg-add-recipe
        s" c@" save-mem s" here 67 over c! c@ ." save-mem s\" [\"67\"]" save-mem 0 cwg-add-recipe
        s" char" save-mem s" char B ." save-mem s\" [\"66\"]" save-mem 0 cwg-add-recipe
        s" constant" save-mem s" 11 constant kc kc ." save-mem s\" [\"11\"]" save-mem 0 cwg-add-recipe
        s" count" save-mem s" here 2 over c! 65 over 1+ c! count type" save-mem s\" [\"A\"]" save-mem 0 cwg-add-recipe
        s" cr" save-mem s" cr" save-mem s\" [\" ok\"]" save-mem 0 cwg-add-recipe
        s" create" save-mem s" : tcr create 7 , ; tcr q7 q7 @ ." save-mem s\" [\"7\"]" save-mem 1 cwg-add-recipe
        s" d+" save-mem s" 1 0 2 0 d+ . ." save-mem s\" [\"3\", \"0\"]" save-mem 0 cwg-add-recipe
        s" d-" save-mem s" 5 0 2 0 d- . ." save-mem s\" [\"3\", \"0\"]" save-mem 0 cwg-add-recipe
        s" d." save-mem s" 123 0 d." save-mem s\" [\"123\"]" save-mem 0 cwg-add-recipe
        s" depth" save-mem s" depth ." save-mem s\" [\"0\"]" save-mem 0 cwg-add-recipe
        s" do" save-mem s" : tdo 0 3 0 do i + loop . ; tdo" save-mem s\" [\"3\"]" save-mem 1 cwg-add-recipe
        s" does>" save-mem s" : tcn create , does> @ ; 23 tcn n23 n23 ." save-mem s\" [\"23\"]" save-mem 1 cwg-add-recipe
        s" drop" save-mem s" 9 8 drop ." save-mem s\" [\"8\"]" save-mem 0 cwg-add-recipe
        s" dup" save-mem s" 7 dup . ." save-mem s\" [\"7\", \"7\"]" save-mem 0 cwg-add-recipe
        s" else" save-mem s" : tel 0 if 1 else 8 then . ; tel" save-mem s\" [\"8\"]" save-mem 1 cwg-add-recipe
        s" emit" save-mem s" 51 emit" save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" execute" save-mem s" 1 2 ' + execute ." save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" exit" save-mem s" : tex 50 emit exit 51 emit ; tex" save-mem s\" [\"2\"]" save-mem 1 cwg-add-recipe
        s" here" save-mem s" here 0= ." save-mem s\" [\"0\"]" save-mem 0 cwg-add-recipe
        s" i" save-mem s" : tid 3 0 do i . loop ; tid" save-mem s\" [\"0\"]" save-mem 1 cwg-add-recipe
        s" if" save-mem s" : tif 0 if 1 else 2 then . ; tif" save-mem s\" [\"2\"]" save-mem 1 cwg-add-recipe
        s" immediate" save-mem s" : bang 33 emit ; immediate : cry postpone bang ; cry" save-mem s\" [\"!\"]" save-mem 1 cwg-add-recipe
        s" invert" save-mem s" 0 invert ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" j" save-mem s" : tjd 2 0 do 2 0 do j . loop loop ; tjd" save-mem s\" [\"0\"]" save-mem 1 cwg-add-recipe
        s" latest" save-mem s" latest @ 0= ." save-mem s\" [\"0\"]" save-mem 0 cwg-add-recipe
        s" leave" save-mem s" : tlv 0 5 0 do i 2 = if leave then 1+ loop . ; tlv" save-mem s\" [\"2\"]" save-mem 1 cwg-add-recipe
        s" literal" save-mem s" : tlit 42 literal ; tlit ." save-mem s\" [\"42\"]" save-mem 1 cwg-add-recipe
        s" loop" save-mem s" : tlp 0 4 0 do 1+ loop . ; tlp" save-mem s\" [\"4\"]" save-mem 1 cwg-add-recipe
        s" lshift" save-mem s" 1 3 lshift ." save-mem s\" [\"8\"]" save-mem 0 cwg-add-recipe
        s" max" save-mem s" 8 3 max ." save-mem s\" [\"8\"]" save-mem 0 cwg-add-recipe
        s" min" save-mem s" 8 3 min ." save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" mod" save-mem s" 10 3 mod ." save-mem s\" [\"1\"]" save-mem 0 cwg-add-recipe
        s" negate" save-mem s" 5 negate ." save-mem s\" [\"-5\"]" save-mem 0 cwg-add-recipe
        s" nip" save-mem s" 1 2 nip ." save-mem s\" [\"2\"]" save-mem 0 cwg-add-recipe
        s" or" save-mem s" 1 2 or ." save-mem s\" [\"3\"]" save-mem 0 cwg-add-recipe
        s" over" save-mem s" 1 2 over ." save-mem s\" [\"1\"]" save-mem 0 cwg-add-recipe
        s" parse-name" save-mem s" : tpn parse-name 2drop ; tpn" save-mem s\" [\" ok\"]" save-mem 1 cwg-add-recipe
        s" postpone" save-mem s" : doplus postpone + ; immediate : addx doplus ; 9 4 addx ." save-mem s\" [\"13\"]" save-mem 1 cwg-add-recipe
        s" quit" save-mem s" : tquit quit ; tquit" save-mem s\" [\" ok\"]" save-mem 1 cwg-add-recipe
        s" r>" save-mem s" : tfr 6 >r r> . ; tfr" save-mem s\" [\"6\"]" save-mem 1 cwg-add-recipe
        s" r@" save-mem s" : tar 7 >r r@ . r> drop ; tar" save-mem s\" [\"7\"]" save-mem 1 cwg-add-recipe
        s" recurse" save-mem s" : tdn dup . dup 0= if drop else 1- recurse then ; 2 tdn" save-mem s\" [\"2\", \"1\", \"0\"]" save-mem 1 cwg-add-recipe
        s" repeat" save-mem s" : tre 2 begin dup while 1- repeat . ; tre" save-mem s\" [\"0\"]" save-mem 1 cwg-add-recipe
        s" rot" save-mem s" 1 2 3 rot ." save-mem s\" [\"1\"]" save-mem 0 cwg-add-recipe
        s" rshift" save-mem s" 8 2 rshift ." save-mem s\" [\"2\"]" save-mem 0 cwg-add-recipe
        s\" s\"" save-mem s\" : tsg s\" xyz\" type ; tsg" save-mem s\" [\"xyz\"]" save-mem 1 cwg-add-recipe
        s" s>d" save-mem s" 5 s>d . ." save-mem s\" [\"5\", \"0\"]" save-mem 0 cwg-add-recipe
        s" space" save-mem s" space" save-mem s\" [\" ok\"]" save-mem 0 cwg-add-recipe
        s" state" save-mem s" state @ ." save-mem s\" [\"0\"]" save-mem 0 cwg-add-recipe
        s" swap" save-mem s" 1 2 swap . ." save-mem s\" [\"1\", \"2\"]" save-mem 0 cwg-add-recipe
        s" then" save-mem s" : tth 1 if 4 then . ; tth" save-mem s\" [\"4\"]" save-mem 1 cwg-add-recipe
        s" to" save-mem s" 8 value vt 9 to vt vt ." save-mem s\" [\"9\"]" save-mem 0 cwg-add-recipe
        s" tuck" save-mem s" 1 2 tuck . . ." save-mem s\" [\"2\", \"1\", \"2\"]" save-mem 0 cwg-add-recipe
        s" type" save-mem s\" : ttyp s\" OKT\" type ; ttyp" save-mem s\" [\"OKT\"]" save-mem 1 cwg-add-recipe
        s" u." save-mem s" 10 u." save-mem s\" [\"10\"]" save-mem 0 cwg-add-recipe
        s" u<" save-mem s" 1 2 u< ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" u>" save-mem s" 2 1 u> ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" unloop" save-mem s" : tul 4 0 do i 2 = if unloop exit then loop 9 . ; tul" save-mem s\" [\" ok\"]" save-mem 1 cwg-add-recipe
        s" until" save-mem s" : tun 0 begin 1+ dup 4 = until . ; tun" save-mem s\" [\"4\"]" save-mem 1 cwg-add-recipe
        s" value" save-mem s" 8 value vv vv ." save-mem s\" [\"8\"]" save-mem 0 cwg-add-recipe
        s" variable" save-mem s" variable vx 5 vx ! vx @ ." save-mem s\" [\"5\"]" save-mem 0 cwg-add-recipe
        s" while" save-mem s" : twi 3 begin dup while 1- repeat . ; twi" save-mem s\" [\"0\"]" save-mem 1 cwg-add-recipe
        s" within" save-mem s" 5 2 8 within ." save-mem s\" [\"-1\"]" save-mem 0 cwg-add-recipe
        s" words" save-mem s" words" save-mem s\" [\"dup\"]" save-mem 0 cwg-add-recipe
        s" xor" save-mem s" 3 1 xor ." save-mem s\" [\"2\"]" save-mem 0 cwg-add-recipe
    ;
    : cwg-load-skips ( -- )
        0 cwg-skip-n !
        s" 'boot" save-mem s" boot vector" save-mem 0 cwg-add-skip-k
        s" 'boot" save-mem s" boot vector" save-mem 0 cwg-add-skip-k
        s" p1!" save-mem s" pin side effect" save-mem 2 cwg-add-skip-k
        s" p3!" save-mem s" pin side effect" save-mem 2 cwg-add-skip-k
        s" led" save-mem s" pin side effect" save-mem 2 cwg-add-skip-k
        s" dly" save-mem s" busy wait side effect" save-mem 0 cwg-add-skip-k
        s" ms" save-mem s" busy wait side effect" save-mem 0 cwg-add-skip-k
        s" wait" save-mem s" busy wait side effect" save-mem 0 cwg-add-skip-k
        s" key?" save-mem s" blocks on UART" save-mem 0 cwg-add-skip-k
        s" key" save-mem s" blocks on UART" save-mem 0 cwg-add-skip-k
        s" accept" save-mem s" reads a line / nested interpret" save-mem 0 cwg-add-skip-k
        s" refill" save-mem s" reads a line / nested interpret" save-mem 0 cwg-add-skip-k
        s" evaluate" save-mem s" reads a line / nested interpret" save-mem 0 cwg-add-skip-k
        s" quit" save-mem s" leaves/aborts the interpreter" save-mem 0 cwg-add-skip-k
        s" abort" save-mem s" leaves/aborts the interpreter" save-mem 0 cwg-add-skip-k
        s\" abort\"" save-mem s" leaves/aborts the interpreter" save-mem 0 cwg-add-skip-k
        s" throw" save-mem s" aborts on nonzero" save-mem 0 cwg-add-skip-k
        s" io@" save-mem s" hardware address" save-mem 0 cwg-add-skip-k
        s" io!" save-mem s" hardware address" save-mem 0 cwg-add-skip-k
        s" compile-" save-mem s" compiler/parser helper" save-mem 1 cwg-add-skip-k
        s" mark-if" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" resolve" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" jump" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" branch0" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" cbranch" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" liter" save-mem s" compiler/parser helper" save-mem 1 cwg-add-skip-k
        s" slit" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" postponed" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" quote" save-mem s" compiler/parser helper" save-mem 1 cwg-add-skip-k
        s" digit" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" dq" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" dr" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" es," save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" et" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" hld" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" interp" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" lastcfa" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" lit!" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" lsp" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" lstk" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" namec" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" nhook" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" nidx" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" nstep" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" opti" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" pic" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" pl," save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" radix" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" src" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" tchar" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" tibc" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" unleaves" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" word" save-mem s" compiler/parser helper" save-mem 0 cwg-add-skip-k
        s" find" save-mem s" no counted-string helpers / input parser" save-mem 0 cwg-add-skip-k
        s" parse-name" save-mem s" no counted-string helpers / input parser" save-mem 0 cwg-add-skip-k
        s" parse" save-mem s" no counted-string helpers / input parser" save-mem 0 cwg-add-skip-k
        s" execute" save-mem s" no tick to obtain an xt" save-mem 0 cwg-add-skip-k
        s" type" save-mem s\" recipe needs a target colon and s\"" save-mem 0 cwg-add-skip-k
        s" allot" save-mem s" writes/moves flash HERE" save-mem 0 cwg-add-skip-k
        s" ," save-mem s" writes/moves flash HERE" save-mem 0 cwg-add-skip-k
        s" :" save-mem s" target colon does not create a header / only clears STATE" save-mem 0 cwg-add-skip-k
        s" ;" save-mem s" target colon does not create a header / only clears STATE" save-mem 0 cwg-add-skip-k
        s" r>" save-mem s" needs a working target colon" save-mem 0 cwg-add-skip-k
        s" >r" save-mem s" needs a working target colon" save-mem 0 cwg-add-skip-k
        s" r@" save-mem s" needs a working target colon" save-mem 0 cwg-add-skip-k
        s" exit" save-mem s" needs a working target colon" save-mem 0 cwg-add-skip-k
        s" empty" save-mem s" clears the data stack" save-mem 0 cwg-add-skip-k
        s" words" save-mem s" omitted for ROM budget" save-mem 0 cwg-add-skip-k
    ;

    cwg-load-recipes
    cwg-load-skips

    true constant con-words-gen-loaded
[THEN]
