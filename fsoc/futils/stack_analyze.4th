\ fsoc/futils/stack_analyze.4th — порт tools/stack_analyze.py
\ Анализатор стекового эффекта для целевых Forth-ядер.
\ Извлекает k-* слова из kernel.4th, сопоставляет с ANS контрактами,
\ выводит отчёт со стековыми эффектами (inputs/outputs/source/confidence).
\ Python-оригинал tools/stack_analyze.py сохранён без изменений.
\
\ Использование:
\   s" <kernel-file>" stack-analyze ( -- )
\   Печатает отчёт в stdout.
\
\ Пример:
\   s" fsys/kernel/bcpu/kernel.4th" stack-analyze

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    \ ------------------------------------------------------------------
    \ Все переменные модуля (все в начале файла)
    \ ------------------------------------------------------------------
    variable sa-ta variable sa-tu        \ текущий токен (addr len)
    variable sa-ts                       \ начало токена в буфере
    variable sa-ci variable sa-cok       \ для sa-str=
    variable sa-a variable sa-ua variable sa-b variable sa-vb

    variable sa-src variable sa-p variable sa-len

    variable sa-kw-n                     \ количество найденных k-слов
    variable sa-dst variable sa-wlen     \ для sa-store-kw
    create sa-kw-names 16384 allot       \ 256 слов по 64 байта
    create sa-kw-lens 256 allot          \ длины имён

    create sa-file-buf 65536 allot       \ буфер содержимого файла
    variable sa-file-l                   \ длина содержимого
    variable sa-fd                       \ файловый дескриптор
    create sa-path-buf 1024 allot        \ статический буфер пути к файлу
    variable sa-kern-a variable sa-kern-u   \ сохранённые аргументы пути
    variable sa-last-s-a variable sa-last-s-u   \ последнее s" имя (ANS-имя)

    \ ------------------------------------------------------------------
    \ Сравнение строк
    \ sa-str= ( a u b vb -- f )
    \ sa-starts-with ( a u b vb -- f )
    \ ------------------------------------------------------------------
    : sa-str= ( a u b vb -- f )
        >r >r >r >r
        r> sa-a !   r> sa-ua !   r> sa-b !   r> sa-vb !
        sa-ua @ sa-vb @ = if
            0 sa-ci ! 1 sa-cok !
            begin sa-cok @ 1 and sa-ci @ sa-ua @ u< and while
                sa-a @ sa-ci @ + c@ sa-b @ sa-ci @ + c@ <> if 0 sa-cok ! then
                1 sa-ci +!
            repeat
            sa-cok @
        else 0 then ;

    : sa-starts-with ( a u b vb -- f )
        >r >r >r >r
        r> sa-a !   r> sa-ua !   r> sa-b !   r> sa-vb !
        sa-ua @ sa-vb @ < if 0 exit then
        0 sa-ci ! 1 sa-cok !
        begin sa-cok @ 1 and sa-ci @ sa-vb @ u< and while
            sa-a @ sa-ci @ + c@ sa-b @ sa-ci @ + c@ <> if 0 sa-cok ! then
            1 sa-ci +!
        repeat
        sa-cok @ ;

    \ ------------------------------------------------------------------
    \ Статические строки-маркеры
    \ ------------------------------------------------------------------
    create sa-s-kword 6 allot   s" k-word"   sa-s-kword swap cmove   6 constant sa-l-s-kword
    create sa-s-jbword 6 allot  s" jb-word"  sa-s-jbword swap cmove  6 constant sa-l-s-jbword
    \ маркер — токен `s"` (2 байта: s + "); в тексте ядер имя всегда
    \ идёт отдельным токеном: `s" dup"` → токены `s"` и `dup"`
    create sa-s-dq    2 allot   115 sa-s-dq c!   34 sa-s-dq 1+ c!   2 constant sa-l-s-dq

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
        sa-tu !   \ sa-tu = name-u (TOS = len)
        sa-ta !   \ sa-ta = name-a (теперь TOS = addr)
        \ защита: пустое pending-имя (например, строка `: k-word ...`
        \ без s" на этой же строке) — не сохраняем и не читаем sa-ta-1
        sa-tu @ 0= if exit then
        \ убрать закрывающий " если есть (токен вида dup")
        sa-tu @ 1- sa-ta @ + c@ 34 = if
            sa-tu @ 1- sa-tu !
        then
        sa-kw-n @ 64 * sa-kw-names + sa-dst !   \ sa-dst = адрес записи
        sa-ta @ sa-dst @ sa-tu @ cmove   \ cmove(src=addr, dst=sa-dst, n=len)
        sa-kw-n @ sa-kw-lens + sa-tu @ swap c!   \ сохранить длину
        1 sa-kw-n +! ;

    \ ------------------------------------------------------------------
    \ Токенизатор по буферу sa-file-buf / sa-file-l
    \ ------------------------------------------------------------------
    : sa-is-ws ( c -- f )
        dup 32 = if drop 1 exit then
        dup 9 = if drop 1 exit then
        dup 13 = if drop 1 exit then
        dup 10 = if drop 1 exit then
        drop 0 ;

    : sa-cpeek ( -- c )
        sa-p @ sa-src @ + c@ ;

    : sa-skip-comment ( -- )
        begin
            sa-p @ sa-len @ u< while
                sa-cpeek 10 = if exit then
                1 sa-p +!
        repeat ;

    : sa-skip-ws ( -- )
        \ Пропускает весь пробельный текст (32/9/13/10) и комментарии `\`.
        \ Раньше потреблялся только 32: на LF скан зацикливался (пустой
        \ токен без продвижения sa-p). LF дополнительно сбрасывает
        \ line-scoped pending-имя — паритет с построчным regex python.
        begin
            sa-p @ sa-len @ u< 0= if exit then   \ конец буфера
            sa-cpeek   \ ( c )
            dup sa-is-ws if   \ ( c ) — пробельный символ
                dup 10 = if   \ ( c ) — LF: конец строки
                    drop
                    0 sa-last-s-a !   0 sa-last-s-u !
                else
                    drop
                then
                1 sa-p +!
            else   \ ( c ) — не пробел
                dup 92 = if   \ ( c ) — комментарий `\`
                    drop
                    sa-skip-comment   \ остаётся на LF — его съест этот же цикл
                else
                    drop
                    exit   \ начало токена
                then
            then
        again ;

    : sa-read-token ( -- a u f )
        sa-skip-ws
        sa-p @ sa-len @ u< if
            sa-p @ sa-ts !
            begin
                sa-p @ sa-len @ u< while
                    sa-cpeek   \ ( c )
                    dup sa-is-ws   \ ( c f )
                    if   \ ( c f ) → consume flag → ( c )
                        drop   \ () — whitespace, end of token
                        sa-file-buf sa-ts @ +   \ адрес начала токена
                        sa-p @ sa-ts @ -        \ длина токена
                        1                       \ флаг успеха
                        exit
                    then   \ ( c ) — not whitespace
                    drop   \ ()
                    1 sa-p +!
                repeat
                sa-file-buf sa-ts @ +   \ адрес конца токена (до конца буфера)
                sa-p @ sa-ts @ -        \ оставшаяся длина
                1
            else
                0 0 0
            then ;

    : sa-next-token ( -- f )
        sa-read-token   \ (a u f)
        >r              \ (a u) R:(f)
        sa-tu !         \ (a)   sa-tu = u
        sa-ta !         \ ()    sa-ta = a
        r>              \ (f)   вернуть f
    ;

    \ ------------------------------------------------------------------
    \ Чтение файла
    \ sa-read-file ( path-a path-u -- count ) — читает файл в sa-file-buf
    \ ------------------------------------------------------------------
    : sa-read-file ( path-a path-u -- count )
        r/o open-file throw   \ (fileid)
        sa-fd !               \ sa-fd = fileid, стек пуст
        sa-file-buf 65536 sa-fd @ read-file   \ (count ior)
        drop                  \ убрать ior, стек: (count)
        dup sa-file-l !       \ sa-file-l = count, count remains on stack
        sa-fd @ close-file throw   \ () закрываем fileid, стек (count)
        ;

    \ ------------------------------------------------------------------
    \ Сканирование kernel.4th — извлекает имена k-/jb-слов
    \ Паттерн: s" name" N s" impl" k-pc k-word  (или jb-pc jb-word)
    \ Сохраняем ANS-имя (первое s"), а не имя реализации (второе s").
    \ ------------------------------------------------------------------
    \ ------------------------------------------------------------------
    \ sa-scan-loop ( -- ) — основной цикл сканирования sa-file-buf.
    \ Токен `s"` → следующий токен = ANS-имя (первое на строке, pending);
    \ `k-word`/`jb-word` → сохранить pending и сбросить.
    \ Сброс pending на LF живёт в sa-skip-ws (построчный паритет python).
    \ ------------------------------------------------------------------
    : sa-scan-loop ( -- )
        begin
            sa-next-token 0= if exit then
            sa-ta @ sa-tu @ sa-s-dq sa-l-s-dq sa-str= if
                sa-next-token 0= if exit then
                \ ANS-имя = первое s" этой строки
                sa-last-s-u @ 0= if
                    sa-ta @ sa-last-s-a !   sa-tu @ sa-last-s-u !
                    \ убрать закрывающий " если есть (токен вида dup")
                    sa-last-s-u @ 1- sa-last-s-a @ + c@ 34 = if
                        sa-last-s-u @ 1- sa-last-s-u !
                    then
                then
            else
                sa-ta @ sa-tu @ sa-s-kword sa-l-s-kword sa-str= if
                    sa-last-s-a @ sa-last-s-u @ sa-store-kw
                    0 sa-last-s-a !   0 sa-last-s-u !   \ сбросили после сохранения
                then
                sa-ta @ sa-tu @ sa-s-jbword sa-l-s-jbword sa-str= if
                    sa-last-s-a @ sa-last-s-u @ sa-store-kw
                    0 sa-last-s-a !   0 sa-last-s-u !   \ сбросили после сохранения
                then
            then
        again ;

    : sa-scan-kernel-file ( path-a path-u -- )
        swap sa-kern-a !   \ sa-kern-a = addr
        sa-kern-u !   \ sa-kern-u = len
        sa-kern-a @ sa-path-buf sa-kern-u @ cmove   \ скопировать путь
        sa-path-buf sa-kern-u @ sa-read-file drop   \ читаем файл по статическому пути
        sa-file-buf sa-src ! sa-file-l @ sa-len ! 0 sa-p !
        0 sa-kw-n !
        0 sa-last-s-a !   0 sa-last-s-u !
        sa-scan-loop ;

    \ ------------------------------------------------------------------
    \ sa-contract-by-name ( name-a name-u -- in-count out-count | -1 )
    \ Жёсткие ANS контракты (как в Python from_ans_contract)
    \ ------------------------------------------------------------------
    : sa-contract-by-name ( name-a name-u -- in-count out-count | -1 )
        sa-tu !   \ sa-tu = name-u (TOS = len)
        sa-ta !   \ sa-ta = name-a (теперь TOS = addr)
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
        dup sa-kw-lens + c@   \ (idx len)
        >r   \ R: len, stack: (idx)
        64 * sa-kw-names + r>   \ (addr len)
        2dup type ."  -> "   \ напечатать имя
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
        sa-scan-kernel-file
        ." Stack analysis report" cr
        ." ==================" cr
        sa-kw-n @ 0 ?do
            i sa-print-effects
        loop
        ." Total words: " sa-kw-n @ . cr
        ;

    true constant stack-analyze-loaded
