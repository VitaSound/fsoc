# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.9.0-green.svg)](https://github.com/VitaSound/fsoc)

Русская версия. English: [README-eng.md](README-eng.md).

Сборщик SoC на Форте: **платы**, **тулчейны Quartus/Yosys/Verilator**, **iomap**, **прошивка J1**. Аналог LiteX `build` + `soc` на Gforth. Модули Verilog приходят из [fhdlgen](https://github.com/VitaSound/fhdlgen) и [hdl-modules](https://github.com/VitaSound/hdl-modules). Пресс-релиз: [doc/PRESS-RELEASE-ru.md](doc/PRESS-RELEASE-ru.md).

## Установка

```bash
git clone git@github.com:VitaSound/fsoc.git
cd fsoc && fmix packages.get
fmix test
```

Оболочка (см. [feco shell-setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md)):

```bash
export FSOC_HOME="$HOME/fsoc"
export PATH="$FSOC_HOME/bin:$PATH"
fsoc version
```

[WavePeek](https://kleverhq.github.io/wavepeek/) ставится по желанию. `fmix test` его не вызывает. Он отвечает на вопросы о `trace.vcd` из эмуляции. Скрипт установки с того сайта кладёт `wavepeek` в `~/.local/bin`; этот каталог должен быть в `PATH` (оболочка входа берёт его из `~/.profile`).

```bash
curl --proto '=https' --tlsv1.2 -LsSf https://kleverhq.github.io/wavepeek/install.sh | sh
wavepeek --version
```

Навык агента в этом репозитории — [`.cursor/skills/wavepeek`](.cursor/skills/wavepeek) (пин 3.0.1). Обновить его из того же бинарника:

```bash
wavepeek skill .cursor/skills/wavepeek
```

`fmix test` включает общую сетку консоли fsys [`tests/con_core_test.4th`](tests/con_core_test.4th) (j1a, j1b, avr, bcpu: ввод, стирание, неизвестное слово, стек, `+`, `.s`, `:`, `words`). Оракул: [`tests/con_words.py`](tests/con_words.py) против `doc/j1-word-graph/fsys-*.json`. Один файл:

```bash
export FSOC_HOME="$HOME/fsoc"
cd tests && gforth con_core_test.4th
```

UART ATmega8 под simavr для клона необязателен. Пакеты: `simavr`, `libsimavr-dev`, `gcc`. Без них срез AVR в `con_core_test` и [`tests/avr_con_test.4th`](tests/avr_con_test.4th) пропускается. Из собранного проекта: `~/fsoc/tools/avr-con ./firmware.hex`. См. [ATmega8](#atmega8). Новый `cpu:` с ядром fsys должен войти в эту сетку — [Новый CPU](#новый-cpu) и `.cursor/rules/fsoc-cpu-target.mdc`.

## Мигалка

Мигалка — одна задача. Лист — [`rtl/blinky.v`](rtl/blinky.v) (`clk` / `led`, `LED_BIT` по умолчанию 25). [`designs/blinky_top.4th`](designs/blinky_top.4th) включает этот файл и ставит его как `top`. Рабочие решения лежат в [`projects/`](projects/). **В git в каждом каталоге остаётся только `target.4th`.** `fsoc --build` пишет остальное (`top.v`, копии листьев, `firmware.hex`, `sim.sh` / `.qsf`, `obj_dir`, …) в этот каталог; `.gitignore` не пускает эти файлы в коммит. После клона `projects/soc_blink/` — один манифест.

Задачу и дизайн отлаживают в проекте `emulation` (`blinky_emul`, `soc_emul`, `soc_blink`). Проект платы — та же задача и тот же дизайн с `quartus` и `board:`.

```text
projects/baremetal/blinky_emul/                  Verilator в реальном времени, LED_BIT=25, события пина в консоли
projects/baremetal/blinky_terasic_de0nano/       Quartus .qsf, Terasic DE0-Nano
projects/baremetal/blinky_colorlight_5a_75e_v6_0/  Yosys .lpf, nextpnr-ecp5, ecppack
projects/soc_blink_colorlight_5a_75e_v6_0/  образ лампы, та же плата и те же инструменты
```

`fsoc` запускают из каталога проекта. Задача и плата записаны в `target.4th`, а не в командной строке:

```forth
s" blinky" task:            \ зарегистрированная задача (fsoc/tasks/)
s" quartus" target:         \ emulation | quartus | yosys
s" terasic_de0nano" board:  \ boards/<name>.4th; для эмуляции поле не нужно
s" designs/soc_top.4th" design:   \ верх fhdlgen, путь от FSOC_HOME (только soc)
s" lamp" s" 1" option:      \ опция задачи
```

`--build` выполняет emit задачи, затем `emit` и `run` таргета; `--load` выполняет `load` таргета. `--clean` удаляет все остальные файлы в каталоге проекта и оставляет `target.4th`. Без этого файла команда отказывается работать. `--clean --build` стирает вывод и собирает заново. Каждый файл репозитория (`rtl/`, `cpu/`, `emu/`, `designs/`, `boards/`) находится через `FSOC_HOME`; каталог проекта — текущий каталог.

| Таргет | `emit` | `run` | `load` |
|--------|--------|-------|--------|
| `emulation` | `emu/{con,clock,uart,script,trace}.*`, обвязка задачи, `sim.sh` | `sh sim.sh` до Ctrl+C или `FSOC_EMU_CYCLES` | ничего |
| `quartus` | `<project>.qpf`, `.qsf`, `.sdc`, `build.sh`, `load.sh` | ничего | `sh load.sh` |
| `yosys` | `<project>.lpf`, `build.sh`, `load.sh` | `sh build.sh` | `sh load.sh` |

Эмуляция — Verilator. `fsoc --build` пишет проект и идёт в реальном времени (шаг стены 50 МГц) до Ctrl+C. Консоль печатает строку на событие, а не на такт: `t=<ns> pin led <value>`, когда меняется `led` (`LED_BIT=25`, около 0,67 с). Тот же принтер — `con_uart` для будущего декодера последовательного порта (строка на принятый байт).

```bash
cd projects/baremetal/blinky_emul
fsoc --build
```

`FSOC_EMU_TRACE=1` на этом `--build` собирает просмотрщик с Verilator `--trace` и пишет `trace.vcd` (4096 тактов, или `FSOC_EMU_CYCLES`, если этот предел длиннее). Прогон затем идёт до обычной остановки. Из каталога проекта `"$FSOC_HOME/tools/peek.sh" info` отдаёт этот файл WavePeek. Бинарник ставят как в разделе [Установка](#установка).

Quartus (`--build` пишет файлы проекта и сам Quartus не запускает; задача отображает `clk50`→`clk` и `user_led`→`led`). Откройте `<project>.qpf` в Quartus II 11 (`QUARTUS_VERSION` 11.0, имя ревизии совпадает с `.qsf`). `FAMILY` в кавычках. Каждое имя в `includes.lst` — это `VERILOG_FILE`, и строки `` `include `` из верха убраны. Пин платы `LVTTL` — это `IO_STANDARD "3.3-V LVTTL"`. Выход дополнительно получает `CURRENT_STRENGTH_NEW 8MA` и `SLEW_RATE 2`. `blinky.sdc` записан как `SDC_FILE` и заканчивается `derive_clock_uncertainty`. Предупреждение 169177, напоминание AN 447 о входе 3.3-V LVTTL, подавлено. `--load` прошивает плату. На эмуляции `--load` ничего не делает.

```bash
cd projects/baremetal/blinky_terasic_de0nano
fsoc --build
fsoc --build --load
```

Yosys (`--build` пишет LPF и скрипты, затем запускает `sh build.sh`). Такт и светодиод берутся с платы (`clk25` на Colorlight 5A-75E). `yosys` и `nextpnr-ecp5` берутся из `PATH`. Если их там нет, а `~/oss-cad-suite` установлен, прогон инструментов сам подключает `environment` этого набора. `load.sh` вызывает `openFPGALoader` только когда в манифесте есть `s" cable" s" <name>" option:`. `FSOC_SYNTH_SKIP` пропускает прогон инструментов и всё равно пишет файлы. В базе плат есть ещё ревизии 7.1 и 8.2; рабочий проект — 6.0.

```bash
cd projects/baremetal/blinky_colorlight_5a_75e_v6_0
fsoc --clean
fsoc --build
```

Один разведённый fit nextpnr этой мигалки (2026-09-26, `LFE5U-25F`, `--25k`) уложился в ограничение 25,00 МГц при 289,35 МГц. Битстрим `blinky.bit` — 582369 байт. Блочная RAM свободна.

| Ресурс | Занято | На LFE5U-25F |
|--------|--------|----------------|
| LUT4 | 27 (1 логики, 26 переноса) | 24288 (0%) |
| DFF | 26 | 24288 (0%) |
| RAM LUT | 0 | 3036 |
| RAMW LUT | 0 | 6072 |
| DP16KD | 0 | 56 |
| TRELLIS_IO | 2 | 197 |
| MULT18X18D | 0 | 28 |

## Минимальный SoC

`projects/soc_emul` — задача сборщика. `fsoc --build` кросс-компилирует SwapForth J1a, загружает `firmware.hex` в приложенное ядро J1 и запускает Verilator до Ctrl+C. Поле манифеста `cpu:` выбирает профиль Форта. Задача `soc` без `cpu:` — это `j1a`. Образ — словарь ANS CORE этой системы без `environment?`. На терминале сеанс — экран ncurses: текст UART прокручивается сверху, нижняя строка — строка хоста. Знаки, включая не-ASCII, появляются там по мере набора; Enter отправляет строку. Ответ заканчивается ` ok`. `FSOC_EMU_CON=log` печатает каждый байт UART как `t=<ns> uart tx <byte>`. `FSOC_EMU_CON=term` включает текстовый вид. Перенаправленный прогон остаётся на журнале байтов, пока не задан `term`. Карта io пишется как `csr.fs` (константы SwapForth `IO-LED` …), `iomap.vh` (`localparam` обёртки) и `csr.json` (`bus` `j1-io`).

```bash
cd projects/soc_emul
fsoc --build
```

`projects/soc_emul_colorlight_5a_75e_v6_0` — та же консоль с тактом Colorlight 5A-75E v6.0, 25 МГц. UART остаётся в симуляторе: на плате нет последовательных пинов, и этот верх держит `uart_rx`, `uart_tx`, `rst` и `dump`. `sim.sh` использует `CLK_HZ=25000000`, то же значение, что в `top.v`, поэтому время бита совпадает. Строка `1 2 + .` по-прежнему отвечает `3 ok`.

```bash
cd projects/soc_emul_colorlight_5a_75e_v6_0
FSOC_EMU_FAST=1 FSOC_EMU_UART_IN='1 2 + .' fsoc --build
```

`projects/soc_blink` — то же ядро со словом `'BOOT`, которое не возвращается к приглашению. Цикл пишет `0` и `1` в `IO-LED`. Этот бит выходит из `top` как `led`. Пауза — чтение `IO-TIMER`. Цикл также шлёт `lamp on` и `lamp off` в UART. Фоновая задача и контроллер прерываний — следующий шаг, он описан в [doc/stm8ef-hw.md](doc/stm8ef-hw.md).

С `s" fsys" sys:` словарь можно урезать. `s" image" s" release" option:` рядом с `s" lamp" s" 1" option:` оставляет лампу и корни компилятора в `fsys/<cpu>/release.4th`. Если `image` не задан или равен `debug`, остаются полные слои. Замер на этом проекте: j1a release `firmware.hex: 2822 bytes of 8192`, debug `7752 bytes of 8192`; j1b release `2956 bytes of 32768`, debug `9156 bytes of 32768`. Пустая строка soc и эти четыре пары лежат в [doc/j1-word-graph/soc-sizes.md](doc/j1-word-graph/soc-sizes.md). Файл заново пишет `python3 doc/j1-word-graph/build.py sizes`.

`FSOC_EMU_CON` выбирает вид. `term` пишет байты UART, поэтому фразы лампы видны текстом. `log` печатает каждый байт UART как `t=<ns> uart tx <byte>`. `pin` печатает только `t=<ns> pin led 0` и `t=<ns> pin led 1` и байты UART не пишет. Прогон без готовой строки UART кончается по Ctrl+C или `FSOC_EMU_CYCLES`. Тесты берут `FSOC_EMU_CYCLES=800000` с `FSOC_EMU_FAST=1`.

```bash
cd projects/soc_blink
FSOC_EMU_CON=term FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=800000 fsoc --build
FSOC_EMU_CON=pin FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=800000 fsoc --build
```

## ATmega8

`projects/soc_atmega8` — консоль Форта (`s" fsys" sys:`): ядро плюс `fsys/avr/extra-min.4th` (`cr`, `type`, арифметические помощники), без портов, Intel HEX. `projects/soc_atmega8_blink` собирает образ **release**: `s" image" s" release" option:` плюс `firmware/blink.fs` (PB0 и текст USART) на `fsys/avr/extra.4th`, не на extra-min. `projects/baremetal/blinky_atmega` — та же **задача** `blinky`, что и копии на ПЛИС, с `s" avr" cpu:`: fasm собирает `firmware/blink_avr.4th` (PB0), без ядра. Журнал печатает `Hardware` / `atmega8(avr)`, затем `Software` / `image tool: fsys` или `fasm` / `firmware.hex: <used> bytes of 8192`. `fsoc --build` Proteus не запускает. Такт, светодиод и Virtual Terminal описаны в [doc/atmega8-proteus.md](doc/atmega8-proteus.md).

Proteus с HEX release: USART на 9600 по `PD1`/`PD0` печатает `blink on` / `blink off` в Virtual Terminal. Тот же текст виден под `tools/avr-con`.

![Мигалка Форта на ATmega8 в Proteus: Virtual Terminal печатает blink on / blink off](doc/atmega8-proteus-blink.png)

```bash
cd projects/soc_atmega8 && fsoc --build
cd projects/soc_atmega8_blink && fsoc --build
cd projects/baremetal/blinky_atmega && fsoc --build
```

На Linux до Proteus консоль UART — это [`tools/avr-con`](tools/avr-con) (simavr). Штатный CLI `simavr` не отдаёт клавиатуру в USART, поэтому после `ok` образ ждёт `KEY` без ввода. Поставьте пакеты и запустите обёртку из каталога проекта, где лежит `firmware.hex`. Первый запуск собирает `tools/avr-con.bin` через `gcc`.

```bash
sudo apt install simavr libsimavr-dev gcc
cd projects/soc_atmega8 && fsoc --build
~/fsoc/tools/avr-con ./firmware.hex
```

Наберите строку Форта и нажмите Enter (уходит как CR). Ctrl-D выходит. Дополнительные аргументы — строки на один раз:

```bash
~/fsoc/tools/avr-con ./firmware.hex words
~/fsoc/tools/avr-con ./firmware.hex '1 2 + .'
```

`simavr` даёт `libsimavr.so.2`; `libsimavr-dev` — заголовки (`/usr/include/simavr`). Без пакета -dev обёртка ищет заголовки в `/tmp/simavr-dev/usr/include/simavr`. Те же заметки по схеме и GDB (`simavr -g`) лежат в [doc/atmega8-proteus.md](doc/atmega8-proteus.md).

## bcpu

`bcpu` — 16-битный аккумулятор (класс 0, FMAP `U-M-B-A-3-F`, MM=U, EX-C=B, CG=F). Набор команд следует [howerj/bit-serial](https://github.com/howerj/bit-serial) (MIT). `cpu/bcpu/bcpu.v` — параллельное АЛУ, а не копия `bit.vhd`. Пустой `sys:` останавливает сборку. `s" fsys" sys:` собирает `fsys/kernel/bcpu`, и хостовый кросс компилирует `fsys/bcpu/extra-min.4th` в образ слово-hex. `cpu/bcpu/bit.hex` остаётся в дереве как исходный образ eForth для указания источника; сборка soc его не загружает. Консоль — строка в `tests/con_core_test.4th`.

`projects/baremetal/blinky_bcpu` — задача `blinky`: fasm собирает `firmware/blink_bcpu.4th`, и журнал показывает `pin led` `0` и `1`. `projects/soc_bcpu` — консоль fsys: `1 2 + .` печатает `3` и ` ok`. `projects/soc_bcpu_blink` компилирует `firmware/bcpu_blink.fs` поверх этого ядра. Журнал пина показывает `0` и `1`, консоль печатает `blink on` и `blink off`. `projects/soc_bcpu_colorlight` — образ консоли на Colorlight 5A-75E v6.0. На плате нет пинов UART: `btn` (`R7`) — линия приёма, передача сложена в светодиод с активным нулём (`leds[0] ^ uart_tx`, простой TX в единице).

Один разведённый fit nextpnr (2026-10-01, `LFE5U-25F`, `--25k`) уложился в ограничение 25,00 МГц при 54,48 МГц. Битстрим `bcpu.bit` — 600913 байт. Критический путь начинается с пина данных блочной RAM, `cpu.mem.0.0.DOB1`.

| Ресурс | Занято | На LFE5U-25F |
|--------|--------|----------------|
| LUT4 | 694 (604 логики, 90 переноса) | 24288 (2%) |
| DFF | 272 | 24288 (1%) |
| RAM LUT | 0 | 3036 |
| DP16KD | 8 | 56 (14%) |
| TRELLIS_IO | 3 | 197 |

Восемь блоков `DP16KD` — память 8192×16 (128 Кбит данных). Каждый блок — 18 Кбит, поэтому эти восемь занимают 144 Кбит. В счёт входят CPU, эта память и `cpu/j1/uart.v`.

```bash
cd projects/baremetal/blinky_bcpu && fsoc --build
cd projects/soc_bcpu && fsoc --build
cd projects/soc_bcpu_blink && fsoc --build
cd projects/soc_bcpu_colorlight && fsoc --build
```

## j1abs

`j1abs` (A Bit Serial) сохраняет набор команд J1a и выполняет его по одному биту на такт (класс 0, FMAP `V-V-A-0-I`, MM=V, EX-C=V, CG=I). `alu_rom` и `ctrl_rom` — синхронные таблицы `512×32`, тела стеков сидят в одной блочной RAM. Порт образа — `j1a`, поэтому SwapForth и `fsys/kernel/j1a` не меняются. Строки `con_core` нет. `projects/baremetal/blinky_j1abs` — задача `blinky`. `projects/soc_j1abs` — консоль fsys (`1 2 + .` печатает `3` и ` ok`). `projects/soc_j1abs_blink` — цикл лампы. `projects/soc_j1abs_colorlight` — этот образ fsys на Colorlight 5A-75E v6.0 (`LFE5U-25F`, 25 МГц, Yosys). На плате нет пинов UART, поэтому верх привязывает `uart_rx` к `1'b1`, не выводит `uart_tx` в список портов и гонит светодиод с активным нулём на `T6`.

```bash
cd projects/baremetal/blinky_j1abs && fsoc --build
cd projects/soc_j1abs && fsoc --build
cd projects/soc_j1abs_blink && fsoc --build
cd projects/soc_j1abs_colorlight && fsoc --build
```

## Данные SPI NOR

Дополнительная SPI NOR — это микросхема данных, а не загрузочное ПЗУ. Сброс J1 остаётся на первом слове внутренней RAM, и `firmware.hex` по-прежнему этот образ. Микросхема не называется `rom`. Команда на шине io читает сплошной диапазон во внутренний буфер; это не окно карты памяти. Строки микросхем живут в `fsoc/soc/nor.4th`. `w25q32jv` — device id `$7016`, 4194304 байта, страница 256, код операции `$03`, без пустых тактов. `w25q64jv` — то же чтение 1-1-1 с другим объёмом. Обе строки используют один лист, [`rtl/spi_nor.v`](rtl/spi_nor.v). `spi_clk` — порт этого модуля. Окно карты памяти флеша и область `main_ram` с базой, размером и шиной — поздние срезы, в этой сборке их нет. Чтение командой проверяется под Verilator и плата не нужна. `csr.json` несёт `regions` рядом с `devices`; без вызова области `regions` равен `[]`, а `led` остаётся на `$400`.

## SoC на плате

`projects/soc_terasic_de0nano` пишет файлы Quartus и `firmware.hex` для консоли SwapForth на Terasic DE0-Nano (`EP4CE22F17C6`). Такт `clk50` — `R8`, `user_led` 0 — `A15`, последовательные tx/rx — `B5`/`B4`. `led` — регистр `IO-LED`: в hex `1 400 io!` поднимает `A15`, `0 400 io!` опускает его. `--build` Quartus не запускает. `--load` запускает `load.sh`. Затем строка хоста на USB UART.

Quartus II 11.1 Build 173, полная компиляция 2026-09-27 02:10:30, timing final. Остаются пять предупреждений map (`$writememh` проигнорирован, четыре усечённых целых литерала). Fitter, assembler и TimeQuest ничего не сообщили. Заметки об этих предупреждениях и об ошибках, закрытых до этого fit: [doc/quartus-ii-11.md](doc/quartus-ii-11.md).

| Ресурс | Занято | Доступно |
| --- | ---: | ---: |
| Logic elements | 1001 (4%) | 22320 |
| Combinational functions | 1000 (4%) | 22320 |
| Dedicated logic registers | 625 (3%) | 22320 |
| Pins | 4 (3%) | 154 |
| Memory bits | 65536 (11%) | 608256 |
| Embedded 9-bit multipliers | 0 | 132 |
| PLLs | 0 | 4 |

Память — firmware RAM 4096×16. Запас setup 9,752 нс (медленно, 85°C), запас hold 0,317 нс. Проверка `1 400 io!` на плате ещё открыта; следующая сборка после неё — Xilinx (`openspec/changes/xilinx-soc`).

```bash
cd projects/soc_terasic_de0nano
fsoc --build --load
gforth tools/fterm.4th /dev/ttyUSB0
```

`fterm` без пути по-прежнему отвечает `ok` из памяти.

`projects/soc_blink_colorlight_5a_75e_v6_0` — образ лампы на Colorlight 5A-75E v6.0 (`LFE5U-25F-6BG256C`, CABGA256, speed 6, nextpnr `--25k`). Такт — `clk25` на `P6`, 25 МГц, LVCMOS33. `T6` — пользовательский светодиод, `R7` — кнопка, поэтому на этой плате нет пинов UART. Верх платы привязывает `uart_rx` к `1'b1`, оставляет `uart_tx` на неиспользуемом проводе и привязывает `rst` и `dump` к `1'b0`. Светодиод с активным нулём: записанная `1` тянет `T6` вниз (`assign led = ~led_q`). Таймер считает миллисекунды (`TIMER_DIV = 25000`, то есть `CLK_HZ/1000`). На нуле счёт стоит до следующей записи, чтобы опрос Форта его увидел. Период лампы в `firmware/lamp.fs` — 500 отсчётов, около половины секунды. `BAUD` на обёртке остаётся 115200. Подача SwapForth, которая пишет `firmware.hex`, по-прежнему идёт на 50 МГц, с тем же временем бита, что и эмуляция; `top.v` платы пишется заново на 25 МГц. `--build` пишет `soc.lpf` и запускает Yosys с `read_verilog -DSYNTHESIS`, поэтому `$writememh` в обёртке в синтез не входит. `FSOC_SYNTH_SKIP` пишет файлы и пропускает инструменты. `load.sh` требует опцию `cable`; в этом манифесте её нет.

Один разведённый fit nextpnr этого образа (2026-09-26) уложился в ограничение 25,00 МГц при 71,55 МГц. Битстрим `soc.bit` — 591641 байт. Критический путь начинается с пина данных блочной RAM, `u.ram.0.3.DOB`.

| Ресурс | Занято | На LFE5U-25F |
|--------|--------|----------------|
| LUT4 | 1135 (1017 логики, 118 переноса) | 24288 (4%) |
| DFF | 697 | 24288 (2%) |
| RAM LUT | 0 | 3036 |
| RAMW LUT | 0 | 6072 |
| DP16KD | 4 | 56 (7%) |
| TRELLIS_IO | 2 | 197 |
| MULT18X18D | 0 | 28 |

Четыре блока `DP16KD` — массив прошивки J1, `4096 × 16` (8 КБ, 64 Кбит данных). Каждый блок — 18 Кбит, поэтому эти четыре занимают 72 Кбит из бюджета блочной RAM 1008 Кбит. Распределённая LUT RAM свободна. Та же лампа на j1a и j1b, полный образ и release, лежит в [doc/j1-word-graph/soc-fit.md](doc/j1-word-graph/soc-fit.md). Файл заново пишет `python3 doc/j1-word-graph/build.py fit`. Эта команда не входит в `fsoc --build`.

```bash
cd projects/soc_blink_colorlight_5a_75e_v6_0
fsoc --build
```

Размещения standalone ниже — одно ядро на плате `lfe5u25f_cabga256` (`LFE5U-25F-6BG256C`). Ограничение — 25,00 МГц. Fmax — разведённый такт. `TRELLIS_IO` — число пинов этого верха. Последняя строка — микросхема.

| Ядро | LUT4 | DFF | DP16KD | TRELLIS_IO | Fmax |
|------|------|-----|--------|------------|------|
| j1a | 1484 (1436 логики, 48 переноса) | 578 | 0 | 82 | 123,24 МГц |
| j1abs | 277 (239 логики, 38 переноса) | 170 | 3 | 82 | 84,08 МГц |
| j1b | 3920 (3836 логики, 84 переноса) | 2164 | 0 | 146 | 93,71 МГц |
| mcpu | 45 (29 логики, 16 переноса) | 24 | 0 | 18 | 245,22 МГц |
| cd16 | 734 (660 логики, 74 переноса) | 95 | 1 | 115 | 62,13 МГц на `clk50`, 97,30 МГц на `clk25` |
| msl16 | 558 (470 логики, 40 переноса, 32 RAM, 16 RAMW) | 54 | 0 | 43 | 84,98 МГц |
| LFE5U-25F | 24288 | 24288 | 56 | 197 | 25,00 МГц |

`projects/standalone_j1a`, `projects/standalone_j1abs` и `projects/standalone_j1b` — ядро и его стеки. Этот файл — карта шаров CABGA256: `clk` на `P6` при 25 МГц, затем обычный PIO, затем шары PCLK. Задача `standalone` привязывает каждый порт модуля `j1` к пину `top`. `j1b` — 32-битное ядро, поэтому `dout`, `io_din` и `mem_din` — 32 бита. Один разведённый fit nextpnr (2026-10-01) уложился в 25,00 МГц. Ту же строку Fmax хранит `doc/j1-word-graph/build.py` для лампы.

Три блока `DP16KD` у j1abs — таблица АЛУ, таблица управления и RAM стека. j1a и j1b держат стеки в триггерах, поэтому у этих двух строк блочной RAM нет.

```bash
cd projects/standalone_j1a
fsoc --build
```

`projects/standalone_mcpu` — экспериментальное микроядро: [MCPU](https://github.com/cpldcpu/MCPU) (GPL-2). Заметки: [doc/mcpu.md](doc/mcpu.md). Профиля Форта у него нет. В `fsoc/cpu.4th` строки нет, консоли и образа soc тоже нет. Хостовый ассемблер — `fsys/fasm/mcpu`: 64 байта, `nor,` `add,` `sta,` `jcc,` `dcb,`. Задача `standalone` привязывает `clk`, `rst`, `oe`, `we`, `adress[5:0]` и `data[7:0]` к пинам `top` на той же корпусной плате. Один разведённый fit nextpnr (2026-10-02) уложился в 25,00 МГц. `oe` и `we` по-прежнему зависят от `clk` в приложенных уравнениях; nextpnr вывел этот пин на глобальную сеть и закончил сборку.

```bash
cd projects/standalone_mcpu
fsoc --build
```

`projects/standalone_cd16` — ядро CD16 из VHDL Брэда Экерта, оставленное ради размера на ECP5. Профиль Форта — `cd16`: `s" fsys" sys:` собирает консоль, проекты — `baremetal/blinky_cd16`, `soc_cd16` и `soc_cd16_blink`. Заметки: [doc/cd16.md](doc/cd16.md). Хостовый ассемблер — `fsys/fasm/cd16` (`cd16-wl`, 65536 слов). Стек — один `DP16KD` на такте 50 МГц; шины программы и данных — пины. Один разведённый fit nextpnr (2026-10-03) уложился в 25,00 МГц на пине. Одно ядро, `synth_ecp5` со всеми портами, — 736 LUT4, 37 `CCU2C` и 94 триггера.

```bash
cd projects/standalone_cd16
fsoc --build
```

`projects/standalone_msl16` — ядро MSL16 из VHDL Филипа Леонга 1998 года. Заметки: [doc/msl16.md](doc/msl16.md). Профиль Форта — `msl16`: `s" fsys" sys:` собирает консоль (слово-hex, 2048 слов, `ADDR=11`), проекты — `baremetal/blinky_msl16`, `soc_msl16` и `soc_msl16_blink`. Хостовый ассемблер — `fsys/fasm/msl16` (четыре слота, `msl16-wl`). Размещение standalone по-прежнему использует 8-битную шину. Два стека 16×16 — LUT RAM (`DPR16X4`). Один разведённый fit nextpnr (2026-10-03, `ADDR=8`) уложился в 25,00 МГц.

```bash
cd projects/standalone_msl16
fsoc --build
```

`tools/fterm.4th` и `firmware/midi_foot.4th`: `fterm` говорит с настоящим портом, когда ему дан путь; `midi_foot` — хостовый макет FOOTSWITCH-SCAN.

## Платы

| Плата | Микросхема | Заметки | последовательный |
|-------|------------|---------|------------------|
| `ep2c5_mini` | EP2C5T144C8 | Quartus II 13.0sp1 | — |
| `terasic_de0nano` | EP4CE22F17C6 | Terasic DE0-Nano, litex-boards; clk `R8`, led `A15` | tx `B5` / rx `B4` |
| `colorlight_5a_75e_v6_0` | LFE5U-25F-6BG256C | clk `P6` 25 МГц, led `T6` активный ноль, btn `R7` | — |
| `colorlight_5a_75e_v7_1` | LFE5U-25F-6BG256C | clk `P6` 25 МГц, led `P11` активный ноль, btn `M13` | — |
| `colorlight_5a_75e_v8_2` | LFE5U-25F-7BG256I | clk `P6` 25 МГц, led `T6` активный ноль, speed 7 | — |
| `lfe5u25f_cabga256` | LFE5U-25F-6BG256C | карта шаров корпуса, clk `P6` 25 МГц, затем PIO, затем PCLK | — |

## Новый CPU

Новая **ISA** — новый id `cpu:` (`fsoc/cpu.4th`, FMAP + CG) со слоями fsys: `fsys/fasm/<id>/` → `fsys/kernel/<id>/` (консоль Форта) → `fsys/host/<id>-cross.4th` → `fsys/<id>/extra.4th`. Новая **микросхема** существующей ISA — только файл части под fasm. У `bcpu` эти слои есть, и его консоль — строка в `tests/con_core_test.4th`. Правило агента: [`.cursor/rules/fsoc-cpu-target.mdc`](.cursor/rules/fsoc-cpu-target.mdc). Навык: `add-cpu-target`. Спеки: [`openspec/specs/forth-cross/spec.md`](openspec/specs/forth-cross/spec.md), [`openspec/specs/fsys/spec.md`](openspec/specs/fsys/spec.md).

Если у id есть консольное ядро fsys, в том же изменении расширьте общую сетку:

1. BS/DEL в `accept` этого ядра (байты 8 и 127, `BS SPACE BS`, на пустой строке игнорировать).
2. Манифест в [`tests/con_session.4th`](tests/con_session.4th) и строка в [`tests/con_core_test.4th`](tests/con_core_test.4th).
3. JSON словаря через [`doc/j1-word-graph/build.py`](doc/j1-word-graph/build.py).
4. Каждое имя JSON помечено в [`tests/con_words.py`](tests/con_words.py) (`run` / `colon` / `skip` с причиной).
5. Слова только этого id — в отдельном `*_test.4th`. Общий REPL не копировать. Файл части микросхемы строку `con_core` не добавляет.

```bash
export FSOC_HOME="$HOME/fsoc"
cd tests && gforth con_core_test.4th
fmix test
```

## Связанное

- [MIT ADR-0003](https://github.com/VitaSound/MIT) — сборщик SoC на Форте
- [feco](https://github.com/VitaSound/feco) — каталог экосистемы
- [fhdlgen](https://github.com/VitaSound/fhdlgen) >= 0.5 — генератор Verilog (`fhdlgen build <design> --out <dir>`)
