\ fsoc/futils/stack_analyze.4th — порт tools/stack_analyze.py
\ Анализатор стекового эффекта для целевых Forth-ядер.
\ Извлекает k-* слова из kernel.4th, сопоставляет с ANS контрактами,
\ выводит отчёт со стековыми эффектами (inputs/outputs/source/confidence).
\ Python-оригинал tools/stack_analyze.py сохранён без изменений.
\
\ Использование:
\   s" <kernel-dir>" stack-analyze ( -- )
\   Печатает отчёт в stdout.
\
\ Пример:
\   s" fsys/kernel/bcpu" stack-analyze
[IFUNDEF] stack-analyze-loaded

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    \ ------------------------------------------------------------------
    \ Переменные модуля (все на одном уровне)
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

    variable sa-file-buf 65536 allot     \ буфер содержимого файла
    variable sa-file-l                   \ длина содержимого
    create sa-path-buf 1024 allot        \ статический буфер пути к файлу
    variable sa-fd                       \ файловый дескриптор
    variable sa-last-s-a variable sa-last-s-u   \ последнее s" имя

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
    \ Статические строки-маркеры
    \ ------------------------------------------------------------------
    create sa-s-kword 6 allot   s" k-word"   sa-s-kword swap cmove   6 constant sa-l-s-kword
    create sa-s-jbword 6 allot  s" jb-word"  sa-s-jbword swap cmove  6 constant sa-l-s-jbword
    create sa-s-dq    1 allot   s" "        sa-s-dq    swap cmove      1 constant sa-l-s-dq

    create sa-s-dup    3 allot   s" dup"   sa-s-dup   swap cmove    3 constant sa-l-s-dup
    create sa-s-drop   4 allot   s" drop"  sa-s-drop  swap cmove    4 constant sa-l-s-drop
    create sa-s-swap   4 allot   s" swap"  sa-s-swap  swap cmove    4 constant sa-l-s-swap
    create sa-s-over   4 allot   s" over" sa-s-over   swap cmove    4 constant sa-l-s-over
    create sa-s-rot    3 allot   s" rot"  sa-s-rot   swap cmove     3 constant sa-l-s-rot
    create sa-s-plus   1 allot   s" +"    sa-s-plus   swap cmove     1 constant sa-l-s-plus
    create sa-s-minus  1 allot   s" -"   sa-s-minus  swap cmove     1 constant sa-l-s-minus
    create sa-s-and    3 allot   s" and" sa-s-and   swap cmove      3 constant sa-l-s-and
    create sa-s-or     2 allot   s" or"  sa-s-or   swap cmove       2 constant sa-l-s-or
    create sa-s-eq     1 allot   s" ="   sa-s-eq   swap cmove       1 constant sa-l-s-eq
    create sa-s-fetch  1 allot   s" @"   sa-s-fetch  swap cmove     1 constant sa-l-s-fetch
    create sa-s-store  1 allot   s" !"   sa-s-store  swap cmove     1 constant sa-l-s-store
    create sa-s-dot    1 allot   s" ."   sa-s-dot   swap cmove      1 constant sa-l-s-dot
    create sa-s-cr     2 allot   s" cr"  sa-s-cr   swap cmove       2 constant sa-l-s-cr
    create sa-s-emit   4 allot   s" emit" sa-s-emit   swap cmove    4 constant sa-l-s-emit

    \ ------------------------------------------------------------------
    \ sa-store-kw ( name-a name-u -- ) — сохранить имя в таблицу
    \ cmove: (src dst n)
    \ ------------------------------------------------------------------
    : sa-store-kw ( name-a name-u -- )
        sa-ta !   \ (name-u) sa-ta = name-a
        sa-tu !   \ () sa-tu = name-u
        sa-kw-n @ 64 * sa-kw-names + sa-dst !   \ () sa-dst = адрес записи
        sa-ta @ sa-dst @ sa-tu @ cmove   \ cmove(src=sa-ta, dst=sa-dst, n=sa-tu)
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
    \ sa-read-file ( path-a path-u -- count ) — читает файл в sa-file-buf
    \ ------------------------------------------------------------------
    : sa-read-file ( path-a path-u -- count )
        r/o open-file throw   \ (fileid ior)
        swap >r drop          \ () убрать ior, r: fileid
        r> sa-fd !            \ () sa-fd = fileid
        sa-file-buf 65536 sa-fd @ read-file   \ (ior) — читаем в sa-file-buf
        drop                  \ убрать ior
        \ определить длину по первому NUL байту
        0
        begin
            dup 65536 u< if
                sa-file-buf swap + c@
                if 1+ else exit then
            else exit then
        again
        dup sa-file-l !       \ sa-file-l = count, count остаётся на стеке
        sa-fd @ close-file throw   \ () закрываем fileid, стек (count)
        ;

    \ ------------------------------------------------------------------
    \ Сканирование kernel.4th — извлекает имена k-/jb-слов
    \ Паттерн: s" name" N s" impl" k-pc k-word  (или jb-pc jb-word)
    \ ------------------------------------------------------------------
    : sa-scan-kernel-file ( path-a path-u -- )
        sa-ta !   \ (path-u) sa-ta = path-а
        sa-tu !   \ () sa-tu = path-у
        sa-tu @ 65536 u< if   \ проверяем path-у < 65536
            sa-ta @ sa-path-buf sa-tu @ cmove   \ cmove(src=path-а, dst=sa-path-buf, n=path-у)
            sa-path-buf sa-tu @ sa-read-file drop   \ читаем файл по статическому пути
            sa-file-buf sa-src ! sa-file-l @ sa-len ! 0 sa-p !
            0 sa-kw-n !
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
    \ sa-contract-by-name ( name-a name-u -- in-count out-count | -1 )
    \ Жёсткие ANS контракты (как в Python from_ans_contract)
    \ ------------------------------------------------------------------
    : sa-contract-by-name ( name-a name-u -- in-count out-count | -1 )
        sa-ta ! sa-tu !
        sa-ta @ sa-tu @ sa-s-dup sa-l-s-dup sa-str= if 1 2 exit then
        sa-ta @ sa-tu @ sa-s-drop sa-l-s-drop sa-str= if 1 0 exit then
        sa-ta @ sa-tu @ sa-s-swap sa-l-s-swap sa-str= if 2 2 exit then
        sa-ta @ sa-tu @ sa-s-over sa-l-s-over sa-str= if 2 3 exit then
        sa-ta @ sa-tu @ sa-s-rot sa-l-s-rot sa-str= if 3 3 exit then
        sa-ta @ sa-tu @ sa-s-plus sa-l-s-plus sa-str= if 2 1 exit then
        sa-ta @ sa-tu @ sa-s-minus sa-l-s-minus sa-str= if 2 1 exit then
        sa-ta @ sa-tu @ sa-s-and sa-l-s-and sa-str= if 2 1 exit then
        sa-ta @ sa-tu @ sa-s-or sa-l-s-or sa-str= if 2 1 exit then
        sa-ta @ sa-tu @ sa-s-eq sa-l-s-eq sa-str= if 2 1 exit then
        sa-ta @ sa-tu @ sa-s-fetch sa-l-s-fetch sa-str= if 1 1 exit then
        sa-ta @ sa-tu @ sa-s-store sa-l-s-store sa-str= if 2 0 exit then
        sa-ta @ sa-tu @ sa-s-dot sa-l-s-dot sa-str= if 1 0 exit then
        sa-ta @ sa-tu @ sa-s-cr sa-l-s-cr sa-str= if 0 0 exit then
        sa-ta @ sa-tu @ sa-s-emit sa-l-s-emit sa-str= if 1 0 exit then
        -1 -1 ;

    \ ------------------------------------------------------------------
    \ sa-print-effects ( idx — ) — напечатать стек-эффект i-го слова
    \ ------------------------------------------------------------------
    : sa-print-effects ( idx -- )
        64 * sa-kw-names +   \ адрес имени
        sa-kw-lens + c@   \ длина имени
        2dup type   \ напечатать имя
        ."  -> "
        sa-contract-by-name   \ (in out | -1)
        dup -1 = if
            2drop ." unknown (no ANS contract)" cr
        else
            swap ." in=" . ." out=" . cr
        then ;

    : sa-list-effects ( -- )
        sa-kw-n @ 0 ?do
            i sa-print-effects
        loop ;

    \ ------------------------------------------------------------------
    \ stack-analyze ( kern-a kern-u -- )
    \ ------------------------------------------------------------------
    : stack-analyze ( kern-a kern-u -- )
        >r >r   \ r: kern-у kern-а (kern-а на верху r)
        r> sa-ta !   \ sa-ta = kern-а (addr)
        r> sa-tu !   \ sa-tu = kern-у (len)
        sa-tu @ 65536 u< if
            sa-ta @ sa-path-buf sa-tu @ cmove   \ скопировать путь в статический буфер
            sa-path-buf sa-tu @ sa-read-file drop   \ читаем файл
            sa-file-buf sa-src ! sa-file-l @ sa-len ! 0 sa-p !
            0 sa-kw-n !
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
        then
        ." Stack analysis report" cr
        ." ==================" cr
        sa-kw-n @ 0 ?do
            i sa-print-effects
        loop
        ." Total words: " sa-kw-n @ . cr
        ;

    true constant stack-analyze-loaded
[THEN]
