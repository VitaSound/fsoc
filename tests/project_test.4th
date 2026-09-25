\ tests/project_test.4th — manifest words fill the project record

s" test_common.4th" included
s" load.4th" included

project-new
s\" s\" blinky\" task:  s\" quartus\" target:  s\" rz_easyfpga\" board:  s\" designs/blinky_top.4th\" design:  s\" led-bit\" s\" 4\" option:  s\" lamp\" s\" 1\" option:" evaluate

project@ project.task@ s" blinky" expect-str-eq
project@ project.target@ s" quartus" expect-str-eq
project@ project.board@ s" rz_easyfpga" expect-str-eq
project@ project.design@ s" designs/blinky_top.4th" expect-str-eq
project@ project.dir@ cwd@ expect-str-eq
s" led-bit" project@ project.opt@ s" 4" expect-str-eq
s" lamp" project@ project.opt@ s" 1" expect-str-eq
s" nosuch" project@ project.opt@ nip 0= expect-true
s" lamp" project@ project.opt? expect-true
s" nosuch" project@ project.opt? expect-false
project@ ' project-check catch 0= expect-true

s" x.v" project@ project.file
2dup cwd@ s" /x.v" fjson.str-concat 2dup 2>r expect-str-eq 2r> fjson.str-free
fjson.str-free

\ A manifest without a target is rejected.
project-new
s" blinky" task:
project@ ' project-check catch 0<> expect-true
drop

project-new
s" designs/blinky_top.4th" project@ project.design-or s" designs/blinky_top.4th" expect-str-eq
s" x" design:
s" designs/blinky_top.4th" project@ project.design-or s" x" expect-str-eq

expect-stack-clean
cr ." project_test ok" cr
