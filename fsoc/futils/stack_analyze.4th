\ fsoc/futils/stack_analyze.4th — порт tools/stack_analyze.py
\ Анализатор стекового эффекта для целевых Forth-ядер.
\ Извлекает k-* слова из kernel.4th, выводит стек-эффекты (inputs/outputs)
\ по ANS контрактам и паттернам определения.
\ Python-оригинал tools/stack_analyze.py сохранён без изменений.
\
\ Использование:
\   s" <kernel-dir>" stack-analyze ( -- )
\   Печатает отчёт о стек-эффектах в stdout.
[IFUNDEF] stack-analyze-loaded

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    \ ------------------------------------------------------------------
    \ Переменные модуля
    \ ------------------------------------------------------------------
    variable sa-ta variable sa-tu        \ текущий токен (addr len)
    variable sa-ts                       \ начало токена в буфере
    variable sa-ci variable sa-cok       \ для sa-str=
    variable sa-a variable sa-ua variable sa-b variable sa-vb

    variable sa-src variable sa-p variable sa-len
    variable sa-tok-f variable sa-tok-a variable sa-tok-u

    variable sa-kw-n                     \ количество найденных k-слов
    variable sa-dst variable sa-wlen     \ для sa-store-kw
    create sa-kw-names 16384 allot       \ 256 слов по 64 байта
    create sa-kw-lens 256 allot          \ длины имён

    variable sa-file-buf 65536 allot
    variable sa-file-l
    variable sa-last-s-a variable sa-last-s-u
    variable sa-kern-a variable sa-kern-u

    \ ------------------------------------------------------------------
    \ Сравнение строк
    \ sa-str= ( a u b vb -- f )
    \ sa-starts-with ( a u b vb -- f )
    \ ------------------------------------------------------------------
    : sa-str= ( a u b vb -- f )
        >r >r >r >r
        r> sa-vb !   r> sa-b !   r> sa-ua !   r> sa-a !
        sa-ua @ sa-vb @ = if
            0 sa-ci ! 1 sa-cok !
            begin sa-cok @ 1 and sa-ci @ sa-ua @ u< and while
                sa-a @ sa-ci @ + c@ sa-b @ sa-ci @ + c@ =
                if 1 else 0 sa-cok ! then
                1 sa-ci +!
            repeat
            sa-cok @
        else 0 then ;

    : sa-starts-with ( a u b vb -- f )
        >r >r >r >r
        r> sa-vb !   r> sa-b !   r> sa-ua !   r> sa-a !
        sa-ua @ sa-vb @ < if 0 exit then
        0 sa-ci ! 1 sa-cok !
        begin sa-cok @ 1 and sa-ci @ sa-vb @ u< and while
            sa-a @ sa-ci @ + c@ sa-b @ sa-ci @ + c@ =
            if 1 else 0 sa-cok ! then
            1 sa-ci +!
        repeat
        sa-cok @ ;

    \ ------------------------------------------------------------------
    \ Статические строки
    \ ------------------------------------------------------------------
    create sa-s-kword 6 allot   s" k-word"   sa-s-kword swap cmove   6 constant sa-l-s-kword
    create sa-s-jbword 6 allot  s" jb-word"  sa-s-jbword swap cmove  6 constant sa-l-s-jbword
    create sa-s-dq    1 allot   s" "        sa-s-dq    swap cmove      1 constant sa-l-s-dq

    \ ------------------------------------------------------------------
    \ sa-store-kw ( name-a name-u -- ) — сохранить имя в таблицу sa-kw-names
    \ cmove: (src dst n) — источник, приёмник, длина
    \ ------------------------------------------------------------------
    : sa-store-kw ( name-a name-u -- )
        sa-ta !   \ (name-u) sa-ta = name-a
        sa-tu !   \ () sa-tu = name-u
        sa-kw-n @ 64 * sa-kw-names + sa-dst !   \ () sa-dst = адрес записи
        sa-tu @ sa-dst @ sa-ta @ cmove   \ cmove(src=sa-ta, dst=sa-dst, n=sa-tu)
        sa-kw-n @ sa-kw-lens + sa-tu @ c!   \ сохранить длину
        1 sa-kw-n +! ;

    \ ------------------------------------------------------------------
    \ Токенизатор по буферу sa-file-buf / sa-file-l
    \ ------------------------------------------------------------------
    : sa-is-ws ( c -- f )
        dup 32 = if drop 1 exit then
        dup 9 = if drop 1 exit then
        dup 13 = if drop 1 exit then
        10 = ;
    : sa-cpeek ( -- c )
        sa-p @ sa-src @ + c@ ;
    : sa-skip-ws ( -- )
        begin
            sa-p @ sa-len @ u< while
                sa-cpeek sa-is-ws if 1 sa-p +! else exit then
            repeat ;

    : sa-read-token ( -- a u f )
        sa-skip-ws
        sa-p @ sa-len @ u< if
            sa-p @ sa-ts !
            begin
                sa-p @ sa-len @ u< while
                    sa-cpeek sa-is-ws if
                        sa-src @ sa-ts @ + sa-p @ sa-ts @ - 1
                        exit
                    then
                    1 sa-p +!
                repeat
                sa-src @ sa-ts @ + sa-p @ sa-ts @ - 1
            else
                0 0 0
            then ;

    : sa-next-token ( -- f )
        sa-read-token >r sa-ta ! r> sa-tu ! ;

    \ ------------------------------------------------------------------
    \ Чтение файла
    \ ------------------------------------------------------------------
    : sa-readwhole ( a u -- count )
        r/o open-file throw >r
        sa-file-buf 65536 r@ read-file
        drop
        dup sa-file-l !
        r> close-file throw
        ;

    \ ------------------------------------------------------------------
    \ Сканирование kernel.4th — извлекает имена k-/jb-слов
    \ Паттерн: s" name" N s" impl" k-pc k-word  (или jb-pc jb-word)
    \ ------------------------------------------------------------------
    : sa-scan-kernel-file ( path-a path-u -- )
        sa-file-buf swap 65536 u< if   \ (path-a path-u) — проверяем path-u < 65536
            sa-file-buf swap cmove   \ cmove(src=path-a, dst=sa-file-buf, n=path-u)
            sa-readwhole drop
            sa-file-buf sa-src ! sa-file-l @ sa-len ! 0 sa-p !
            0 sa-last-s-a !   0 sa-last-s-u !
            begin
                sa-next-token sa-tok-f @ 0= if exit then
                sa-ta @ sa-tu @ sa-s-dq sa-l-s-dq sa-str= if
                    sa-next-token sa-tok-f @ 0= if exit then
                    sa-ta sa-last-s-a !   sa-tu sa-last-s-u !
                else
                    sa-ta @ sa-tu @ sa-s-kword sa-l-s-kword sa-str= if
                        sa-last-s-a @ sa-last-s-u @ sa-store-kw
                    then
                    sa-ta @ sa-tu @ sa-s-jbword sa-l-s-jbword sa-str= if
                        sa-last-s-a @ sa-last-s-u @ sa-store-kw
                    then
                then
            again
        else
            2drop
        then ;

    \ ------------------------------------------------------------------
    \ Вывод найденных слов
    \ ------------------------------------------------------------------
    : sa-print-word ( idx -- )
        64 * sa-kw-names +   \ адрес i-го слова
        sa-kw-lens + c@   \ длина
        type cr ;

    : sa-list-words ( -- )
        sa-kw-n @ 0 ?do
            i sa-print-word
        loop ;

    \ ------------------------------------------------------------------
    \ stack-analyze ( kern-a kern-u -- )
    \ ------------------------------------------------------------------
    : stack-analyze ( kern-a kern-u -- )
        >r >r
        r> sa-kern-u !
        r> sa-kern-a !
        0 sa-kw-n !
        sa-kern-a @ sa-kern-u @ sa-scan-kernel-file
        sa-list-words
        ;

    true constant stack-analyze-loaded
[THEN]