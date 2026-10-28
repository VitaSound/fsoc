# Soft-AVR (Verilator)

CI and Day-1 AVR emulation use a **soft AVR CPU** under Verilator, not simavr.

## Sources

| Path | Role |
|------|------|
| [`cpu/avr/`](../cpu/avr/) | Vendored [nanamake/avr_cpu](https://github.com/nanamake/avr_cpu) (MIT) + NOTICE |
| `cpu/avr/top_blink.v` | PM/DM + DDRB/PORTB → `led` |
| `cpu/avr/top_soc.v` | Same + minimal USART for fsys `KEY`/`EMIT` |

Part files under `fsys/fasm/avr/*.4th` and Proteus ISIS remain for **HEX / hard** flows. They are not the CI emulator.

## Projects

| Project | Gate |
|---------|------|
| `projects/baremetal/blinky_avr_emul` | `FSOC_EMU_CON=pin FSOC_EMU_EDGES=4` — ≥2× `pin led 0` / `1` |
| `projects/soc/soc_avr` | UART session / `con_core` |
| `projects/soc/soc_avr_blink` | Soc blink + pin edges |

## Tests

- `tests/avr_pin_test.4th`, `tests/avr_soft_blink_test.4th`, `tests/avr_soc_blink_test.4th`
- `tests/con_core_test.4th` (AVR row via `avr-con-session` → Verilator)
- `tests/avr_con_test.4th`, `tests/avr_words_test.4th`

No `tools/avr-con`, `tools/avr-pin`, or simavr package is required.
