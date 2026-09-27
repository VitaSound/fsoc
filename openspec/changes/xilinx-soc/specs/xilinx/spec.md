## ADDED Requirements

### Requirement: Сборка консоли под Xilinx
Появится таргет Xilinx отдельным файлом, не веткой `targets/quartus.4th`, и плата разработки Xilinx на кристалле XCKU5P с тулчейном Vivado. Пины платы MUST прийти из названного источника и MUST NOT быть выдуманы. Проект консоли MUST собираться задачей `soc` и дизайном `designs/soc_console.4th`. `--build` MUST записать файлы проекта и MUST NOT требовать, чтобы имя задачи жило в таргете. `USE_REGIO` MUST остаться 1. Эта возможность MUST NOT вливаться в основные спеки, пока проверка на DE0-Nano не закрыта.

#### Scenario: Проект консоли
- **WHEN** в каталоге проекта Xilinx выполняется `fsoc --build`
- **THEN** в каталоге есть топ с `USE_REGIO(1)` и `.led(led)`, а таргет не содержит литерал `soc`
