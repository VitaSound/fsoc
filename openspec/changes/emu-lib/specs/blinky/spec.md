# Spec Delta

## MODIFIED Requirements

### Requirement: Эмуляция не знает задачу
`emu/` MUST содержать только общую библиотеку эмуляции (консоль `con_pin` / `con_uart` с экраном строки набора, такт, UART-кодек, скрипт сеанса) и MUST NOT содержать `main` задачи. `main` MUST жить рядом с задачей и MUST соединять порты `Vtop` со словами библиотеки, не повторяя цикл тактов. Сборка эмуляции MUST копировать `main` в каталог проекта вместе с библиотекой. Blinky экран строки набора MUST NOT открывать.

#### Scenario: main blinky рядом с задачей
- **WHEN** собрана эмуляция blinky
- **THEN** `main` взят из `fsoc/tasks/blinky_main.cpp`, в каталоге проекта есть его копия и копии `emu/*.cc`, в `emu/` нет файла с именем blinky, а в `blinky_main.cpp` нет `sleep_until` и `std::signal`
