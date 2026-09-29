# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.8.0-green.svg)](https://github.com/VitaSound/fsoc)

Forth-native SoC builder: **boards**, **Quartus/Yosys/Verilator toolchains**, **iomap**, **J1 firmware**. Analogue of LiteX `build` + `soc` on Gforth. Verilog modules come from [fhdlgen](https://github.com/VitaSound/fhdlgen) and [hdl-modules](https://github.com/VitaSound/hdl-modules).

## Install

```bash
git clone git@github.com:VitaSound/fsoc.git
cd fsoc && fmix packages.get
fmix test
```

Shell (see [feco shell-setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md)):

```bash
export FSOC_HOME="$HOME/fsoc"
export PATH="$FSOC_HOME/bin:$PATH"
fsoc version
```

[WavePeek](https://kleverhq.github.io/wavepeek/) is optional. `fmix test` does not call it. It answers questions about a `trace.vcd` from emulation. The install script from that site puts `wavepeek` in `~/.local/bin`; that directory must be on `PATH` (a login shell picks it up from `~/.profile`).

```bash
curl --proto '=https' --tlsv1.2 -LsSf https://kleverhq.github.io/wavepeek/install.sh | sh
wavepeek --version
```

The agent skill in this repo is [`.cursor/skills/wavepeek`](.cursor/skills/wavepeek) (pin 3.0.1). Refresh it from the same binary:

```bash
wavepeek skill .cursor/skills/wavepeek
```

## Blinky

Blinky is one task. The leaf is [`rtl/blinky.v`](rtl/blinky.v) (`clk` / `led`, `LED_BIT` defaults to 25). [`designs/blinky_top.4th`](designs/blinky_top.4th) includes that file and instantiates it as `top`. Working solutions live under [`projects/`](projects/). **Git tracks only `target.4th` in each directory.** `fsoc --build` emits the rest (`top.v`, leaf copies, `firmware.hex`, `sim.sh` / `.qsf`, `obj_dir`, …) into that directory; `.gitignore` keeps those files out. After a clone, `projects/soc_blink/` is the manifest alone.

Debug the task and the design in an `emulation` project (`blinky_emul`, `soc_emul`, `soc_blink`). A board project is the same task and design with `quartus` and `board:` — not a second HDL tree.

```text
projects/blinky_emul/                  Verilator realtime, LED_BIT=25, console pin events
projects/blinky_terasic_de0nano/       Quartus .qsf, Terasic DE0-Nano
projects/blinky_colorlight_5a_75e_v6_0/  Yosys .lpf, nextpnr-ecp5, ecppack
projects/soc_blink_colorlight_5a_75e_v6_0/  lamp image, same board and tools
```

Run `fsoc` from the project directory. The task and the board are in `target.4th`, not on the command line:

```forth
s" blinky" task:            \ registered task (fsoc/tasks/)
s" quartus" target:         \ emulation | quartus | yosys
s" terasic_de0nano" board:  \ boards/<name>.4th; omit for emulation
s" designs/soc_top.4th" design:   \ fhdlgen top, path from FSOC_HOME (soc only)
s" lamp" s" 1" option:      \ task option
```

`--build` runs the task's emit, then the target's `emit` and `run`; `--load` runs the target's `load`. `--clean` deletes every other file in the project directory and keeps `target.4th`. It refuses to run when that file is absent. `--clean --build` wipes the output and builds again. Every repository file (`rtl/`, `cpu/`, `emu/`, `designs/`, `boards/`) is found through `FSOC_HOME`; the project directory is the current directory.

| Target | `emit` | `run` | `load` |
|--------|--------|-------|--------|
| `emulation` | `emu/{con,clock,uart,script,trace}.*`, task harness, `sim.sh` | `sh sim.sh` until Ctrl+C or `FSOC_EMU_CYCLES` | nothing |
| `quartus` | `<project>.qpf`, `.qsf`, `.sdc`, `build.sh`, `load.sh` | nothing | `sh load.sh` |
| `yosys` | `<project>.lpf`, `build.sh`, `load.sh` | `sh build.sh` | `sh load.sh` |

Emulation is Verilator. `fsoc --build` emits the project and runs in realtime (50 MHz wall pace) until Ctrl+C. The console prints one line per event, not per clock: `t=<ns> pin led <value>` when `led` changes (`LED_BIT=25`, ~0.67 s). The same printer is `con_uart` for a future serial decoder (one line per received byte).

```bash
cd projects/blinky_emul
fsoc --build
```

`FSOC_EMU_TRACE=1` on that `--build` compiles the viewer with Verilator `--trace` and writes `trace.vcd` (4096 cycles, or `FSOC_EMU_CYCLES` when that limit is longer). The run then continues until its usual stop. From the project directory, `"$FSOC_HOME/tools/peek.sh" info` sends that file to WavePeek. Install the binary as in [Install](#install).

Quartus (`--build` writes the project files and does not run Quartus; the task maps `clk50`→`clk` and `user_led`→`led`). Open `<project>.qpf` in Quartus II 11 (`QUARTUS_VERSION` 11.0, revision name equal to the `.qsf`). `FAMILY` is quoted. Each name in `includes.lst` is a `VERILOG_FILE`, and those `` `include `` lines are removed from the top. A board `LVTTL` pin is `IO_STANDARD "3.3-V LVTTL"`. An output also gets `CURRENT_STRENGTH_NEW 8MA` and `SLEW_RATE 2`. `blinky.sdc` is listed as `SDC_FILE` and ends with `derive_clock_uncertainty`. Warning 169177, the AN 447 reminder on a 3.3-V LVTTL input, is suppressed. `--load` programs the board. On emulation `--load` does nothing.

```bash
cd projects/blinky_terasic_de0nano
fsoc --build
fsoc --build --load
```

Yosys (`--build` writes the LPF and the scripts, then runs `sh build.sh`). The clock and the LED come from the board (`clk25` on the Colorlight 5A-75E). `yosys` and `nextpnr-ecp5` are taken from `PATH`. If they are not there and `~/oss-cad-suite` is installed, the tool run sources that suite's `environment` itself. `load.sh` calls `openFPGALoader` only when the manifest has `s" cable" s" <name>" option:`. `FSOC_SYNTH_SKIP` skips the tool run and still writes the files. The board database also has revisions 7.1 and 8.2; the working project is 6.0.

```bash
cd projects/blinky_colorlight_5a_75e_v6_0
fsoc --clean
fsoc --build
```

One routed nextpnr fit of that blinky (2026-09-26, `LFE5U-25F`, `--25k`) met the 25.00 MHz constraint at 289.35 MHz. The bitstream `blinky.bit` is 582369 bytes. Block RAM is unused.

| Resource | Used | On LFE5U-25F |
|----------|------|----------------|
| LUT4 | 27 (1 logic, 26 carry) | 24288 (0%) |
| DFF | 26 | 24288 (0%) |
| RAM LUT | 0 | 3036 |
| RAMW LUT | 0 | 6072 |
| DP16KD | 0 | 56 |
| TRELLIS_IO | 2 | 197 |
| MULT18X18D | 0 | 28 |

## Minimal SoC

`projects/soc_emul` is a builder task. `fsoc --build` cross-compiles SwapForth J1a, loads `firmware.hex` into the vendored J1 core, and runs Verilator until Ctrl+C. The manifest field `cpu:` selects the Forth profile. Task `soc` with no `cpu:` is `j1a`. The image is that system's ANS CORE dictionary without `environment?`. On a terminal the session is an ncurses screen: UART text scrolls above, and the bottom row is the host line. Characters, including non-ASCII, appear there as they are typed; Enter sends that line. The reply ends with ` ok`. `FSOC_EMU_CON=log` prints each UART byte as `t=<ns> uart tx <byte>`. `FSOC_EMU_CON=term` forces the text view. A redirected run stays on the byte log unless `term` is set. The io map is written as `csr.fs` (SwapForth constants `IO-LED` …), `iomap.vh` (wrapper `localparam`s), and `csr.json` (`bus` `j1-io`).

```bash
cd projects/soc_emul
fsoc --build
```

`projects/soc_emul_colorlight_5a_75e_v6_0` is that same console with the Colorlight 5A-75E v6.0 clock, 25 MHz. UART stays in the simulator: the board has no serial pins, and this top keeps `uart_rx`, `uart_tx`, `rst`, and `dump`. `sim.sh` uses `CLK_HZ=25000000`, the same value as `top.v`, so the bit time matches. A line `1 2 + .` still answers `3 ok`.

```bash
cd projects/soc_emul_colorlight_5a_75e_v6_0
FSOC_EMU_FAST=1 FSOC_EMU_UART_IN='1 2 + .' fsoc --build
```

`projects/soc_blink` is the same core with a `'BOOT` word that does not return to the prompt. The loop writes `0` and `1` to `IO-LED`. That bit leaves `top` as `led`. The pause is a read of `IO-TIMER`. The loop also sends `lamp on` and `lamp off` on the UART. A background task and an interrupt controller are a later step, described in [doc/stm8ef-hw.md](doc/stm8ef-hw.md).

With `s" fsys" sys:` the dictionary can be cut down. `s" image" s" release" option:` next to `s" lamp" s" 1" option:` keeps the lamp and the compiler roots in `fsys/<cpu>/release.4th`. Omit `image`, or set it to `debug`, and the full layers stay. Measured on this project: j1a release `firmware.hex: 2822 bytes of 8192`, debug `7752 bytes of 8192`; j1b release `2956 bytes of 32768`, debug `9156 bytes of 32768`. The empty soc row and these four pairs are in [doc/j1-word-graph/soc-sizes.md](doc/j1-word-graph/soc-sizes.md). Regenerate that file with `python3 doc/j1-word-graph/build.py sizes`.

`FSOC_EMU_CON` picks the view. `term` writes the UART bytes, so the lamp phrases show as text. `log` prints each UART byte as `t=<ns> uart tx <byte>`. `pin` prints only `t=<ns> pin led 0` and `t=<ns> pin led 1` and does not write the UART bytes. A run without a scripted UART line ends at Ctrl+C or `FSOC_EMU_CYCLES`. Tests use `FSOC_EMU_CYCLES=800000` with `FSOC_EMU_FAST=1`.

```bash
cd projects/soc_blink
FSOC_EMU_CON=term FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=800000 fsoc --build
FSOC_EMU_CON=pin FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=800000 fsoc --build
```

## Data SPI NOR

An extra SPI NOR is a data part, not a boot ROM. The J1 reset stays at the first word of internal RAM, and `firmware.hex` is still that image. The part is not named `rom`. A command on the io bus reads a contiguous range into an internal buffer; it is not a memory-map window. Chip rows live in `fsoc/soc/nor.4th`. `w25q32jv` is device id `$7016`, 4194304 bytes, page 256, opcode `$03`, and no dummy clocks. `w25q64jv` is the same 1-1-1 read with a different size. Both rows use one leaf, [`rtl/spi_nor.v`](rtl/spi_nor.v). `spi_clk` is a port of that module. A memory-map window of the flash, and a `main_ram` region with a base, a size, and a bus, are later slices and are not in this build. The command read is checked under Verilator and does not need a board. `csr.json` carries `regions` next to `devices`; with no region call, `regions` is `[]` and `led` stays at `$400`.

## SoC on a board

`projects/soc_terasic_de0nano` writes Quartus files and `firmware.hex` for the SwapForth console on the Terasic DE0-Nano (`EP4CE22F17C6`). Clock `clk50` is `R8`, `user_led` 0 is `A15`, serial tx/rx are `B5`/`B4`. `led` is the `IO-LED` register: in hex, `1 400 io!` drives `A15` high and `0 400 io!` drives it low. `--build` does not run Quartus. `--load` runs `load.sh`. Then a host line on the USB UART.

Quartus II 11.1 Build 173, full compile 2026-09-27 02:10:30, timing final. Five map warnings remain (`$writememh` ignored, four truncated integer literals). Fitter, assembler, and TimeQuest reported none. Notes on those warnings and on the errors closed before this fit: [doc/quartus-ii-11.md](doc/quartus-ii-11.md).

| Resource | Used | Available |
| --- | ---: | ---: |
| Logic elements | 1001 (4%) | 22320 |
| Combinational functions | 1000 (4%) | 22320 |
| Dedicated logic registers | 625 (3%) | 22320 |
| Pins | 4 (3%) | 154 |
| Memory bits | 65536 (11%) | 608256 |
| Embedded 9-bit multipliers | 0 | 132 |
| PLLs | 0 | 4 |

Memory is the 4096×16 firmware RAM. Setup slack 9.752 ns (slow 85°C), hold slack 0.317 ns. The on-board check of `1 400 io!` is still open; the next build after that is Xilinx (`openspec/changes/xilinx-soc`).

```bash
cd projects/soc_terasic_de0nano
fsoc --build --load
gforth tools/fterm.4th /dev/ttyUSB0
```

`fterm` without a path still answers `ok` from memory.

`projects/soc_blink_colorlight_5a_75e_v6_0` is the lamp image on the Colorlight 5A-75E v6.0 (`LFE5U-25F-6BG256C`, CABGA256, speed 6, nextpnr `--25k`). The clock is `clk25` on `P6`, 25 MHz, LVCMOS33. `T6` is the user LED and `R7` is the button, so this board has no UART pins. The board `top` ties `uart_rx` to `1'b1`, leaves `uart_tx` on an unused wire, and ties `rst` and `dump` to `1'b0`. The LED is active-low: a stored `1` drives `T6` low (`assign led = ~led_q`). The timer counts milliseconds (`TIMER_DIV = 25000`, which is `CLK_HZ/1000`). While `DIV` is greater than 1 it holds `0` until the next write, so the Forth poll can see the zero. The lamp period in `firmware/lamp.fs` is 500 counts, about half a second. `BAUD` on the wrapper stays 115200. The SwapForth feed that writes `firmware.hex` still runs at 50 MHz, the same bit time as emulation; the board `top.v` is written again at 25 MHz. `--build` writes `soc.lpf` and runs Yosys with `read_verilog -DSYNTHESIS`, so `$writememh` in the wrapper is not part of synthesis. `FSOC_SYNTH_SKIP` writes the files and skips the tools. `load.sh` needs a `cable` option; this manifest does not set one.

One routed nextpnr fit of that image (2026-09-26) met the 25.00 MHz constraint at 71.55 MHz. The bitstream `soc.bit` is 591641 bytes. The critical path starts at a block-RAM data pin, `u.ram.0.3.DOB`.

| Resource | Used | On LFE5U-25F |
|----------|------|----------------|
| LUT4 | 1135 (1017 logic, 118 carry) | 24288 (4%) |
| DFF | 697 | 24288 (2%) |
| RAM LUT | 0 | 3036 |
| RAMW LUT | 0 | 6072 |
| DP16KD | 4 | 56 (7%) |
| TRELLIS_IO | 2 | 197 |
| MULT18X18D | 0 | 28 |

The four `DP16KD` blocks are the J1 firmware array, `4096 × 16` (8 KB, 64 Kbit of data). Each block is 18 Kbit, so those four reserve 72 Kbit out of the 1008 Kbit block-RAM budget. Distributed LUT RAM is unused. The same lamp on j1a and j1b, full and release, is in [doc/j1-word-graph/soc-fit.md](doc/j1-word-graph/soc-fit.md). Regenerate that file with `python3 doc/j1-word-graph/build.py fit`. That command is not part of `fsoc --build`.

```bash
cd projects/soc_blink_colorlight_5a_75e_v6_0
fsoc --build
```

`tools/fterm.4th` and `firmware/midi_foot.4th`: `fterm` talks to a real port when given a path; `midi_foot` is a host mock of FOOTSWITCH-SCAN.

## Boards

| Board | Device | Notes | serial |
|-------|--------|--------|--------|
| `ep2c5_mini` | EP2C5T144C8 | Quartus II 13.0sp1 | — |
| `terasic_de0nano` | EP4CE22F17C6 | Terasic DE0-Nano, litex-boards; clk `R8`, led `A15` | tx `B5` / rx `B4` |
| `colorlight_5a_75e_v6_0` | LFE5U-25F-6BG256C | clk `P6` 25 MHz, led `T6` active-low, btn `R7` | — |
| `colorlight_5a_75e_v7_1` | LFE5U-25F-6BG256C | clk `P6` 25 MHz, led `P11` active-low, btn `M13` | — |
| `colorlight_5a_75e_v8_2` | LFE5U-25F-7BG256I | clk `P6` 25 MHz, led `T6` active-low, speed 7 | — |

## Related

- [MIT ADR-0003](https://github.com/VitaSound/MIT) — Forth-native SoC builder
- [feco](https://github.com/VitaSound/feco) — ecosystem catalog
- [fhdlgen](https://github.com/VitaSound/fhdlgen) >= 0.5 — Verilog generator (`fhdlgen build <design> --out <dir>`)
