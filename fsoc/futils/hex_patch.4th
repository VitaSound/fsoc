\ fsoc/futils/hex_patch.4th — Работа с hex-данными в памяти (in-memory)
\ Зеркало Python-утилит проекта (hex-обработка из tools/fix_branches.py,
\ tools/patch_firmware.py, tests/*.py).
\
\ Назначение: парсинг hex-строк, поиск байтовых паттернов, патчинг,
\             z80 if/else (zbranch) автопатчинг.
\
\ Sémantique Gforth 0.7.9_20250101 (подтверждено прямыми пробами):
\   c! : ( c a-addr -- )   — значение СВЕРХУ, адрес снизу (ANS).
\   c@ : ( a-addr -- c )   — адрес сверху.
\   !  : ( x a-addr -- )   — значение сверху.
\   @  : ( a-addr -- x )
\
\ ИДИОМЫ:
\  - hex-цифры через таблицу hex-digit-tab (256 байт, конвенция digit+1)
\  - циклы: begin...while/repeat с переменными-счётчиками (do...loop
\    с c! в этой сборке вешается)
\  - "не найдено" = -1 (0 — валидный адрес буфера)
\  - hex-buffer/hex-len — общее состояние; патч-функции его изменяют

[IFUNDEF] hex-patch-loaded
    decimal

    \ ------------------------------------------------------------------
    \ Буферы и переменные
    \ ------------------------------------------------------------------
    create hex-buffer    65536 allot
    create hex-digit-tab  256 allot

    variable hex-len
    variable hex-acc
    variable hex-src
    variable hex-src-len
    variable hex-pos
    variable line-start
    variable buf-base
    variable buf-len
    variable find-addr
    variable find-start
    variable find-i
    variable find-z
    variable patch-new
    variable found
    variable pat-addr
    variable pat-len
    variable pw-addr
    variable pm-match
    variable pm-pos

    \ ------------------------------------------------------------------
    \ Таблица hex-цифр. Конвенция: 0 = "не цифра"; иначе digit+1
    \ (байт 0 зарезервирован: 0 — валидная hex-цифра).
    \ ------------------------------------------------------------------
    : init-hex-digit-tab
        hex-digit-tab 256 erase
        1  [char] 0  hex-digit-tab +  c!
        2  [char] 1  hex-digit-tab +  c!
        3  [char] 2  hex-digit-tab +  c!
        4  [char] 3  hex-digit-tab +  c!
        5  [char] 4  hex-digit-tab +  c!
        6  [char] 5  hex-digit-tab +  c!
        7  [char] 6  hex-digit-tab +  c!
        8  [char] 7  hex-digit-tab +  c!
        9  [char] 8  hex-digit-tab +  c!
        10 [char] 9  hex-digit-tab +  c!
        11 [char] A  hex-digit-tab +  c!
        12 [char] B  hex-digit-tab +  c!
        13 [char] C  hex-digit-tab +  c!
        14 [char] D  hex-digit-tab +  c!
        15 [char] E  hex-digit-tab +  c!
        16 [char] F  hex-digit-tab +  c!
        11 [char] a  hex-digit-tab +  c!
        12 [char] b  hex-digit-tab +  c!
        13 [char] c  hex-digit-tab +  c!
        14 [char] d  hex-digit-tab +  c!
        15 [char] e  hex-digit-tab +  c!
        16 [char] f  hex-digit-tab +  c!
    ;
    init-hex-digit-tab

    \ hex-цифра: ( c -- digit true | 0 false )
    : hex-digit ( c -- digit true | 0 false )
        hex-digit-tab + c@
        dup 0= if  drop 0 false exit then
        1 - true ;

    \ ------------------------------------------------------------------
    \ Парсинг hex-строк
    \ ------------------------------------------------------------------

    \ Hex-пара в байт: "FF" -> 255, "GG" -> -1 (не hex).
    \ ( addr len -- byte | -1 )
    : parse-hex-byte ( addr len -- byte | -1 )
        0 hex-acc !
        0 hex-pos !
        swap hex-src !          \ addr
        hex-src-len !           \ len
        begin
            hex-pos @ hex-src-len @ u< while
            hex-src @ hex-pos @ + c@
            hex-digit
            if   hex-acc @ 16 * swap + hex-acc !
            else drop -1 exit
            then
            1 hex-pos +!
        repeat
        hex-acc @ ;

    \ Строка является Intel HEX record? (первый символ ':')
    \ ( addr len -- flag )
    \ 58 = код ':' (ASCII); литерал ':' в теле : не используется —
    \ сломал бы токенизатор flint (см. doc/UTILS_RU.md)
    : colon-literal ( -- c ) 58 ;
    : hex-line-is-intel? ( addr len -- flag )
        drop 0 + c@ colon-literal = ;

    \ Парсинг одной строки: hex-пара в hex-buffer.
    \ Intel HEX строки и не-hex — пропускаются.
    \ ( addr len -- )
    : hex-parse-line ( addr len -- )
        over 0 + c@ colon-literal =
        if   drop drop
        else  parse-hex-byte
              dup 0< if  drop
              else  hex-buffer hex-len @ + c!
                    1 hex-len +!
              then
        then ;

    \ Парсинг буфера построчно (разделитель 10 = LF). Пустые строки
    \ и Intel HEX записи пропускаются.
    \ ( buf-addr buf-len -- )
    : hex-parse-buffer ( buf-addr buf-len -- )
        0 hex-len !
        0 line-start !
        0 find-i !
        swap buf-base !
        buf-len !
        begin
            find-i @ buf-len @ u< while
            buf-base @ find-i @ + c@ 10 = if
                find-i @ line-start @ -          \ n
                dup 0= if  drop
                else
                    dup hex-src-len !            \ n
                    line-start @ buf-base @ +    \ n src
                    swap                         \ src n
                    hex-parse-line               \ --
                then
                find-i @ 1 + line-start !
            then
            1 find-i +!
        repeat ;

    \ ------------------------------------------------------------------
    \ Поиск и патчинг
    \ ------------------------------------------------------------------

    \ Совпадает ли паттерн (pat-addr, pat-len) с hex-buffer в pos?
    \ ( pos -- flag )
    : pat-match? ( pos -- flag )
        pm-pos !                           \ --
        1 pm-match !
        0 find-i !
        begin
            pm-match @ 1 and find-i @ pat-len @ u< and while
                pat-addr @ find-i @ + c@         \ p
                hex-buffer pm-pos @ find-i @ + + c@  \ p h
                = if  ( equal: keep 1 )
                else  0 pm-match !  then  \ mismatch -> 0
                1 find-i +!
        repeat
        pm-match @ ;

    \ Поиск байтового паттерна в hex-buffer.
    \ ( pat-addr pat-len -- addr | -1 )   (-1 = не найдено)
    : hex-find-pattern ( pat-addr pat-len -- addr | -1 )
        swap pat-addr !                 \ addr  (pat-len on top)
        pat-len !
        0 found !
        pat-len @ hex-len @ u> if -1 exit then
        0 find-start !
        begin
            found @ 0= find-start @ hex-len @ pat-len @ - u< and while
                find-start @ pat-match? if
                    find-start @ find-addr !
                    1 found !
                then
                1 find-start +!
        repeat
        found @ if find-addr @ else -1 then ;

    \ Запись байта в hex-buffer ( byte addr -- )
    : hex-patch-at ( byte addr -- )
        hex-buffer + c! ;

    \ Запись 16-битного слова little-endian: ( word addr -- )
    \ addr -> pw-addr; word остаётся на стеке для обоих байтов.
    : hex-patch-word-at ( word addr -- )
        pw-addr !                          \ word   (addr -> pw-addr)
        hex-buffer pw-addr @ +             \ word base
        over 0xFF and                      \ word base lo
        swap c!                            \ word    [lo @ base]
        8 rshift                           \ hi
        hex-buffer pw-addr @ 1 + + c! ;    \ [hi @ base+1]

    \ ------------------------------------------------------------------
    \ Z80: поиск и патчинг zbranch (if/else)
    \ ------------------------------------------------------------------

    \ Поиск CALL zbranch: CD <addr-lo> <addr-hi>.
    \ ( zbranch-addr -- call-addr | -1 )
    : hex-find-call-zbranch ( zbranch-addr -- call-addr | -1 )
        find-z !
        0 found !
        hex-len @ 3 u< if -1 exit then
        0 find-start !
        begin
            found @ 0= find-start @ hex-len @ 2 - u< and while
                hex-buffer find-start @ + c@ 0xCD = if
                    hex-buffer find-start @ 1 + + c@ find-z @ 0xFF and = if
                        hex-buffer find-start @ 2 + + c@ find-z @ 8 rshift = if
                            find-start @ find-addr !
                            1 found !
                        then
                    then
                then
                1 find-start +!
        repeat
        found @ if find-addr @ else -1 then ;

    \ Поиск JP (0xC3) начиная с адреса.
    \ ( start-addr -- jp-addr target-addr | -1 -1 )
    : hex-find-jp-after ( start-addr -- jp-addr target-addr | -1 -1 )
        find-start !
        hex-len @ 3 u< if -1 -1 exit then
        0 found !
        0 find-addr !
        begin
            found @ 0= find-start @ hex-len @ u< and while
                hex-buffer find-start @ + c@ 0xC3 = if
                    find-start @ find-addr !
                    1 found !
                then
                1 find-start +!
        repeat
        found @ if
            find-addr @
            find-addr @ 1 + hex-buffer + c@
            find-addr @ 2 + hex-buffer + c@ 256 * +
        else
            -1 -1
        then ;

    \ Поиск JR NZ (0x20, off>=0x80 = backward jump) начиная с адреса.
    \ ( start-addr -- jr-addr | -1 )
    : hex-find-jr-nz-after ( start-addr -- jr-addr | -1 )
        find-start !
        hex-len @ 2 u< if -1 exit then
        0 found !
        begin
            found @ 0= find-start @ hex-len @ u< and while
                hex-buffer find-start @ + c@ 0x20 = if
                    hex-buffer find-start @ 1 + + c@ 128 u>= if
                        find-start @ find-addr !
                        1 found !
                    then
                then
                1 find-start +!
        repeat
        found @ if find-addr @ else -1 then ;

    \ Начало else-тела после CALL zbranch: цель первого JP после (call+3).
    \ ( zbranch-call-addr -- else-addr | -1 )
    : hex-find-else-body ( zbranch-call-addr -- else-addr | -1 )
        3 + hex-find-jp-after over drop ;

    \ Автопатчинг: переадресовать else-ветку на new-addr.
    \ ( zbranch-addr new-addr -- ok? )
    : hex-patch-zbranch ( zbranch-addr new-addr -- ok? )
        patch-new !                      \ zaddr  (new-addr -> patch-new)
        hex-find-call-zbranch            \ call
        dup 0< if  drop false exit then  \ call
        3 + hex-find-jp-after            \ jp target
        dup 0< if  drop drop drop false exit then  \ (3 items, 3 drops)
        drop                             \ jp
        1 + patch-new @ swap hex-patch-word-at   \ [new @ jp+1]
        true ;

    \ ------------------------------------------------------------------
    \ Отладка
    \ ------------------------------------------------------------------

    \ Один hex-символ (n 0..15 -> ASCII).
    : hex-byte-ch ( n -- ch )
        16 mod
        dup 9 > IF  7 + THEN
        48 + ;
    \ Два hex-символа (n 0..255).
    : hex2 ( n -- )
        dup 4 rshift hex-byte-ch emit   \ n hi-nibble
        16 mod hex-byte-ch emit ;          \ lo-nibble
    \ Дамп hex-buffer [addr .. addr+len) hex-байтами по пробелу.
    \ ( addr len -- )
    : hex-dump ( addr len -- )
        0 hex-pos !
        swap hex-src !
        hex-src-len !
        begin
            hex-pos @ hex-src-len @ u< while
                hex-src @ hex-pos @ + c@ hex2
                space
                1 hex-pos +!
        repeat
        decimal cr ;

    true constant hex-patch-loaded
[THEN]