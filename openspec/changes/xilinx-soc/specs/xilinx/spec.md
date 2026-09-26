## ADDED Requirements

### Requirement: Сборка консоли под Xilinx
Появится таргет Xilinx и плата с тактом, светодиодом и UART. Проект консоли MUST собираться задачей `soc` и дизайном `designs/soc_console.4th`. `--build` MUST записать файлы проекта и MUST NOT требовать, чтобы имя задачи жило в таргете. `USE_REGIO` MUST остаться 1. Эта возможность MUST NOT вливаться в основные спеки, пока проверка на DE0-Nano не закрыта.

#### Scenario: Проект консоли
- **WHEN** в каталоге проекта Xilinx выполняется `fsoc --build`
- **THEN** в каталоге есть топ с `USE_REGIO(1)` и `.led(led)`, а таргет не содержит литерал `soc`
