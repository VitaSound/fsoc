\ fsoc/futils/run_all_tools.4th — порт tools/run_all_tools.py
\ Оркестратор: discovery CPU из fsys/kernel + четыре инструмента
\ (stack_analyze / cross_lint / con_words_gen / isa_to_fasm) in-process —
\ python гоняет подпроцессы с capture_output; здесь вывод каждого инструмента
\ уходит во временный cap-файл, в консоль идёт только отчёт оркестратора
\ (байт-в-байт паритет) и exit code: 0 = ни одна тулза не error (warnings
\ не считаются), 1 = error любого статуса / isa_check / битой спеки.
\
\ Использование:
\   run-all-tools ( -- rc )     \ паритет `python3 tools/run_all_tools.py`
\   run-all-cli   ( -- rc )     \ то же + argv: --dry-run, --only <list>,
\                               \   --stack-report <path>
\ --json <path> — пишет отчёт (cpus + isa_specs); con_run/con_skip из cap.
\ --stack-report: side-effect файл python; Forth принимает и игнорирует.
\
\ Стиль (уроки gen_golden/isa_to_fasm): без { }-локалов, переменные-параметры,
\ cap-файл через outfile-execute (аналог capture_output), discovery сортируется
\ через fenum enum-sort, префикс rat-.

\ ------------------------------------------------------------------
\ Зависимости
\ ------------------------------------------------------------------
require stack_analyze.4th
require cross_lint.4th
require con_words_gen.4th
require isa_to_fasm.4th
require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

\ ------------------------------------------------------------------
\ Данные и состояние вызова
\ ------------------------------------------------------------------
create rat-cap 24 allot             \ cap-файл = capture_output python
s" /tmp/fsoc_rat_cap.txt" rat-cap swap cmove
21 constant rat-cap-l
create rat-path 512 allot variable rat-path-l  \ сборный путь
create rat-namebuf 16 64 * allot variable rat-namep \ слоты копий имён cpu
create rat-dbuf 512 allot           \ буфер read-dir
variable rat-dst                    \ адрес копии имени в rat-namebuf

variable rat-rc                     \ rc последнего запуска инструмента
variable rat-dry                    \ --dry-run
variable rat-only                   \ маска: 1=stack 2=cross 4=con 8=isa (15=все)
variable rat-pa variable rat-pu     \ путь1
variable rat-pb-a variable rat-pb-u \ путь2
variable rat-cpu-a variable rat-cpu-u \ имя cpu (указатель в rat-namebuf)
variable rat-spec-a variable rat-spec-u
variable rat-n                      \ число discovered cpus
variable rat-any-error              \ флаг exit code (python any_error)
variable rat-ispec                   \ счётчик checked ISA spec
variable rat-iskip                   \ счётчик invalid ISA spec
create rat-cnt 12 cells allot       \ Tool summary: 12 ячеек t*3+{0 ok,1 skip,2 err}
                                    \ (было variable — 1 ячейка: outcome/summary
                                    \  затирали rat-a/rat-u/rat-cpbuf → SEGV)
variable rat-a variable rat-u        \ scratch строковых пар
\ имя каталога-кандидата: копируется в rat-cpbuf ДО rat-has-kernel?,
\ т.к. тот читает подкаталог в тот же rat-dbuf и затирает источник
create rat-cpbuf 64 allot variable rat-cpl
: rat-cp-save ( a u -- )
    dup 64 u>= abort" run_all_tools: cpu name too long"
    dup rat-cpl !
    rat-cpbuf swap move ;
: rat-cp@ ( -- a u ) rat-cpbuf rat-cpl @ ;
variable rat-i variable rat-q2       \ scratch индексов
variable rat-padn                    \ scratch rat-pad
variable rat-found                   \ флаг наличия kernel*.4th
variable rat-did                      \ открытый каталог fsys/kernel
variable rat-subid                    \ открытый проверяемый каталог <cpu>
variable rat-rec                      \ выделенный rat-rec%
variable rat-len                      \ длина строки-скраб
variable rat-cont                     \ флаг продолжения цикла
variable rat-cont2                    \ внутренний цикл rat-has-kernel? (не трогает rat-cont)
variable rat-cpus                      \ ulist указателей на rat-rec% (discovery)

\ заполнения пар-аргументов
: rat-set1 ( a u -- ) rat-pu ! rat-pa ! ;
: rat-set2 ( a u -- ) rat-pb-u ! rat-pb-a ! ;
: rat-setcpu ( a u -- ) rat-cpu-u ! rat-cpu-a ! ;

\ ------------------------------------------------------------------
\ Строковые/файловые утилиты (паритет python-хелперов)
\ ------------------------------------------------------------------
: rat-exists? ( a u -- f )
    r/o open-file if drop 0 else close-file drop -1 then ;

\ отбить первую « (» — python split(' (')[0] для console-статусов
variable rat-sa variable rat-su
: rat-split-paren ( a u -- a u2 )
    rat-su ! rat-sa !
    0 rat-i !
    -1 rat-q2 !
    begin rat-i @ rat-su @ < rat-q2 @ -1 = and while
        rat-sa @ rat-i @ + c@ [char] ( = if
            rat-i @ rat-sa @ - dup 0> if 1- then
            rat-su !
            0 rat-q2 !
        then
        1 rat-i +!
    repeat
    rat-sa @ rat-su @ ;

\ печать числа без пробела (python str(int))
: rat-n. ( n -- ) s>d <# #s #> type ;

\ левое выравнивание (python {cpu:6})
: rat-pad ( a u n -- )
    rat-padn !
    dup rat-padn @ swap - 0 max          \ ( a u d ) — d = n-u (python {cpu:6})
    >r type r>
    begin dup 0> while space 1- repeat drop ;

\ путь = ( a u ) + суффикс ( b u ) -> rat-path/rat-path-l
: rat-path-reset ( -- ) 0 rat-path-l ! ;
: rat-path-add ( a u -- )
    dup rat-path-l @ + 512 u>= abort" run_all_tools: path too long"
    dup >r                        \ запомнить u
    rat-path rat-path-l @ +       \ ( a u dst )
    swap move                     \ ( a dst u ) -> move
    r> rat-path-l +! ;
: rat-path@ ( -- a u ) rat-path rat-path-l @ ;

\ имя каталога/файла -> копия в слот rat-namebuf, возвращает ( a' u )
: rat-nameslot ( a u -- a' u )
    dup 64 u>= abort" run_all_tools: cpu name too long"
    rat-u ! rat-a !
    rat-namebuf rat-namep @ + rat-dst !
    rat-a @ rat-dst @ rat-u @ move     \ src=rat-a, dst=rat-dst
    rat-u @ rat-namep @ + rat-namep !
    rat-dst @ rat-u @ ;

\ ------------------------------------------------------------------
\ ISA_SPEC: имя спеки по cpu (таблица python ISA_SPEC)
\ ------------------------------------------------------------------
: rat-lookup-spec ( a u -- spec-a spec-u | 0 0 )
    2dup s" j1a"   compare 0= if 2drop s" j1_isa.json"    exit then
    2dup s" j1b"   compare 0= if 2drop s" j1_isa.json"    exit then
    2dup s" bcpu"  compare 0= if 2drop s" bcpu_isa.json"  exit then
    2dup s" z80"   compare 0= if 2drop s" z80_isa.json"   exit then
    2dup s" avr"   compare 0= if 2drop s" avr_isa.json"   exit then
    2dup s" cd16"  compare 0= if 2drop s" cd16_isa.json"  exit then
    2dup s" msl16" compare 0= if 2drop s" msl16_isa.json" exit then
    2dup s" 8051"  compare 0= if 2drop s" mcs51_isa.json" exit then
    2dup s" stm8"  compare 0= if 2drop s" stm8_isa.json"  exit then
    2drop 0 0 ;

\ ------------------------------------------------------------------
\ Обход каталогов: чтение имени и наличие kernel*.4th (python glob)
\ ------------------------------------------------------------------
\ имя из открытого каталога rat-did -> ( a u f ), f=0 конец/ошибка
: rat-read-main ( -- a u f ) \ f=0 — конец каталога
    rat-dbuf 512 rat-did @ read-dir throw   \ данные: ( u2 -1 ) | конец: ( 0 0 )
    over 0= if                               \ u2=0 — конец
        2drop 0 exit
    then
    drop rat-dbuf swap 1 ;                   \ ( buf u2 1 )

\ то же из проверяемого каталога rat-subid
: rat-read-sub ( -- a u f )
    rat-dbuf 512 rat-subid @ read-dir throw
    over 0= if
        2drop 0 exit
    then
    drop rat-dbuf swap 1 ;

\ python glob "kernel*.4th": начинается с kernel, кончается .4th (мин 10)
: rat-kernel-name? ( a u -- f )
    dup 10 < if 2drop 0 exit then
    rat-u ! rat-a !
    rat-a @ 6 s" kernel" compare if 0 exit then
    rat-a @ rat-u @ + 4 - 4 s" .4th" compare 0= ;

\ каталог ( a u ) содержит kernel*.4th? (python: d.glob("kernel*.4th"))
: rat-has-kernel? ( a u -- f )
    open-dir if drop 0 exit then   \ не каталог / нет доступа
    rat-subid !
    0 rat-found !
    -1 rat-cont2 !
    begin rat-cont2 @ while
        rat-read-sub if            \ ( a u ) прочитали имя
            rat-kernel-name? if
                -1 rat-found !
                0 rat-cont2 !
            then
        else
            0 rat-cont2 !
        then
    repeat
    rat-subid @ close-dir drop
    rat-found @ ;

\ ------------------------------------------------------------------
\ Запись cpu и discovery (паритет discover_cpus: sorted(KERNEL.glob("*")))
\ ------------------------------------------------------------------
\ struct/field/constant на верхнем уровне оставляет мусор на стеке —
\ по образцу fjson/node.4th и gen_golden: mark глубины, drop лишнего
variable rat-depth
: rat-mark ( -- ) depth rat-depth ! ;
: rat-unmark ( -- ) depth rat-depth @ - 0 ?do drop loop ;

rat-mark
struct
    cell% field r-na                \ имя в rat-namebuf
    cell% field r-nu
    cell% field r-cross             \ 0/1 fsys/host/<cpu>-cross.4th есть
    cell% field r-dict              \ 0/1 doc/j1-word-graph/fsys-<cpu>*.json есть
    cell% field r-spec-a            \ имя спеки (0 0 = нет)
    cell% field r-spec-u
constant rat-rec%
rat-unmark

\ cross: fsys/host/<cpu>-cross.4th (python: HOST.glob("*-cross.4th"))
: rat-attach-cross ( -- )           \ rat-rec выставлен вызывающим
    rat-path-reset
    s" fsys/host/" rat-path-add
    rat-rec @ r-na @ rat-rec @ r-nu @ rat-path-add
    s" -cross.4th" rat-path-add
    rat-path@ rat-exists?
    rat-rec @ r-cross ! ;

\ dict: doc/j1-word-graph/fsys-<cpu>.json ИЛИ fsys-<cpu>-extra-min.json
\ (python: GRAPH.glob("fsys-*.json") + regex fsys-(.+?)(-extra-min)?)
: rat-attach-dict ( -- )
    rat-path-reset
    s" doc/j1-word-graph/fsys-" rat-path-add
    rat-rec @ r-na @ rat-rec @ r-nu @ rat-path-add
    s" .json" rat-path-add
    rat-path@ rat-exists? if
        -1
    else
        rat-path-reset
        s" doc/j1-word-graph/fsys-" rat-path-add
        rat-rec @ r-na @ rat-rec @ r-nu @ rat-path-add
        s" -extra-min.json" rat-path-add
        rat-path@ rat-exists?
    then
    rat-rec @ r-dict ! ;

\ spec: таблица python ISA_SPEC + существование файла (python: ISA_SPEC.get + exists)
: rat-attach-spec ( -- )
    rat-rec @ r-na @ rat-rec @ r-nu @ rat-lookup-spec
    dup 0= if
        2drop
        0 0 rat-rec @ r-spec-u ! rat-rec @ r-spec-a !
    else
        rat-rec @ r-spec-u ! rat-rec @ r-spec-a !
        rat-path-reset
        s" tools/isa_specs/" rat-path-add
        rat-rec @ r-spec-a @ rat-rec @ r-spec-u @ rat-path-add
        rat-path@ rat-exists? 0= if
            0 0 rat-rec @ r-spec-u ! rat-rec @ r-spec-a !
        then
    then ;

\ добавить cpu ( a u = имя каталога ) как запись discovery
: rat-add-cpu ( a u -- )
    rat-rec% allocate throw rat-rec !
    rat-nameslot                    \ ( a' u )
    rat-rec @ r-nu !                \ rat-nu := u
    rat-rec @ r-na !                \ rat-na := a'
    rat-attach-cross
    rat-attach-dict
    rat-attach-spec
    rat-rec @ rat-cpus @ ulist-add ;

\ аргументы rat-cmp-cpu (как gc-ia/gc-ib в gen_golden)
variable rat-ia variable rat-ib

\ cmp для enum-sort: «порядок правилен» по имени (как gg-cmp-name)
: rat-cmp-cpu ( ia ib -- flag )
    rat-ib ! rat-ia !
    rat-ia @ r-na @ rat-ia @ r-nu @
    rat-ib @ r-na @ rat-ib @ r-nu @
    compare 0<= ;

\ сортировка по имени (= python sorted(KERNEL.glob("*")))
: rat-sort-cpus ( -- )
    rat-cpus @ >r
    ['] rat-cmp-cpu rat-cpus @ enum-sort rat-cpus !
    r> ulist-dispose ;

\ основной обход fsys/kernel (паритет discover_cpus)
: rat-discover ( -- )
    s" fsys/kernel" open-dir if drop exit then
    rat-did !
    ulist-new rat-cpus !
    -1 rat-cont !
    begin rat-cont @ while
        rat-read-main if            \ ( a u ) имя записи каталога
            over c@ [char] . <> if  \ не скрытая (glob '*' не даёт dot-имён)
                rat-cp-save
                rat-path-reset
                s" fsys/kernel/" rat-path-add
                rat-cp@ rat-path-add
                rat-path@ rat-has-kernel? if
                    rat-cp@ rat-add-cpu
                then
            else
                2drop
            then
        else
            0 rat-cont !
        then
    repeat
    rat-did @ close-dir drop
    rat-sort-cpus
    rat-cpus @ ulist-len rat-n ! ;

\ ------------------------------------------------------------------
\ Cap-механика: вывод инструмента -> /tmp/fsoc_rat_cap.txt
\ (аналог subprocess.run(..., capture_output=True) в python run():
\ вывод инструментов в консоль не попадает, наружу идёт только rc)
\ ------------------------------------------------------------------
variable rat-capfid                    \ fid cap-файла (запись)
variable rat-caprfid                   \ fid cap-файла (чтение)
create rat-capbuf 65536 4 * allot      \ 256KB: cap прочитан для анализа
variable rat-capbufn                   \ прочитано байт
variable rat-wn                        \ строк после strip, начинающихся с ⚠
variable rat-en                        \ строк после strip с ERROR (без регистра)
variable rat-noerr                     \ -1: подстрока "No errors." найдена

\ выполняет xt с перенаправлением type/emit/... в cap-файл (outfile-id)
: rat-cap-in ( xt -- )
    rat-capfid @ outfile-execute ;

\ xt -> cap-файл; rc = 0 либо код throw xt (python: returncode)
: rat-cap-run ( xt -- rc )
    rat-cap 21 w/o create-file throw rat-capfid !
    ['] rat-cap-in catch
    rat-capfid @ close-file drop ;

\ один чанк чтения cap -> rat-capbuf; f=-1: EOF либо буфер полон
: rat-cap-read1 ( -- f )
    65536 4 * rat-capbufn @ -          \ ( room )
    dup 0<= if drop -1 exit then
    rat-capbuf rat-capbufn @ + swap    \ ( dst room )
    rat-caprfid @ read-file throw      \ ( u2 )
    dup rat-capbufn +!
    0= ;

: rat-cap-read ( -- ) \ весь cap-файл в rat-capbuf (сверх лимита отбрасывается)
    0 rat-capbufn !
    rat-cap 21 r/o open-file throw rat-caprfid !
    begin rat-cap-read1 0= while repeat
    rat-caprfid @ close-file drop ;

\ ------------------------------------------------------------------
\ Построчный разбор cap (python: line.strip().startswith(...)).
\ Строки: rat-la/lu — до LF, rat-ha/hu — хвост после LF (0 0 = нет).
\ scratch только наш: rat-split-paren держит свои rat-sa/rat-su.
\ ------------------------------------------------------------------
create rat-lf-ch 1 allot 10 rat-lf-ch c!        \ LF для поиска
create rat-warn3 3 allot                        \ ⚠ UTF-8: E2 9A A0
226 rat-warn3 c! 154 rat-warn3 1+ c! 160 rat-warn3 2 + c!
create rat-err5 5 allot s" ERROR" rat-err5 swap move

variable rat-la variable rat-lu                 \ текущая строка (без LF)
variable rat-ha variable rat-hu                 \ хвост после LF
variable rat-lsa variable rat-lsu               \ scratch входа split

\ выделить первую строку из ( a u): rat-la/lu — строка, rat-ha/hu — хвост
: rat-split-line ( a u -- )
    rat-lsu ! rat-la !
    rat-la @ rat-lsu @ rat-lf-ch 1 search
    if                                   \ ( a3 u3 ): a3 = адрес LF
        over rat-la @ -                  \ ( a3 u3 line-len )
        rat-lu !
        over 1+ rat-ha !                 \ ( a3 u3 )
        1- rat-hu !
        drop
    else                                 \ LF нет: строка = весь вход
        2drop
        rat-lsu @ rat-lu !
        0 rat-ha ! 0 rat-hu !
    then ;

: rat-skip-ws ( a u -- a' u' ) \ пропуск пробелов/таб слева (python strip)
    begin dup 0> while
        over c@ dup 32 = swap 9 = or if
            1 /string
        else
            exit
        then
    repeat ;

: rat-starts-warn? ( a u -- f ) \ строка начинается с ⚠ (E2 9A A0)
    dup 3 < if 2drop 0 exit then
    drop
    dup c@ 226 <> if drop 0 exit then
    dup 1+ c@ 154 <> if drop 0 exit then
    dup 2 + c@ 160 <> if drop 0 exit then
    drop -1 ;

: rat-starts-error? ( a u -- f ) \ строка начинается с ERROR без регистра
    dup 5 < if 2drop 0 exit then
    drop                               \ ( a )
    5 0 do
        dup i + c@
        dup [char] a >= over [char] z <= and if 32 - then
        rat-err5 i + c@ <> if drop 0 unloop exit then
    loop
    drop -1 ;

: rat-analyze-line ( -- ) \ классифицировать rat-la/lu (после strip)
    rat-la @ rat-lu @ rat-skip-ws
    2dup rat-starts-warn? if 1 rat-wn +! then
    rat-starts-error? if 1 rat-en +! then ;

: rat-analyze-lines ( -- )
    rat-lu @ 0> if rat-analyze-line then
    begin rat-hu @ 0> while
        rat-ha @ rat-hu @ rat-split-line
        rat-lu @ 0> if rat-analyze-line then
    repeat ;

\ прочитать cap, подсчитать wn/en/noerr (нужно только для cross-статуса)
: rat-analyze ( -- )
    rat-cap-read
    0 rat-wn ! 0 rat-en ! 0 rat-noerr !
    rat-capbuf rat-capbufn @ rat-split-line
    rat-analyze-lines
    rat-capbuf rat-capbufn @ s" No errors." search if
        2drop -1 rat-noerr !
    then ;

\ ------------------------------------------------------------------
\ Статусы (python out[t]): код rat-stc[t], параметр rat-stp[t]
\ t: 0=stack 1=cross 2=con 3=isa 4=isa_check
\ коды: 0=нет 1=ok 2=skipped 3=error rc=N 4=errors: N 5=rc=N
\ (консоль печатает .split(' (')[0] — ok/skipped потому без хвоста)
\ ------------------------------------------------------------------
create rat-stc 5 allot
create rat-stp 5 cells allot
variable rat-cur                       \ текущий rec в главном цикле
variable rat-xrc                       \ rc последнего запуска инструмента

: rat-st! ( code par t -- )
    >r rat-stp r@ cells + ! r> rat-stc + c! ;
: rat-stc@ ( t -- code ) rat-stc + c@ ;
: rat-stp@ ( t -- par ) cells rat-stp + @ ;
: rat-st-clear ( -- ) 5 0 do 0 0 i rat-st! loop ;

\ печать статуса в консольном формате python (после .split(' (')[0])
: rat-st-type ( t -- )
    dup rat-stc@ 1 = if drop ." ok" exit then
    dup rat-stc@ 2 = if drop ." skipped" exit then
    dup rat-stc@ 3 = if rat-stp@ ." error rc=" rat-n. exit then
    dup rat-stc@ 4 = if rat-stp@ ." errors: " rat-n. exit then
    dup rat-stc@ 5 = if rat-stp@ ." rc=" rat-n. exit then
    drop ;

\ python: out[t].startswith("error") — "error rc=N" и "errors: N"
: rat-st-err? ( t -- f )
    rat-stc@ dup 3 = swap 4 = or ;

\ ------------------------------------------------------------------
\ Пути для этапов (все строятся в rat-path из rat-cur rec)
\ ------------------------------------------------------------------
: rat-path-kernel-dir ( -- )
    rat-path-reset s" fsys/kernel/" rat-path-add
    rat-cur @ r-na @ rat-cur @ r-nu @ rat-path-add ;
: rat-path-cross ( -- )
    rat-path-reset s" fsys/host/" rat-path-add
    rat-cur @ r-na @ rat-cur @ r-nu @ rat-path-add
    s" -cross.4th" rat-path-add ;
: rat-path-spec ( -- )
    rat-path-reset s" tools/isa_specs/" rat-path-add
    rat-cur @ r-spec-a @ rat-cur @ r-spec-u @ rat-path-add ;
: rat-path-scratch ( -- ) \ /tmp/isa_gen_preview/<cpu>
    rat-path-reset s" /tmp/isa_gen_preview/" rat-path-add
    rat-cur @ r-na @ rat-cur @ r-nu @ rat-path-add ;

\ ------------------------------------------------------------------
\ Перебор kernel*.4th каталога fsys/kernel/<cpu>.
\ xt ( a u -- ) получает путь очередного файла; throw уходит в catch
\ кап-обёртки этапа (python: один subprocess на cpu).
\ ------------------------------------------------------------------
variable rat-kxt                       \ текущий xt перебора

: rat-kern-each ( xt -- )
    rat-kxt !
    rat-path-kernel-dir
    rat-path@ open-dir if drop exit then
    rat-subid !
    -1 rat-cont2 !
    begin rat-cont2 @ while
        rat-read-sub if            \ ( a u ) имя файла
            rat-kernel-name? if    \ name? потребляет ( a u ) сам — else с 2drop ронял стек
                s" /" rat-path-add
                rat-a @ rat-u @ rat-path-add
                rat-path@ rat-kxt @ execute
                rat-path-kernel-dir \ восстановить путь каталога
            then
        else
            0 rat-cont2 !
        then
    repeat
    rat-subid @ close-dir drop ;

\ ------------------------------------------------------------------
\ Этап 1 stack: python stack_analyze.py <KERNEL/cpu> --report <tmp>
\ (forth не пишет --report side-effect; статус только от rc)
\ ------------------------------------------------------------------
: rat-stack-do ( a u -- ) stack-analyze ;
: rat-stack-1 ( -- ) ['] rat-stack-do rat-kern-each ;

: rat-do-stack ( -- )
    ['] rat-stack-1 rat-cap-run
    dup if 3 swap 0 rat-st! else drop 1 0 0 rat-st! then ;

\ ------------------------------------------------------------------
\ Этап 3 con: python con_words_gen.py <cpu> <KERNEL/cpu>
\ ------------------------------------------------------------------
create rat-con-run 64 allot  variable rat-con-run-u
create rat-con-skip 64 allot variable rat-con-skip-u

: rat-con-do ( -- )
    rat-path-kernel-dir
    rat-cur @ r-na @ rat-cur @ r-nu @
    rat-path@ con-words-gen ;

: rat-pfx ( a u pre-a pre-u -- f )
    2swap                           \ ( pre-a pre-u a u )
    2over nip over < if 2drop 2drop 0 exit then
    drop 2over nip                  \ ( pre-a pre-u a pu )
    2swap compare 0= ;

: rat-con-cap-take ( a u -- )
    2dup s"  RUN:" rat-pfx if
        dup 63 min rat-con-run-u !
        rat-con-run swap move exit
    then
    2dup s"  SKIP:" rat-pfx if
        dup 63 min rat-con-skip-u !
        rat-con-skip swap move exit
    then
    2drop ;

: rat-harvest-con ( -- )
    0 rat-con-run-u ! 0 rat-con-skip-u !
    rat-cap-read
    rat-capbuf rat-capbufn @ rat-split-line
    begin rat-lu @ while
        rat-la @ rat-lu @ rat-con-cap-take
        rat-ha @ rat-hu @ dup 0= if 2drop 0 rat-lu ! else rat-split-line then
    repeat ;

: rat-do-con ( -- )
    rat-cur @ r-dict @ 0= if 2 0 2 rat-st! exit then
    ['] rat-con-do rat-cap-run
    dup if 3 swap 2 rat-st!
    else drop 1 0 2 rat-st! rat-harvest-con then ;

\ ------------------------------------------------------------------
\ Этап 2 cross: python cross_lint.py <cross> <KERNEL/cpu>
\ ------------------------------------------------------------------
create rat-pcross 512 allot variable rat-pcross-l  \ клон cross-пути: rat-path перезапишется ядром
: rat-cross-do ( -- )
    rat-path-cross
    rat-path@ dup rat-pcross-l ! rat-pcross swap move \ ( клон )
    rat-path-kernel-dir
    rat-pcross rat-pcross-l @        \ ( cross ) — указатель в клоне, не в rat-path
    rat-path@                        \ ( cross kern )
    cross-lint rat-xrc ! ;

: rat-do-cross ( -- )
    rat-cur @ r-cross @ 0= if 2 0 1 rat-st! exit then
    ['] rat-cross-do rat-cap-run
    dup if \ throw из cross-lint
        3 swap 1 rat-st!
    else
        drop
        rat-analyze
        rat-xrc @ 0= rat-noerr @ 0<> and rat-en @ 0= and if
            1 rat-wn @ 1 rat-st!            \ ok (wn warnings)
        else
            rat-en @ 0> if
                4 rat-en @ 1 rat-st!        \ errors: N
            else
                5 rat-xrc @ 1 rat-st!       \ rc=N
            then
        then
    then ;

\ ------------------------------------------------------------------
\ Этап 4 isa: python isa_to_fasm.py <spec> <scratch>; затем drift-гейт
\ (--check) по fsys/fasm/<cpu>/words.4th
\ ------------------------------------------------------------------
\ командная строка для system() (по образцу gg-cmd в gen_golden)
create rat-cmd 600 allot variable rat-cmd-l
: rat-cmd-reset ( -- ) 0 rat-cmd-l ! ;
: rat-cmd-add ( a u -- )
    dup rat-cmd-l @ + 600 u>= abort" run_all_tools: cmd too long"
    dup >r                        \ запомнить u
    rat-cmd rat-cmd-l @ +         \ ( a u dst )
    swap move                     \ ( a dst u ) -> move
    r> rat-cmd-l +! ;
: rat-cmd@ ( -- a u ) rat-cmd rat-cmd-l @ ;
: rat-isa-gen ( -- )
    \ mkdir -p /tmp/isa_gen_preview/<cpu> (python: output_dir.mkdir)
    rat-cmd-reset s" mkdir -p " rat-cmd-add
    rat-path-scratch rat-path@ rat-cmd-add
    rat-cmd@ system
    $? 0<> abort" run_all_tools: mkdir failed"
    \ загрузка спеки (isa-root-node для gen-слов)
    rat-path-spec
    rat-path@ isa-load-spec
    dup 0= if drop abort" run_all_tools: bad spec" then drop
    \ words.4th в scratch
    rat-path-scratch
    s" /words.4th" rat-path-add
    rat-path@ isa-gen-words4th
    \ chip-варианты: <scratch>/<variant>.4th
    rat-path-scratch rat-path@ isa-gen-chip4th ;

: rat-isa-1 ( -- ) rat-isa-gen ;

\ drift-гейт: python isa_to_fasm.py --check <spec> <words>
\ клон words-пути: rat-path перезапишется spec-путём, обе пары
\ в одном буфере давали бы ic-check обрезанный/мусорный путь
create rat-pwords 512 allot variable rat-pwords-l

: rat-isa-check ( -- )
    rat-path-reset s" fsys/fasm/" rat-path-add
    rat-cur @ r-na @ rat-cur @ r-nu @ rat-path-add
    s" /words.4th" rat-path-add
    rat-path@ rat-exists? if
        \ клон ( words ) -> rat-pwords
        rat-path@ dup rat-pwords-l !
        rat-pwords swap move
        rat-path-spec                \ rat-path = spec-путь
        rat-pwords rat-pwords-l @    \ ( words )
        rat-path@                    \ ( words spec )
        2swap                        \ ( spec words )
        ic-check
        dup 0= if 1 0 4 rat-st! else 3 swap 4 rat-st! then
    then ;

: rat-do-isa ( -- )
    rat-cur @ r-spec-a @ 0= if 2 0 3 rat-st! exit then
    1 0 3 rat-st!                   \ ok (spec present)
    rat-dry @ if exit then
    ['] rat-isa-1 rat-cap-run
    dup if
        3 swap 3 rat-st!            \ error rc=<throw>
    else
        drop
        1 0 3 rat-st!               \ ok (generated preview)
        \ python: subprocess.run(--check, capture_output) — вывод в cap-файл
        ['] rat-isa-check rat-cap-run
        dup if 3 swap 4 rat-st! else drop then
    then ;

\ ------------------------------------------------------------------
\ Console line (python f"  {cpu:6}  " + "  ".join(parts))
\ ------------------------------------------------------------------
variable rat-p1                        \ -1: первая часть напечатана без "  "

: rat-part ( mask t -- ) \ t=часть, mask=бит в rat-only (1/2/4/8)
    swap rat-only @ and 0= if drop exit then
    rat-p1 @ 0= if ."   " then
    0 rat-p1 !
    dup 0= if ." stack=" then
    dup 1 = if ." cross=" then
    dup 2 = if ." con=" then
    dup 3 = if ." isa=" then
    rat-st-type ;

\ any_error (python: startswith("error")) + Tool summary счёт
: rat-outcome ( -- )
    5 0 do i rat-st-err? if -1 rat-any-error ! then loop
    4 0 do
        1 i lshift rat-only @ and 0<> if
            i rat-stc@ dup 1 = if
                drop 0
            else
                2 = if 1 else 2 then
            then
            i 3 * + cells rat-cnt + 1 swap +!
        then
    loop ;

: rat-cpu-line ( -- )
    cr ."   " rat-cur @ r-na @ rat-cur @ r-nu @ 6 rat-pad
    ."   "
    -1 rat-p1 !
    1 0 rat-part  2 1 rat-part  4 2 rat-part  8 3 rat-part ;

\ ------------------------------------------------------------------
\ Валидация всех tools/isa_specs/*.json (python json.loads)
\ порядок печати python: шапка "ISA specs: n checked, m invalid",
\ затем строки "  - <bad>"; bad-имёна копируются в фикс-слоты.
\ ------------------------------------------------------------------
create rat-badnames 128 64 * allot    \ 128 слотов по64
create rat-badlens 128 allot
variable rat-badn
variable rat-ba variable rat-bu variable rat-bl   \ scratch rat-bad-add (имя в rat-dbuf)

: rat-json-name? ( a u -- f ) \ "*.json": суффикс ".json" (5 байт, как Path.suffix в python)
    dup 5 < if 2drop 0 exit then
    2dup + 5 - 5 s" .json" compare    \ ( a u n )
    >r 2drop r> 0= ;

: rat-spec-load ( -- ) \ валидация: загрузить путь из rat-path, иначе throw
    rat-path@ isa-load-spec
    dup 0= if drop abort" run_all_tools: invalid spec" then
    drop ;

: rat-bad-add ( a u -- ) \ имя битой спеки в слот rat-badn
    dup 64 min rat-bl !
    swap rat-ba !
    rat-bu !
    rat-ba @ rat-bl @
    rat-badn @ 64 * rat-badnames +
    -rot move
    rat-bl @ rat-badn @ rat-badlens + c!
    1 rat-badn +! ;

\ обход tools/isa_specs/*.json: подсчёт checked/invalid + копии bad-имён
: rat-specs-check ( -- )
    0 rat-badn !
    s" tools/isa_specs" open-dir if drop exit then
    rat-subid !
    -1 rat-cont2 !
    begin rat-cont2 @ while
        rat-read-sub if            \ ( a u ) имя файла
            2dup rat-json-name? if
                rat-u ! rat-a !
                1 rat-ispec +!
                rat-path-reset s" tools/isa_specs/" rat-path-add
                rat-a @ rat-u @ rat-path-add
                ['] rat-spec-load catch
                if
                    1 rat-iskip +!
                    rat-a @ rat-u @ rat-bad-add
                then
            else
                2drop
            then
        else
            0 rat-cont2 !
        then
    repeat
    rat-subid @ close-dir drop ;

\ печать итогов спек (python: шапка, затем bad-строки)
: rat-specs-print ( -- )
    cr ." ISA specs: " rat-ispec @ rat-n.
    ."  checked, " rat-iskip @ rat-n. ."  invalid" cr
    rat-badn @ 0 ?do
        ."   - " rat-badnames i 64 * + rat-badlens i + c@ type
        ." : invalid spec" cr
    loop ;

\ имя инструмента как python t (stack/cross/con/isa)
: rat-tool-name ( t -- a u )
    dup 0= if drop s" stack" exit then
    dup 1 = if drop s" cross" exit then
    dup 2 = if drop s" con" exit then
    drop s" isa" ;

\ печать Tool summary (python: f"  {t:6} ok={ok}  skip={skip}  error={err}")
: rat-summary-line ( t -- )
    cr ."   " dup rat-tool-name 6 rat-pad
    ."  ok=" dup 3 * cells rat-cnt + @ rat-n.
    ."   skip=" dup 3 * 1+ cells rat-cnt + @ rat-n.
    ."   error=" 3 * 2 + cells rat-cnt + @ rat-n. ;

\ ------------------------------------------------------------------
\ Ядро: цикл по cpu, отчёт, спеки, summary (порядок python main())
\ ------------------------------------------------------------------
\ ---- --json report (incremental via outfile-execute) ----
create rat-json-path 512 allot
variable rat-json-path-u
variable rat-jfid
variable rat-jfirst-cpu

: rat-jwith ( xt -- )
    rat-jfid @ outfile-execute ;

: rat-json-st-emit ( t -- )
    [char] " emit rat-st-type [char] " emit ;

: rat-jq ( -- ) [char] " emit ;
: rat-jkey ( a u -- ) rat-jq type rat-jq ." :" ;

: rat-json-cpu-body ( -- )
    rat-jfirst-cpu @ if [char] , emit then
    -1 rat-jfirst-cpu !
    rat-jq rat-cur @ r-na @ rat-cur @ r-nu @ type rat-jq ." :{"
    rat-only @ 1 and if
        s" stack" rat-jkey 0 rat-json-st-emit
        rat-only @ 14 and if [char] , emit then
    then
    rat-only @ 2 and if
        s" cross" rat-jkey 1 rat-json-st-emit
        rat-only @ 12 and if [char] , emit then
    then
    rat-only @ 4 and if
        s" con" rat-jkey 2 rat-json-st-emit
        rat-con-run-u @ if
            [char] , emit s" con_run" rat-jkey
            rat-jq rat-con-run rat-con-run-u @ type rat-jq
        then
        rat-con-skip-u @ if
            [char] , emit s" con_skip" rat-jkey
            rat-jq rat-con-skip rat-con-skip-u @ type rat-jq
        then
        rat-only @ 8 and if [char] , emit then
    then
    rat-only @ 8 and if
        s" isa" rat-jkey 3 rat-json-st-emit
    then
    [char] } emit ;

: rat-json-cpu ( -- )
    rat-jfid @ 0= if exit then
    ['] rat-json-cpu-body rat-jwith ;

: rat-json-hdr ( -- )
    ." {" s" root" rat-jkey rat-jq ." ." rat-jq
    ." ," s" cpus" rat-jkey ." {" ;

: rat-json-open ( a u -- )
    dup 512 min rat-json-path-u !
    rat-json-path swap move
    rat-json-path rat-json-path-u @ w/o create-file throw rat-jfid !
    0 rat-jfirst-cpu !
    ['] rat-json-hdr rat-jwith ;

: rat-json-close-body ( -- )
    ." }," s" isa_specs" rat-jkey ." {"
    s" checked" rat-jkey rat-ispec @ 0 .r
    ." ," s" bad" rat-jkey ." ["
    rat-badn @ 0 ?do
        i 0> if [char] , emit then
        rat-jq rat-badnames i 64 * + rat-badlens i + c@ type rat-jq
    loop
    ." ]}}" ;

: rat-json-close ( -- )
    rat-jfid @ 0= if exit then
    ['] rat-json-close-body rat-jwith
    rat-jfid @ close-file drop
    0 rat-jfid !
    cr ." Report written to " rat-json-path rat-json-path-u @ type cr ;

\ этапы одного cpu + console line + any_error/summary
: rat-do-cpu ( rec -- )
    rat-cur !
    rat-st-clear
    0 rat-con-run-u ! 0 rat-con-skip-u !
    rat-only @ 1 and if rat-do-stack then
    rat-only @ 2 and if rat-do-cross then
    rat-only @ 4 and if rat-do-con then
    rat-only @ 8 and if rat-do-isa then
    rat-cpu-line
    rat-outcome
    rat-json-cpu ;
: rat-run-core ( -- rc )
    rat-discover
    \ f"Discovered {n} CPUs with kernels: {a, b, ...}\n" + пустая строка
    ." Discovered " rat-n @ rat-n. ."  CPUs with kernels: "
    rat-n @ 0 ?do
        i 0 > if ." , " then
        i rat-cpus @ ulist-nth-addr dup r-na @ swap r-nu @ type
    loop
    cr
    \ цикл cpu: этапы + console line + any_error/summary
    rat-n @ 0 ?do
        i rat-cpus @ ulist-nth-addr rat-do-cpu
    loop
    cr
    \ валидация спек (python: независимо от discovery — stm8 и т.п.)
    rat-specs-check
    rat-specs-print
    \ Tool summary
    ." Tool summary:"
    4 0 do i rat-summary-line loop
    cr
    rat-json-close
    rat-any-error @ if 1 else 0 then ;

\ ------------------------------------------------------------------
\ Точка входа (паритет `python3 tools/run_all_tools.py`)
\ ------------------------------------------------------------------
: run-all-tools ( -- rc )
    15 rat-only !
    0 rat-dry !
    0 rat-jfid !
    0 rat-any-error ! 0 rat-ispec ! 0 rat-iskip !
    12 0 do 0 i cells rat-cnt + ! loop
    rat-run-core ;

\ ------------------------------------------------------------------
\ CLI: --dry-run, --only <stack,cross,con,isa>, --stack-report <path>,
\ --json <path> (cpus + isa_specs + con_run/con_skip when present)
\ ------------------------------------------------------------------
create rat-comma 44 c,                \ "," ASCII44
variable rat-oa variable rat-ou             \ остаток --only-списка
variable rat-only-seen                      \ --only уже встречался

: rat-only-token ( a u -- ) \ токен списка -> бит в rat-only
    2dup s" stack" compare 0= if 2drop rat-only @ 1 or rat-only ! exit then
    2dup s" cross" compare 0= if 2drop rat-only @ 2 or rat-only ! exit then
    2dup s" con" compare 0= if 2drop rat-only @ 4 or rat-only ! exit then
    2dup s" isa" compare 0= if 2drop rat-only @ 8 or rat-only ! exit then
    2drop ;                                \ неизвестный: просто не входит

\ "stack,cross,..." -> rat-only (первый --only заменяет маску целиком)
: rat-only-parse ( a u -- )
    rat-only-seen @ 0= if
        0 rat-only ! -1 rat-only-seen !
    then
    rat-ou ! rat-oa !
    begin rat-ou @ 0> while
        rat-oa @ rat-ou @ rat-comma 1 search if
            \ ( a3 u3 ): a3 = адрес ","; токен = ( oa, a3-oa )
            over rat-oa @ -                \ ( a3 u3 tlen )
            rat-oa @ swap                  \ ( a3 u3 oa tlen )
            rat-only-token                 \ ( a3 u3 )
            >r 1+ r> 1-                   \ ( a3+1 u3-1 )
            rat-oa ! rat-ou !
        else
            2drop
            rat-oa @ rat-ou @ rat-only-token
            0 rat-ou !
        then
    repeat ;
: rat-cli-refused ( a u -- rc ) \ непонятный/запрещённый аргумент
    cr ." run_all_tools: argument not supported: " type cr
    1 ;

: run-all-cli ( -- rc )
    15 rat-only !
    0 rat-dry !
    0 rat-jfid !
    0 rat-only-seen !
    begin next-arg dup while
        2dup s" --dry-run" compare 0= if
            2drop -1 rat-dry !
        else
            2dup s" --only" compare 0= if
                2drop next-arg
                rat-only-parse
            else
                2dup s" --stack-report" compare 0= if
                    2drop next-arg 2drop
                else
                    2dup s" --json" compare 0= if
                        2drop next-arg rat-json-open
                    else
                        rat-cli-refused exit
                    then
                then
            then
        then
    repeat
    2drop
    0 rat-any-error ! 0 rat-ispec ! 0 rat-iskip !
    12 0 do 0 i cells rat-cnt + ! loop
    rat-run-core ;
