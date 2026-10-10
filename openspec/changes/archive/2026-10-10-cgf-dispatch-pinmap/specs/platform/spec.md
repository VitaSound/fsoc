# Spec Delta

## ADDED Requirements

### Requirement: Общий маппинг пинов платы
Платформенный слой MUST предоставлять слова `board-map-clock`, `board-map-led`, `board-map-uart` и `pin-map` (в `fsoc/platform-pinmap.4th`, после `targets/quartus.4th`), которые при загруженной платформе делают `request` нужных ресурсов и вызывают `quartus-map` / `quartus-map-sub` как compile-time xt. Без загруженной платформы (`current-platform` = 0) эти слова MUST завершаться без ошибки и без записи в `.qsf`. Задачи `blinky`, `soc` и CG=F MCU-мапперы (`*-map` / `*-map-board`) MUST использовать эти слова для такта, LED и UART вместо собственных копий `request` + `quartus-map` для тех же ресурсов.

#### Scenario: blinky на DE0-Nano через helpers
- **WHEN** в `projects/baremetal/blinky_terasic_de0nano` выполняется `fsoc --build`
- **THEN** в `.qsf` есть назначение такта на `clk` и `user_led` на `led`, как до рефакторинга

#### Scenario: soc с UART через helpers
- **WHEN** в проекте `soc` на `terasic_de0nano` выполняется `fsoc --build`
- **THEN** в `.qsf` есть `clk`, `led`, `uart_tx` и `uart_rx`

#### Scenario: Эмуляция без платы
- **WHEN** задача вызывает `board-map-clock` / `board-map-led` / `board-map-uart` без загруженной платформы
- **THEN** слова завершаются без `abort"` и без записи `.qsf`
