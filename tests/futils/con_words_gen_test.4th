\ ------------------------------------------------------------------
\ Тесты fsoc/futils/con_words_gen.4th — извлечение ANS-имён слов
\ Пути: include резолвится от каталога включающего файла, runtime-путь
\ (open-file) — от CWD (корень репо, pre-commit делает cd).
\ ------------------------------------------------------------------

s" ../../fsoc/futils/con_words_gen.4th" included
s" helper.4th" included

\ cwg-has ( na nu -- f ) — найдено ли имя среди извлечённых k-слов
variable cwgt-qa   variable cwgt-qu   variable cwgt-found
: cwg-has ( na nu -- f )
    cwgt-qu !   cwgt-qa !   0 cwgt-found !
    cwg-kw-n @ 0 ?do
        cwgt-found @ 0= if
            i 64 * cwg-kw-names +      \ (name-a)
            i cwg-kw-lens-arr + c@     \ (name-a name-u)
            cwgt-qa @ cwgt-qu @              \ (name-a name-u query-a query-u)
            cwg-str=                   \ (f)
            if 1 cwgt-found ! then
        then
    loop
    cwgt-found @ ;

\ FIXTURE: простой kernel.4th — 3 строки формата `s" name" 0 s" impl" k-pc k-word`
s" tests/futils/con_words_gen_fixtures/kernel.4th" cwg-scan-kernel-file
cwg-kw-n @ 3 Aeq

\ Имена реально лежат в массиве (первое s" на строке, без кавычки)
s" dup"  cwg-has AtTrue
s" drop" cwg-has AtTrue
s" +"    cwg-has AtTrue

\ FIXTURE: пустой файл — счётчик сбрасывается внутри скана
s" /dev/null" cwg-scan-kernel-file
cwg-kw-n @ 0 Aeq

futils-test-finish
