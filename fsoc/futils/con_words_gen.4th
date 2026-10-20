\ fsoc/futils/con_words_gen.4th — порт tools/con_words_gen.py
\ Генерирует {CPU}_RUN / {CPU}_COLON / {CPU}_SKIP / {CPU}_CORE_HAS
\ из kernel.4th + встроенных тестовых рецептов.
\ Python-оригинал tools/con_words_gen.py сохранён без изменений.
\
\ Использование:
\   s" <cpu>" s" <kernel-dir>" con-words-gen ( -- )
\   Печатает сгенерированный Python-код в stdout.
\
\ Пример:
\   s" bcpu" s" fsys/kernel/bcpu" con-words-gen
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
        r> cwg-vb !   r> cwg-b !   r> cwg-ua !   r> cwg-a !
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
        r> cwg-vb !   r> cwg-b !   r> cwg-ua !   r> cwg-a !
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
    create cwg-s-dq    1 allot   s" "        cwg-s-dq    swap cmove      1 constant cwg-l-s-dq

    \ ------------------------------------------------------------------
    : cwg-store-kw ( name-a name-u -- )
        cwg-kw-n @ 64 * cwg-kw-names + cwg-dst !   \ dst в переменную, стек (name-a name-u)
        dup cwg-wlen !   \ (name-a) cwg-wlen = name-u
        cwg-ta !   \ () cwg-ta = name-a — имя сохранено
        cwg-ta @ cwg-dst @ cwg-wlen @ cmove   \ cmove(src=name-a, dst=адрес, n=name-u)
        cwg-kw-n @ cwg-kw-lens-arr + cwg-wlen c!   \ сохранить длину
        1 cwg-kw-n +! ;

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
        cwg-file-buf swap 32768 u< if   \ path-u < 32768
            cwg-file-buf swap cmove   \ cmove(src=path-a, dst=cwg-file-buf, n=path-u)
            cwg-readwhole drop
            cwg-file-buf cwg-src ! cwg-file-l @ cwg-len ! 0 cwg-p !
            0 cwg-last-s-a !   0 cwg-last-s-u !
            begin
                cwg-next-token cwg-tok-f @ 0= if exit then
                cwg-ta @ cwg-tu @ cwg-s-dq cwg-l-s-dq cwg-str= if
                    cwg-next-token cwg-tok-f @ 0= if exit then
                    cwg-ta cwg-last-s-a !   cwg-tu cwg-last-s-u !
                else
                    cwg-ta @ cwg-tu @ cwg-s-kword cwg-l-s-kword cwg-str= if
                        cwg-last-s-a @ cwg-last-s-u @ cwg-store-kw
                    then
                    cwg-ta @ cwg-tu @ cwg-s-jbword cwg-l-s-jbword cwg-str= if
                        cwg-last-s-a @ cwg-last-s-u @ cwg-store-kw
                    then
                then
            again
        else
            2drop
        then ;

    \ ------------------------------------------------------------------
    \ con-words-gen ( cpu-a cpu-u kern-a kern-u -- )
    \ ------------------------------------------------------------------
    : con-words-gen ( cpu-a cpu-u kern-a kern-u -- )
        >r >r >r >r
        r> cwg-kern-u !
        r> cwg-kern-a !
        0 cwg-kw-n !
        cwg-kern-a @ cwg-kern-u @ cwg-scan-kernel-file
        cwg-list-words
        ;

    true constant con-words-gen-loaded
[THEN]
FORTH_EOF
echo "written"