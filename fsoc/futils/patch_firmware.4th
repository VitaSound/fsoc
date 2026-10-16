\ fsoc/futils/patch_firmware.4th
\ Gforth-порт patch_firmware.py (z80 zbranch-патчинг).
\
\ Алгоритм (1:1 с Python):
\   1. Прочитать .hex (по одному hex-байту на строку) в hex-buffer.
\   2. Найти первое CD <lo> <hi>, где addr = hi*256+lo == 0x00D3 или 0x20D3.
\      (Python: if bytes[i]==0xCD and bytes[i+2]==0x00: ... addr check)
\   3. После call+3: найти JR NZ (0x20, off>=128), затем JP (0xC3).
\      else-body = target JP.
\   4. bytes[call+3..4] = else-body (little-endian).
\   5. Записать обратно: 1 байт/строка, %02X.
\
\ fenum: ulist используется в pf-find-candidates — сбор всех адресов
\ CALL zbranch (0x00D3/0x20D3) в список, и выбор первого — так же,
\ как Python накапливает zbranch_calls и возвращает первый hit.
\
\ Zdeps: hex_patch.4th (in-memory buffer + hex-byte-ch).
\        fenum.4th (ulist для кандидатов).
\
\ Использование:
\   " /path/firmware.hex" pf-patch   (возвращает ok?)
\
\ Файл перезаписывается in-place (как Python), если ok?=true.

[IFUNDEF] patch-firmware-loaded
    require ./hex_patch.4th
    require ../../forth-packages/fenum/0.1.1/fenum.4th

    \ ------------------------------------------------------------------
    \ Буферы и переменные
    \ ------------------------------------------------------------------
    create  pf-in-file   65536 allot
    variable pf-in-len
    create  pf-out-file  65536 allot
    variable pf-out-len
    variable pf-fid
    variable pf-i
    variable pf-j
    variable pf-path-a
    variable pf-path-u
    variable pf-lf
    10 pf-lf !   \ LF char (for newline writes)

    \ Запомнить путь для перезаписи in-place. (patha pathu -- )
    : pf-store-path ( patha pathu -- )
        pf-path-u !   \ pathu (top)
        pf-path-a ! ; \ patha

    \ ------------------------------------------------------------------
    \ File I/O: прочитать файл целиком (string-stream, 1 байт/строка)
    \ (patha pathu -- in-len)
    \ ------------------------------------------------------------------
    : pf-read-file ( patha pathu -- in-len )
        r/o open-file throw pf-fid !
        pf-in-file 65536 pf-fid @ read-file
        drop pf-in-len !
        pf-fid @ close-file throw
        pf-in-len @ ;

    \ ------------------------------------------------------------------
    \ Parse в hex-buffer через hex_patch: hex-parse-buffer ожидает
    \ строки вида "FF" (2 hex-символа, разделитель LF).
    \ ------------------------------------------------------------------
    : pf-parse-file ( -- )
        pf-path-a @ pf-path-u @ pf-read-file drop
        pf-in-file pf-in-len @ hex-parse-buffer ;

    \ ------------------------------------------------------------------
    \ Записать hex-buffer в файл (1 байт/строку, %02X).
    \ (patha pathu -- )
    \ ------------------------------------------------------------------
    : pf-dump-buffer ( -- )
        pf-path-a @ pf-path-u @
        w/o create-file throw pf-fid !
        0 pf-out-len !
        begin
            pf-out-len @ hex-len @ u< while
                pf-out-len @ hex-buffer + c@
                dup 4 rshift hex-byte-ch pf-out-file c!
                16 mod     hex-byte-ch pf-out-file 1 + c!
                pf-out-file 2 pf-fid @ write-file throw
                pf-lf 1      pf-fid @ write-file throw
                1 pf-out-len +!
        repeat
        pf-fid @ close-file throw ;

    \ ------------------------------------------------------------------
    \ Шаг 1: сбор кандидатов CALL zbranch через fenum ulist.
    \ Python: for i in range(len-2):
    \     if bytes[i]==0xCD and bytes[i+2]==0x00:
    \         addr = bytes[i+2]*256 + bytes[i+1]
    \         if addr == 0x00D3 or addr == 0x20D3: ...
    \ (Python-баг: hi==0x00 фильтр слабый, но addr-чек точный)
    \
    \ Мы: ulist содержит адреса i, где:
    \     bytes[i]==0xCD AND
    \     (hi==0x00 AND lo==0xD3)  => addr==0x00D3
    \  OR (hi==0x20 AND lo==0xD3)  => addr==0x20D3
    \ Возврат: (first-addr | -1)  (первый элемент ulist)
    \ ------------------------------------------------------------------
    : pf-find-candidates ( -- first | -1 )
        ulist-new >r
        0 pf-i !
        begin
            pf-i @ hex-len @ 2 - u< while
                hex-buffer pf-i @ + c@ 0xCD = if
                    hex-buffer pf-i @ 1 + + c@ 0xD3 = if
                        hex-buffer pf-i @ 2 + + c@ 0x00 = if
                            pf-i @ r@ ulist-add
                        then
                    then
                then
                1 pf-i +!
        repeat
        r@ ulist-reverse           \ порядок по возрастанию i (Python: первый hit)
        r@ ulist-empty?            \ -- flag
        if
            r@ ulist-dispose rdrop
            -1
        else
            0 r@ ulist-nth-addr    \ -- addr
            r@ ulist-dispose rdrop
        then ;

    \ ------------------------------------------------------------------
    \ Шаг 2: find_else_body_start (Python lines 37-48)
    \ (call -- else-addr | -1)
    \ ------------------------------------------------------------------
    : pf-find-else ( call -- else-addr | -1 )
        3 + pf-i !
        begin
            pf-i @ hex-len @ 1 - u< while
                hex-buffer pf-i @ + c@ 0x20 = if
                    hex-buffer pf-i @ 1 + + c@ 128 u>= if
                        \ JP после (i+2)
                        pf-i @ 2 + pf-j !
                        begin
                            pf-j @ hex-len @ 2 - u< while
                                hex-buffer pf-j @ + c@ 0xC3 = if
                                    hex-buffer pf-j @ 1 + + c@
                                    hex-buffer pf-j @ 2 + + c@ 256 * +
                                    exit
                                then
                                1 pf-j +!
                        repeat
                    then
                then
                1 pf-i +!
        repeat
        -1 ;

    \ ------------------------------------------------------------------
    \ Шаг 3: bytes[call+3..4] = else-addr (little-endian)
    \ (call else-addr -- )
    \ ------------------------------------------------------------------
    : pf-patch-call-target ( call else-addr -- )
        swap 3 +                    \ (else call+3)
        hex-patch-word-at ;        \ little-endian, уже проверено в hex_patch

    \ ------------------------------------------------------------------
    \ Основной драйвер: (patha pathu -- ok?)
    \ ------------------------------------------------------------------
    : pf-patch ( patha pathu -- ok? )
        pf-store-path
        pf-parse-file
        pf-find-candidates
        dup 0< if  drop false exit then
        \ call-addr
        dup                        \ сохранить call для патча (find-else его потребляет)
        pf-find-else
        dup 0< if  drop drop false exit then
        \ call else
        pf-patch-call-target
        pf-dump-buffer
        true ;

    true constant patch-firmware-loaded
[THEN]
