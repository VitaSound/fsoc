# Tasks

## 1. cpu% xt-поля

- [x] 1.1 Добавить в `fsoc/cpu.4th` поля `cpu.cg-soc` и `cpu.cg-blinky`, сеттеры `cpu-cg-soc` / `cpu-cg-blinky` (xt на `current-cpu`) и слово проверки нулевого xt; убедиться, что `gforth` загружает `fsoc/cpu.4th` без ошибки
- [x] 1.2 В конце `fsoc/tasks/cg-f.4th` (или после определений avr) зарегистрировать `' avr-hex` / `' avr-blinky` для профиля `avr`; проверить `s" avr" cpu-find cpu.cg-soc @` ненулевой после загрузки билдера
- [x] 1.3 Зарегистрировать xt для `bcpu`, `cd16`, `msl16`, `z80` в соответствующих `cg-*.4th` (`*-soc` / `*-blinky`); проверить ненулевые поля у всех пяти профилей

## 2. Диспетчеризация без id-compare

- [x] 2.1 Переписать `: cg-f` на `cpu.cg-soc @ execute` с `cpu-stop` при нуле; удалить лестницу `s" avr" compare` …; проверить, что в теле `cg-f` нет id-compare
- [x] 2.2 Переписать `blinky-mcu-f` на `cpu.cg-blinky` (оставить проверку CG=`F`); удалить id-compare; проверить тело слова
- [x] 2.3 Собрать `cd projects/baremetal/blinky_atmega && fsoc --build` и один soc CG=F (`soc` с `avr` или `bcpu` + `fsys`) — оба завершаются без abort и пишут ожидаемый образ

## 3. Platform pinmap helpers

- [x] 3.1 Добавить в `fsoc/platform.4th` слова `board-map-clock`, `board-map-led`, `board-map-uart`, `pin-map` по design.md; без платформы — тихий выход; проверить загрузку файла
- [x] 3.2 Перевести `blinky-map-board` и `soc-map-board` на helpers (оставив `quartus-project` / `quartus-top` / `quartus-clock` в задаче); `cd projects/baremetal/blinky_terasic_de0nano && fsoc --build` и `cd projects/soc_terasic_de0nano && fsoc --build` — в `.qsf` есть clk/led (и uart у soc)
- [x] 3.3 Перевести `bcpu-map`, `cd16-map`, `msl16-map`, `z80-map` на helpers + `pin-map` для `user_btn`; точечный `--build` одного MCU-проекта с платой или существующий тест pinmap

## 4. Проверка и документация

- [x] 4.1 Прогнать `fmix test` — полный suite зелёный
- [x] 4.2 Обновить `CHANGELOG.md` краткой записью о xt-dispatch и pinmap helpers
- [x] 4.3 `openspec validate --change cgf-dispatch-pinmap` — без ошибок
