\ fsoc/futils/con_words_gen.4th — порт tools/con_words_gen.py
\ Извлекает ANS-имена слов из kernel.4th.
\ Python-оригинал tools/con_words_gen.py сохранён без изменений.
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
        cwg-wlen @ cwg-dst @ cwg-ta @ cmove   \ cmove(src=name-a, dst=адрес, n=name-u)
        cwg-kw-n @ cwg-kw-lens-arr + cwg-wlen c!   \ сохранить длину
        1 cwg-kw-n +! ;

    \ ------------------------------------------------------------------
    \ Токенизатор
    \ ------------------------------------------------------------------
    : cwg-is-ws ( c -- f )
        dup 32 = if drop 1 exit then
        dup 9 = if drop 1 exit then
        dup 13 = if drop 1 exit then
        10 = ;
    : cwg-cpeek ( -- c )
        cwg-p @ cwg-src @ + c@ ;
    : cwg-skip-ws ( -- )
        begin
            cwg-p @ cwg-len @ u< while
                cwg-cpeek cwg-is-ws if 1 cwg-p +! else exit then
            repeat ;

    : cwg-read-token ( -- a u f )
        cwg-skip-ws
        cwg-p @ cwg-len @ u< if
            cwg-p @ cwg-ts !
            begin
                cwg-p @ cwg-len @ u< while
                    cwg-cpeek cwg-is-ws if
                        cwg-src @ cwg-ts @ + cwg-p @ cwg-ts @ - 1
                        exit
                    then
                    1 cwg-p +!
                repeat
                cwg-src @ cwg-ts @ + cwg-p @ cwg-ts @ - 1
            else
                0 0 0
            then ;

    : cwg-next-token ( -- f )
        cwg-read-token >r cwg-ta ! r> cwg-tu ! ;

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
    \ Вывод
    \ ------------------------------------------------------------------
    : cwg-print-word ( idx -- )
        64 * cwg-kw-names +   \ адрес i-го слова
        cwg-kw-lens-arr + c@   \ длина
        type cr ;

    : cwg-list-words ( -- )
        cwg-kw-n @ 0 ?do
            i cwg-print-word
        loop ;

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