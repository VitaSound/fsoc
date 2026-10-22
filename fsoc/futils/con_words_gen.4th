\ fsoc/futils/con_words_gen.4th — извлечение ANS-имён слов из kernel.4th
\ (база tools/con_words_gen.py; python-оригинал сохранён без изменений).
\ cwg-scan-kernel-file заполняет массивы cwg-kw-names / cwg-kw-lens-arr;
\ con-words-gen сканирует kernel-файл и печатает список имён. Паритет
\ построчного regex python: имя = первое s" на строке, pending сбрасывается
\ на LF и после сохранения (k-word / jb-word).
\
\ WIP: каркас TEST_RECIPES / SKIP_PATTERNS (cwg-add-recipe / cwg-find-*)
\ и вывод RUN/COLON/SKIP — заготовка, генерация Python-кода не реализована.
\
\ Использование:
\   s" <cpu>" s" <kernel-path>" con-words-gen ( -- )
\ Пример:
\   s" bcpu" s" fsys/kernel/bcpu/kernel.4th" con-words-gen
[IFUNDEF] con-words-gen-loaded

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    \ ------------------------------------------------------------------
    \ Переменные на уровне модуля
    \ ------------------------------------------------------------------
    variable cwg-ta variable cwg-tu
    variable cwg-ci variable cwg-cok
    variable cwg-a variable cwg-ua variable cwg-b variable cwg-vb
    variable cwg-src variable cwg-p variable cwg-len
    variable cwg-tok-f variable cwg-tok-a variable cwg-tok-u
    variable cwg-ts
    variable cwg-last-s-a variable cwg-last-s-u
    variable cwg-kw-n
    variable cwg-kern-a variable cwg-kern-u
    variable cwg-dst variable cwg-wlen
    create cwg-kw-names 16384 allot
    create cwg-kw-lens-arr 256 allot
    create cwg-file-buf 32768 allot
    variable cwg-file-l

    \ ------------------------------------------------------------------
    : cwg-str= ( a u b vb -- f )
        >r >r >r >r
        r> cwg-a !   r> cwg-ua !   r> cwg-b !   r> cwg-vb !
        cwg-ua @ cwg-vb @ = if
            0 cwg-ci ! 1 cwg-cok !
            begin cwg-cok @ 1 and cwg-ci @ cwg-ua @ u< and while
                cwg-a @ cwg-ci @ + c@ cwg-b @ cwg-ci @ + c@ =
                if 1 else 0 cwg-cok ! then
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
            cwg-a @ cwg-ci @ + c@ cwg-b @ cwg-ci @ + c@ =
            if 1 else 0 cwg-cok ! then
            1 cwg-ci +!
        repeat
        cwg-cok @ ;

    \ ------------------------------------------------------------------
    \ Статические строки
    \ ------------------------------------------------------------------
    create cwg-s-kword 6 allot   s" k-word"   cwg-s-kword swap cmove   6 constant cwg-l-s-kword
    create cwg-s-jbword 6 allot  s" jb-word"  cwg-s-jbword swap cmove  6 constant cwg-l-s-jbword
    create cwg-s-dq    2 allot   115 cwg-s-dq c!   34 cwg-s-dq 1+ c!   2 constant cwg-l-s-dq   \ байты s"

    \ ------------------------------------------------------------------
    : cwg-store-kw ( name-a name-u -- )
        cwg-tu !   cwg-ta !
        cwg-tu @ 0= if exit then            \ пустой pending (def-строка без s")
        cwg-tu @ 1- cwg-ta @ + c@ 34 = if   \ strip закрывающей " (токен вида dup")
            cwg-tu @ 1- cwg-tu !
        then
        cwg-ta @ cwg-kw-n @ 64 * cwg-kw-names + cwg-tu @ cmove
        cwg-tu @ cwg-kw-n @ cwg-kw-lens-arr + c!
        1 cwg-kw-n +! ;

    \ ------------------------------------------------------------------
    \ Токенизатор (паритет stack_analyze): весь whitespace, комментарии `\`,
    \ LF сбрасывает line-scoped pending-имя.
    \ ------------------------------------------------------------------
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
        cwg-read-token
        >r cwg-tu ! cwg-ta ! r> ;

    \ ------------------------------------------------------------------
    \ cwg-scan-loop ( -- ) — цикл сканирования cwg-file-buf:
    \ токен `s"` → ANS-имя = первое s" этой строки (pending);
    \ `k-word`/`jb-word` → сохранить pending и сбросить.
    \ ------------------------------------------------------------------
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

    \ ------------------------------------------------------------------
    \ Таблица TEST_RECIPES (fenum)
    \ ------------------------------------------------------------------
    begin-structure cwg-recipe%
        field: r-name
        field: r-nlen
        field: r-line
        field: r-llen
        field: r-has
        field: r-hlen
        field: r-type
    end-structure
    variable cwg-recipe-n
    create cwg-recipe-names 4096 allot   \ 64 рецепта × 64 байта
    create cwg-recipe-lines 4096 allot
    create cwg-recipe-hashes 4096 allot
    create cwg-recipe-types 256 allot    \ 1 байт на рецепт (type)
    create cwg-recipe-nlens 256 allot
    create cwg-recipe-llens 256 allot
    create cwg-recipe-hlens 256 allot

    : cwg-add-recipe ( name-a name-u line-a line-u has-a has-u type -- )
        cwg-recipe-n @ 64 * cwg-recipe-names + cwg-dst !
        cwg-ta ! cwg-tu !   \ сохранить name
        cwg-ta @ cwg-dst @ cwg-tu @ cmove   \ скопировать name
        cwg-recipe-n @ cwg-recipe-nlens + cwg-tu c!   \ сохранить name-len
        \ line
        cwg-ta ! cwg-tu !
        cwg-recipe-n @ 64 * cwg-recipe-lines + cwg-dst !
        cwg-ta @ cwg-dst @ cwg-tu @ cmove   \ скопировать line
        cwg-recipe-n @ cwg-recipe-llens + cwg-tu c!   \ сохранить line-len
        \ has
        cwg-ta ! cwg-tu !
        cwg-recipe-n @ 64 * cwg-recipe-hashes + cwg-dst !
        cwg-ta @ cwg-dst @ cwg-tu @ cmove   \ скопировать has
        cwg-recipe-n @ cwg-recipe-hlens + cwg-tu c!   \ сохранить has-len
        \ type
        cwg-recipe-n @ cwg-recipe-types + swap c!   \ сохранить type
        1 cwg-recipe-n +! ;

    variable cwg-dst2 variable cwg-wlen2

    \ ------------------------------------------------------------------
    \ cwg-find-recipe ( name-a name-u -- idx|-1 )
    \ ------------------------------------------------------------------
    create cwg-rname 64 allot
    variable cwg-rnlen
    variable cwg-ri
    : cwg-find-recipe ( name-a name-u -- idx|-1 )
        cwg-ta ! cwg-tu !
        0 cwg-ri !
        begin
            cwg-ri @ cwg-recipe-n @ u< if
                cwg-ri @ 64 * cwg-recipe-names +   \ адрес i-го name
                dup cwg-rname swap cmove   \ скопировать в cwg-rname
                cwg-recipe-n @ cwg-recipe-nlens + c@ cwg-rnlen !   \ длина
                cwg-rname cwg-rnlen @ cwg-ta @ cwg-tu @ cwg-str=   \ сравнить
                if cwg-ri @ exit then   \ нашли
                1 cwg-ri +!
            else
                -1 exit   \ не нашли
            then
        again ;

    \ ------------------------------------------------------------------
    \ Таблица SKIP_PATTERNS (fenum)
    \ cwg-skip%: pattern-addr, pattern-len, reason-addr, reason-len
    \ ------------------------------------------------------------------
    begin-structure cwg-skip%
        field: s-pattern
        field: s-plen
        field: s-reason
        field: s-rlen
    end-structure
    variable cwg-skip-n
    create cwg-skip-patterns 4096 allot
    create cwg-skip-reasons 4096 allot
    create cwg-skip-plens 256 allot
    create cwg-skip-rlens 256 allot

    : cwg-add-skip ( pat-a pat-u rea-a rea-u -- )
        cwg-skip-n @ 64 * cwg-skip-patterns + cwg-dst !
        cwg-ta ! cwg-tu !   \ pat
        cwg-ta @ cwg-dst @ cwg-tu @ cmove   \ скопировать pattern
        cwg-skip-n @ cwg-skip-plens + cwg-tu c!   \ сохранить pattern-len
        cwg-ta ! cwg-tu !   \ reason
        cwg-skip-n @ 64 * cwg-skip-reasons + cwg-dst !
        cwg-ta @ cwg-dst @ cwg-tu @ cmove   \ скопировать reason
        cwg-skip-n @ cwg-skip-rlens + cwg-tu c!   \ сохранить reason-len
        1 cwg-skip-n +! ;

    : cwg-find-skip ( name-a name-u -- idx|-1 )
        cwg-ta ! cwg-tu !
        0
        begin
            over cwg-skip-n @ u< if   \ i < skip-n
                over 64 * cwg-skip-patterns +   \ адрес i-го pattern
                dup cwg-rname swap cmove   \ скопировать в cwg-rname
                cwg-skip-n @ cwg-skip-plens + c@ cwg-rnlen !   \ длина pattern
                cwg-rname cwg-rnlen @ cwg-ta @ cwg-tu @ cwg-starts-with   \ проверяем starts-with
                if over exit then   \ нашли, возвращаем i
                1+   \ i++
            else
                2drop -1 exit   \ не нашли
            then
        again ;

    \ ------------------------------------------------------------------
    \ Вывод результатов
    \ ------------------------------------------------------------------
    variable cwg-cpu-a variable cwg-cpu-u

    : cwg-print-quoted ( a u -- )
        cwg-l-s-dq emit   type   cwg-l-s-dq emit ;

    : cwg-print-entry ( type-addr type-len name-a name-u line-a line-u has-a has-u -- )
        over over type space   \ напечатать тип (RUN/COLON/SKIP)
        cwg-print-quoted   \ name
        ." ("
        cwg-print-quoted   \ line
        ." , "
        cwg-print-quoted   \ has
        ." )," cr ;

    \ ------------------------------------------------------------------
    \ Чтение файла
    \ ------------------------------------------------------------------
    : cwg-readwhole ( a u -- count )
        r/o open-file throw >r
        cwg-file-buf 32768 r@ read-file
        drop
        dup cwg-file-l !
        r> close-file throw
        ;

    \ ------------------------------------------------------------------
    \ Сканирование kernel.4th
    \ ------------------------------------------------------------------
    : cwg-scan-kernel-file ( path-a path-u -- )
        cwg-readwhole drop              \ файл → cwg-file-buf; count не нужен
        cwg-file-buf cwg-src ! cwg-file-l @ cwg-len ! 0 cwg-p !
        0 cwg-kw-n !
        0 cwg-last-s-a !   0 cwg-last-s-u !
        cwg-scan-loop ;

    \ ------------------------------------------------------------------
    \ cwg-print-word ( idx -- ) / cwg-list-words ( -- )
    \ ------------------------------------------------------------------
    : cwg-print-word ( idx -- )
        dup 64 * cwg-kw-names +      \ (idx name-a)
        swap cwg-kw-lens-arr + c@    \ (name-a name-u)
        type cr ;

    : cwg-list-words ( -- )
        cwg-kw-n @ 0 ?do
            i cwg-print-word
        loop ;

    \ ------------------------------------------------------------------
    \ con-words-gen ( cpu-a cpu-u kern-a kern-u -- )
    \ ------------------------------------------------------------------
    : con-words-gen ( cpu-a cpu-u kern-a kern-u -- )
        2swap cwg-cpu-u ! cwg-cpu-a !
        cwg-kern-u ! cwg-kern-a !
        cwg-kern-a @ cwg-kern-u @ cwg-scan-kernel-file
        cwg-list-words ;

    true constant con-words-gen-loaded
[THEN]
