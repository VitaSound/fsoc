\ ------------------------------------------------------------------
\ Тесты fsoc/futils/patch_firmware.4th
\ ------------------------------------------------------------------
\ Покрытие:
\   - pf-find-candidates   (сбор CALL zbranch через fenum ulist)
\   - pf-find-else         (JR NZ -> JP, target = else-body)
\   - pf-patch-call-target (little-endian запись в hex-buffer)
\   - pf-patch             (полный цикл: файл -> патч -> файл)
\   - no-op случаи (нет кандидата)
\
\ Своя assert-обвязка (как в hex_patch_test.4th), без ttester.
\ ------------------------------------------------------------------

s" ../../fsoc/futils/patch_firmware.4th" included
s" helper.4th" included

\ ------------------------------------------------------------------
\ Ситуация A (для unit-тестов find/patch):
\   0: CD   1: D3   2: 00      -> CALL 0x00D3 @0
\   3: 16   4: 09              -> dummy target (low,high)
\   5: 20   6: FF              -> JR NZ (off 0xFF <0)
\   7: C3   8: 7B   9: 06      -> JP 0x067B
\ 10: 00                       -> tail
\ else-addr = 0x067B = 1659.
\ После патча: byte[3]=0x7B, byte[4]=0x06.
\ ------------------------------------------------------------------
: sit-a-load ( -- )
    hex-buffer 65536 erase
    0 hex-len !
    0xCD 0  hex-patch-at
    0xD3 1  hex-patch-at
    0x00 2  hex-patch-at
    0x16 3  hex-patch-at
    0x09 4  hex-patch-at
    0x20 5  hex-patch-at
    0xFF 6  hex-patch-at
    0xC3 7  hex-patch-at
    0x7B 8  hex-patch-at
    0x06 9  hex-patch-at
    10 hex-len ! ;

\ ------------------------------------------------------------------
\ t-cand: pf-find-candidates -> 0 (первый и единственный CALL zbranch)
\ ------------------------------------------------------------------
: t-cand
    sit-a-load
    pf-find-candidates  0 Aeq ;

\ t-cand-miss: без CD D3 00 -> -1
: t-cand-miss
    hex-buffer 65536 erase
    0 hex-len !
    0xAA 0  hex-patch-at
    0xBB 1  hex-patch-at
    0xCC 2  hex-patch-at
    3 hex-len !
    pf-find-candidates  -1 Aeq ;

\ ------------------------------------------------------------------
\ t-else: pf-find-else (call=0 -- 0x067B)
\ ------------------------------------------------------------------
: t-else
    sit-a-load
    0 pf-find-else  0x067B Aeq ;

\ t-else-miss: нет JR NZ/JP после call -> -1
\   0: CD D3 00 16 09 (call + dummy), 5: 00 6: 00 (no 0x20)
: t-else-miss
    hex-buffer 65536 erase
    0 hex-len !
    0xCD 0  hex-patch-at
    0xD3 1  hex-patch-at
    0x00 2  hex-patch-at
    0x16 3  hex-patch-at
    0x09 4  hex-patch-at
    0x00 5  hex-patch-at
    0x00 6  hex-patch-at
    7 hex-len !
    0 pf-find-else  -1 Aeq ;

\ ------------------------------------------------------------------
\ t-patch-ct: pf-patch-call-target (call=0 else=0x067B --)
\   byte[3] -> 0x7B, byte[4] -> 0x06
\ ------------------------------------------------------------------
: t-patch-ct
    sit-a-load
    0 0x067B pf-patch-call-target
    hex-buffer 3 + c@  0x7B Aeq
    hex-buffer 4 + c@  0x06 Aeq ;

\ ------------------------------------------------------------------
\ Полный цикл pf-patch: пишем временный .hex, патчим, читаем назад.
\ ------------------------------------------------------------------
variable tmp-a
variable tmp-u

: t-path-init ( -- )
    s" tests/futils/.pf_tmp.hex"
    tmp-u !     \ len
    tmp-a ! ;   \ addr

: t-path-del ( -- )
    tmp-a @ tmp-u @
    delete-file   \ не бросает исключение при отсутствии файла
    drop ;

\ Записать hex-buffer в файл через pf-dump-buffer
: pf-dump ( -- )
    tmp-a @ tmp-u @ pf-store-path
    pf-dump-buffer ;

\ t-roundtrip: полный pf-patch
: t-roundtrip
    t-path-init
    sit-a-load
    pf-dump
    tmp-a @ tmp-u @ pf-patch  AtTrue
    tmp-a @ tmp-u @ pf-store-path
    pf-parse-file
    hex-buffer 3 + c@  0x7B Aeq
    hex-buffer 4 + c@  0x06 Aeq
    hex-buffer 5 + c@  0x20 Aeq   \ JR NZ нетронут
    hex-buffer 7 + c@  0xC3 Aeq   \ JP нетронут
    t-path-del ;

\ t-roundtrip-nocand: файл без CALL zbranch -> false, файл не меняется
: t-roundtrip-nocand
    t-path-init
    hex-buffer 65536 erase
    0 hex-len !
    0x11 0  hex-patch-at
    0x22 1  hex-patch-at
    0x33 2  hex-patch-at
    3 hex-len !
    pf-dump
    tmp-a @ tmp-u @ pf-patch  Afs
    tmp-a @ tmp-u @ pf-store-path
    pf-parse-file
    hex-buffer 0 + c@  0x11 Aeq   \ нетронут
    hex-buffer 1 + c@  0x22 Aeq
    t-path-del ;

\ ------------------------------------------------------------------
\ Запуск
\ ------------------------------------------------------------------
: pf-run-all
    t-cand
    t-cand-miss
    t-else
    t-else-miss
    t-patch-ct
    t-roundtrip
    t-roundtrip-nocand
    futils-test-finish
    ;
pf-run-all
