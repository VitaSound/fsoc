# Design

## Context

См. proposal.md — Why. Плата `terasic_de0nano` уже описывает `clk50` (`R8`, 50 МГц), `user_led` 0 (`A15`) и `serial` tx/rx (`B5`/`B4`), устройство `EP4CE22F17C6`. Задача `soc` и таргет `quartus` уже собирают консоль по манифесту: дизайн `designs/soc_console.4th` не называет плату. Рабочий пример — уходящий `projects/soc_vitasound_ep4ce10/target.4th`. Blinky на DE0-Nano уже есть: `projects/blinky_terasic_de0nano`.

## Goals / Non-Goals

**Goals:**

- Один новый манифест `projects/soc_terasic_de0nano/target.4th` на существующей задаче и таргете.
- Убрать каталоги проектов и файлы плат, которые больше не грузятся.
- Перенести тестовые фикстуры и сценарии спек на оставшиеся платы, не меняя слова билдера.

**Non-Goals:**

- Новые пины, другой дизайн, другой таргет, правка `designs/soc_console.4th` или `targets/quartus.4th`.
- Проект лампы на DE0-Nano.
- Правка архива `openspec/changes/archive/` и старых записей CHANGELOG.

## Decisions

1. Имя каталога `soc_terasic_de0nano` — тот же шаблон, что `soc_vitasound_ep4ce10` и `blinky_terasic_de0nano`: задача, затем плата.
2. Манифест копирует четыре строки уходящего SoC и подставляет `terasic_de0nano`. Путь дизайна `designs/soc_console.4th` от `FSOC_HOME`, как у `soc_emul`.
3. Пины не дублируются в задаче. Их уже отдаёт плата; тест проверяет строки `.qsf`, которые пишет существующий `quartus-map-sub`.
4. Секции blinky для VitaSound и RZ удаляются, а не переписываются inline-манифестом: плат больше нет. Покрытие Cyclone II остаётся на `ep2c5_mini`, покрытие Cyclone IV E — на `terasic_de0nano`.
5. Сценарий «три платы» в platform называет `terasic_de0nano`, `ep2c5_mini` и `colorlight_5a_75e_v6_0`: три разных устройства и семейства из оставшегося каталога. Частота `clk50` = 50000000 проверяется только на двух платах с тактом 50 МГц; Colorlight — 25 МГц и в этот сценарий не входит.
6. Главные спеки не правятся в apply. Их обновляет archive из дельт.

## Risks / Trade-offs

- [Тест `request-all` на VitaSound считал светодиоды той платы] → На DE0-Nano восемь `user_led`; ожидание длины списка запросов берётся из этой платы, а не из старого числа 4.
- [Документы и `openspec/config.yaml` ещё называют удалённые платы] → Тот же change правит README, AGENTS.md, roadmap и блок «Уже сделано». Исторический CHANGELOG не трогается.

## Migration Plan

1. Добавить `projects/soc_terasic_de0nano/target.4th`.
2. Удалить три каталога `projects/` и два файла `boards/`.
3. Поправить тесты и документы под дельты.
4. `fmix test`. Пункт в CHANGELOG `[0.7.0]`.
5. Archive вливает дельты в `openspec/specs/`.

Откат — вернуть четыре файла из git и убрать новый каталог. Слова билдера не меняются, отдельной миграции данных нет.
