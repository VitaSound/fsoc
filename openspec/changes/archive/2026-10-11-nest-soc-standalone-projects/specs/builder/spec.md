# Spec Delta

## MODIFIED Requirements

### Requirement: Blinky без Forth лежит в baremetal
Рабочие копии задачи `blinky` MUST жить в `projects/baremetal/<имя>/`. Рабочие копии задачи `soc` MUST жить в `projects/soc/<имя>/`. Рабочие копии задачи `standalone` MUST жить в `projects/standalone/<имя>/`. Git MUST хранить только `target.4th` на втором уровне внутри каждого из этих каталогов категорий.

#### Scenario: Манифест HDL-blinky не игнорируется
- **WHEN** выполняется `git check-ignore -q projects/baremetal/blinky_emul/target.4th`
- **THEN** код возврата не 0

#### Scenario: Манифест soc не игнорируется
- **WHEN** выполняется `git check-ignore -q projects/soc/soc_emul/target.4th`
- **THEN** код возврата не 0

#### Scenario: Манифест standalone не игнорируется
- **WHEN** выполняется `git check-ignore -q projects/standalone/standalone_j1a/target.4th`
- **THEN** код возврата не 0
