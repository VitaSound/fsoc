# Spec Delta

## ADDED Requirements

### Requirement: Blinky без Forth лежит в baremetal
Рабочие копии задачи `blinky` MUST жить в `projects/baremetal/<имя>/`. Git MUST хранить только `target.4th` на втором уровне. `projects/soc_*` MUST оставаться прямо в `projects/`.

#### Scenario: Манифест HDL-blinky не игнорируется
- **WHEN** выполняется `git check-ignore -q projects/baremetal/blinky_emul/target.4th`
- **THEN** код возврата не 0
