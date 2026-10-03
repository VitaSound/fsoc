# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.9.0-green.svg)](https://github.com/VitaSound/fsoc)

English copy. Русская версия: [README.md](README.md).

Forth-native SoC builder: **boards**, **Quartus/Yosys/Verilator toolchains**, **iomap**, **J1 firmware**. Analogue of LiteX `build` + `soc` on Gforth. Verilog modules come from [fhdlgen](https://github.com/VitaSound/fhdlgen) and [hdl-modules](https://github.com/VitaSound/hdl-modules). Russian release note: [doc/PRESS-RELEASE-ru.md](doc/PRESS-RELEASE-ru.md).

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

`fmix test` includes the shared fsys console grid [`tests/con_core_test.4th`](tests/con_core_test.4th) (j1a, j1b, avr, bcpu: input, erase, unknown word, stack, `+`, `.s`, `:`, `words`). Oracle: [`tests/con_words.py`](tests/con_words.py) against `doc/j1-word-graph/fsys-*.json`. One file:

```bash
export FSOC_HOME="$HOME/fsoc"
cd tests && gforth con_core_test.4th
```

ATmega8 UART under simavr is optional for a clone. Packages: `simavr`, `libsimavr-dev`, `gcc`. Without them the AVR slice of `con_core_test` and [`tests/avr_con_test.4th`](tests/avr_con_test.4th) skip. From a built project: `~/fsoc/tools/avr-con ./firmware.hex`. See [ATmega8](#atmega8). A new `cpu:` with an fsys kernel must extend this grid — [Adding a CPU](#adding-a-cpu) and `.cursor/rules/fsoc-cpu-target.mdc`.

## Blinky

Blinky is one task. The leaf is [`rtl/blinky.v`](rtl/blinky.v) (`clk` / `led`, `LED_BIT` defaults to 25). [`designs/blinky_top.4th`](designs/blinky_top.4th) includes that file and instantiates it as `top`. Working solutions live under [`projects/`](projects/). **Git tracks only `target.4th` in each directory.** `fsoc --build` emits the rest (`top.v`, leaf copies, `firmware.hex`, `sim.sh` / `.qsf`, `obj_dir`, …) into that directory; `.gitignore` keeps those files out. After a clone, `projects/soc_blink/` is the manifest alone.

Debug the task and the design in an `emulation` project (`blinky_emul`, `soc_emul`, `soc_blink`). A board project is the same task and design with `quartus` and `board:` — not a second HDL tree.

```text
projects/baremetal/blinky_emul/                  Verilator realtime, LED_BIT=25, console pin events
projects/baremetal/blinky_terasic_de0nano/       Quartus .qsf, Terasic DE0-Nano
projects/baremetal/blinky_colorlight_5a_75e_v6_0/  Yosys .lpf, nextpnr-ecp5, ecppack
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
cd projects/baremetal/blinky_emul
fsoc --build
```

`FSOC_EMU_TRACE=1` on that `--build` compiles the viewer with Verilator `--trace` and writes `trace.vcd` (4096 cycles, or `FSOC_EMU_CYCLES` when that limit is longer). The run then continues until its usual stop. From the project directory, `"$FSOC_HOME/tools/peek.sh" info` sends that file to WavePeek. Install the binary as in [Install](#install).

Quartus (`--build` writes the project files and does not run Quartus; the task maps `clk50`→`clk` and `user_led`→`led`). Open `<project>.qpf` in Quartus II 11 (`QUARTUS_VERSION` 11.0, revision name equal to the `.qsf`). `FAMILY` is quoted. Each name in `includes.lst` is a `VERILOG_FILE`, and those `` `include `` lines are removed from the top. A board `LVTTL` pin is `IO_STANDARD "3.3-V LVTTL"`. An output also gets `CURRENT_STRENGTH_NEW 8MA` and `SLEW_RATE 2`. `blinky.sdc` is listed as `SDC_FILE` and ends with `derive_clock_uncertainty`. Warning 169177, the AN 447 reminder on a 3.3-V LVTTL input, is suppressed. `--load` programs the board. On emulation `--load` does nothing.

```bash
cd projects/baremetal/blinky_terasic_de0nano
fsoc --build
fsoc --build --load
```

Yosys (`--build` writes the LPF and the scripts, then runs `sh build.sh`). The clock and the LED come from the board (`clk25` on the Colorlight 5A-75E). `yosys` and `nextpnr-ecp5` are taken from `PATH`. If they are not there and `~/oss-cad-suite` is installed, the tool run sources that suite's `environment` itself. `load.sh` calls `openFPGALoader` only when the manifest has `s" cable" s" <name>" option:`. `FSOC_SYNTH_SKIP` skips the tool run and still writes the files. The board database also has revisions 7.1 and 8.2; the working project is 6.0.

```bash
cd projects/baremetal/blinky_colorlight_5a_75e_v6_0
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

## ATmega8

`projects/soc_atmega8` is a Forth console (`s" fsys" sys:`): kernel plus `fsys/avr/extra-min.4th` (`cr`, `type`, arithmetic helpers), no ports, Intel HEX. `projects/soc_atmega8_blink` packs a **release** image: `s" image" s" release" option:` plus `firmware/blink.fs` (PB0 and USART text) on `fsys/avr/extra.4th`, not extra-min. `projects/baremetal/blinky_atmega` is the same **task** `blinky` as the FPGA copies, with `s" avr" cpu:`: fasm assembles `firmware/blink_avr.4th` (PB0), no kernel. The log prints `Hardware` / `atmega8(avr)` then `Software` / `image tool: fsys` or `fasm` / `firmware.hex: <used> bytes of 8192`. `fsoc --build` does not start Proteus. Clock, LED, and Virtual Terminal are in [doc/atmega8-proteus.md](doc/atmega8-proteus.md).

Proteus with the release HEX: USART at 9600 on `PD1`/`PD0` prints `blink on` / `blink off` in the Virtual Terminal. The same text appears under `tools/avr-con`.

![ATmega8 Forth blink in Proteus: Virtual Terminal prints blink on / blink off](doc/atmega8-proteus-blink.png)

```bash
cd projects/soc_atmega8 && fsoc --build
cd projects/soc_atmega8_blink && fsoc --build
cd projects/baremetal/blinky_atmega && fsoc --build
```

On Linux, before Proteus, the UART console is [`tools/avr-con`](tools/avr-con) (simavr). The stock `simavr` CLI does not feed the keyboard to USART, so after `ok` the image waits on `KEY` with no input. Install the packages, then run the wrapper from the project directory that holds `firmware.hex`. First launch compiles `tools/avr-con.bin` with `gcc`.

```bash
sudo apt install simavr libsimavr-dev gcc
cd projects/soc_atmega8 && fsoc --build
~/fsoc/tools/avr-con ./firmware.hex
```

Type a Forth line and press Enter (sent as CR). Ctrl-D exits. Extra arguments are one-shot lines:

```bash
~/fsoc/tools/avr-con ./firmware.hex words
~/fsoc/tools/avr-con ./firmware.hex '1 2 + .'
```

`simavr` provides `libsimavr.so.2`; `libsimavr-dev` is the headers (`/usr/include/simavr`). Without the -dev package the wrapper looks for headers in `/tmp/simavr-dev/usr/include/simavr`. The same schematic notes and GDB (`simavr -g`) are in [doc/atmega8-proteus.md](doc/atmega8-proteus.md).

## bcpu

`bcpu` is a 16-bit accumulator (class 0, FMAP `U-M-B-A-3-F`, MM=U, EX-C=B, CG=F). The instruction set follows [howerj/bit-serial](https://github.com/howerj/bit-serial) (MIT). `cpu/bcpu/bcpu.v` is a parallel ALU, not a copy of `bit.vhd`. Empty `sys:` stops. `s" fsys" sys:` assembles `fsys/kernel/bcpu` and the host cross compiles `fsys/bcpu/extra-min.4th` into a word-hex image. `cpu/bcpu/bit.hex` stays in the tree as the original eForth attribution image; the soc build does not load it. The console is a row in `tests/con_core_test.4th`.

`projects/baremetal/blinky_bcpu` is task `blinky`: fasm assembles `firmware/blink_bcpu.4th` and the log shows `pin led` `0` and `1`. `projects/soc_bcpu` is the fsys console: `1 2 + .` prints `3` and ` ok`. `projects/soc_bcpu_blink` compiles `firmware/bcpu_blink.fs` onto that kernel. The pin log shows `0` and `1`, and the console prints `blink on` and `blink off`. `projects/soc_bcpu_colorlight` is the console image on the Colorlight 5A-75E v6.0. The board has no UART pins: `btn` (`R7`) is the receive line, and transmit is folded into the active-low LED (`leds[0] ^ uart_tx`, idle TX high).

One routed nextpnr fit (2026-10-01, `LFE5U-25F`, `--25k`) met the 25.00 MHz constraint at 54.48 MHz. The bitstream `bcpu.bit` is 600913 bytes. The critical path starts at a block-RAM data pin, `cpu.mem.0.0.DOB1`.

| Resource | Used | On LFE5U-25F |
|----------|------|----------------|
| LUT4 | 694 (604 logic, 90 carry) | 24288 (2%) |
| DFF | 272 | 24288 (1%) |
| RAM LUT | 0 | 3036 |
| DP16KD | 8 | 56 (14%) |
| TRELLIS_IO | 3 | 197 |

The eight `DP16KD` blocks are the 8192×16 memory (128 Kbit of data). Each block is 18 Kbit, so those eight reserve 144 Kbit. The count includes the CPU, that memory, and `cpu/j1/uart.v`.

```bash
cd projects/baremetal/blinky_bcpu && fsoc --build
cd projects/soc_bcpu && fsoc --build
cd projects/soc_bcpu_blink && fsoc --build
cd projects/soc_bcpu_colorlight && fsoc --build
```

## j1abs

`j1abs` (A Bit Serial) keeps the J1a instruction set and runs it one bit per clock (class 0, FMAP `V-V-A-0-I`, MM=V, EX-C=V, CG=I). `alu_rom` and `ctrl_rom` are synchronous `512×32` tables, and the stack bodies sit in one block RAM. The image port is `j1a`, so SwapForth and `fsys/kernel/j1a` are unchanged. There is no `con_core` row. `projects/baremetal/blinky_j1abs` is task `blinky`. `projects/soc_j1abs` is the fsys console (`1 2 + .` prints `3` and ` ok`). `projects/soc_j1abs_blink` is the lamp loop. `projects/soc_j1abs_colorlight` is that fsys image on the Colorlight 5A-75E v6.0 (`LFE5U-25F`, 25 MHz, Yosys). The board has no UART pins, so the top ties `uart_rx` to `1'b1`, leaves `uart_tx` off the port list, and drives the active-low LED on `T6`.

```bash
cd projects/baremetal/blinky_j1abs && fsoc --build
cd projects/soc_j1abs && fsoc --build
cd projects/soc_j1abs_blink && fsoc --build
cd projects/soc_j1abs_colorlight && fsoc --build
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

`projects/soc_blink_colorlight_5a_75e_v6_0` is the lamp image on the Colorlight 5A-75E v6.0 (`LFE5U-25F-6BG256C`, CABGA256, speed 6, nextpnr `--25k`). The clock is `clk25` on `P6`, 25 MHz, LVCMOS33. `T6` is the user LED and `R7` is the button, so this board has no UART pins. The board `top` ties `uart_rx` to `1'b1`, leaves `uart_tx` on an unused wire, and ties `rst` and `dump` to `1'b0`. The LED is active-low: a stored `1` drives `T6` low (`assign led = ~led_q`). The timer counts milliseconds (`TIMER_DIV = 25000`, which is `CLK_HZ/1000`). At zero the count stays there until the next write, so the Forth poll can see it. The lamp period in `firmware/lamp.fs` is 500 counts, about half a second. `BAUD` on the wrapper stays 115200. The SwapForth feed that writes `firmware.hex` still runs at 50 MHz, the same bit time as emulation; the board `top.v` is written again at 25 MHz. `--build` writes `soc.lpf` and runs Yosys with `read_verilog -DSYNTHESIS`, so `$writememh` in the wrapper is not part of synthesis. `FSOC_SYNTH_SKIP` writes the files and skips the tools. `load.sh` needs a `cable` option; this manifest does not set one.

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

The standalone fits below are the core alone on board `lfe5u25f_cabga256` (`LFE5U-25F-6BG256C`). The constraint is 25.00 MHz. Fmax is the routed clock. `TRELLIS_IO` is the pin count of that top. The last row is the part, not a core.

| Core | LUT4 | DFF | DP16KD | TRELLIS_IO | Fmax |
|------|------|-----|--------|------------|------|
| j1a | 1484 (1436 logic, 48 carry) | 578 | 0 | 82 | 123.24 MHz |
| j1abs | 277 (239 logic, 38 carry) | 170 | 3 | 82 | 84.08 MHz |
| j1b | 3920 (3836 logic, 84 carry) | 2164 | 0 | 146 | 93.71 MHz |
| mcpu | 45 (29 logic, 16 carry) | 24 | 0 | 18 | 245.22 MHz |
| cd16 | 734 (660 logic, 74 carry) | 95 | 1 | 115 | 62.13 MHz on `clk50`, 97.30 MHz on `clk25` |
| msl16 | 558 (470 logic, 40 carry, 32 RAM, 16 RAMW) | 54 | 0 | 43 | 84.98 MHz |
| LFE5U-25F | 24288 | 24288 | 56 | 197 | 25.00 MHz |

`projects/standalone_j1a`, `projects/standalone_j1abs`, and `projects/standalone_j1b` are the core and its stacks alone. That file is the CABGA256 ball map: `clk` on `P6` at 25 MHz, then plain PIO, then PCLK balls. Task `standalone` ties every port of module `j1` to a pin of `top`. `j1b` is the 32-bit core, so `dout`, `io_din`, and `mem_din` are 32 bits. One routed nextpnr fit (2026-10-01) met 25.00 MHz. The same Fmax line is what `doc/j1-word-graph/build.py` keeps for the lamp.

The three `DP16KD` blocks on j1abs are the ALU table, the control table, and the stack RAM. j1a and j1b keep their stacks in flip-flops, so those two rows have no block RAM.

```bash
cd projects/standalone_j1a
fsoc --build
```

`projects/standalone_mcpu` is an experimental micro-core: [MCPU](https://github.com/cpldcpu/MCPU) (GPL-2). Notes: [doc/mcpu.md](doc/mcpu.md). It is not a Forth profile. There is no row in `fsoc/cpu.4th`, no console, and no soc image. The host assembler is `fsys/fasm/mcpu`: 64 bytes, `nor,` `add,` `sta,` `jcc,` `dcb,`. Task `standalone` ties `clk`, `rst`, `oe`, `we`, `adress[5:0]`, and `data[7:0]` to pins of `top` on the same package board. One routed nextpnr fit (2026-10-02) met 25.00 MHz. `oe` and `we` still depend on `clk` in the vendored equations; nextpnr promoted that pin onto a global net and finished.

```bash
cd projects/standalone_mcpu
fsoc --build
```

`projects/standalone_cd16` is the CD16 core from Brad Eckert's VHDL, kept for the ECP5 size. The Forth profile is `cd16`: `s" fsys" sys:` builds the console, and the projects are `baremetal/blinky_cd16`, `soc_cd16`, and `soc_cd16_blink`. Notes: [doc/cd16.md](doc/cd16.md). The host assembler is `fsys/fasm/cd16` (`cd16-wl`, 65536 words). The stack is one `DP16KD` on a 50 MHz clock; program and data buses are pins. One routed nextpnr fit (2026-10-03) met 25.00 MHz on the pin. The core alone, `synth_ecp5` with every port kept, is 736 LUT4, 37 `CCU2C`, and 94 flip-flops.

```bash
cd projects/standalone_cd16
fsoc --build
```

`projects/standalone_msl16` is the MSL16 core from Philip Leong's 1998 VHDL. Notes: [doc/msl16.md](doc/msl16.md). The Forth profile is `msl16`: `s" fsys" sys:` builds the console (word hex, 2048 words, `ADDR=11`), and the projects are `baremetal/blinky_msl16`, `soc_msl16`, and `soc_msl16_blink`. The host assembler is `fsys/fasm/msl16` (four slots, `msl16-wl`). The standalone fit still uses the 8-bit bus. The two 16×16 stacks are LUT RAM (`DPR16X4`). One routed nextpnr fit (2026-10-03, `ADDR=8`) met 25.00 MHz.

```bash
cd projects/standalone_msl16
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
| `lfe5u25f_cabga256` | LFE5U-25F-6BG256C | package ball map, clk `P6` 25 MHz, then PIO, then PCLK | — |

## Adding a CPU

A new **ISA** is a new `cpu:` id (`fsoc/cpu.4th`, FMAP + CG) with the fsys layers: `fsys/fasm/<id>/` → `fsys/kernel/<id>/` (Forth console) → `fsys/host/<id>-cross.4th` → `fsys/<id>/extra.4th`. A new **chip** of an existing ISA is only a part file under fasm. `bcpu` has those layers, and its console is a row in `tests/con_core_test.4th`. Agent rule: [`.cursor/rules/fsoc-cpu-target.mdc`](.cursor/rules/fsoc-cpu-target.mdc). Skill: `add-cpu-target`. Specs: [`openspec/specs/forth-cross/spec.md`](openspec/specs/forth-cross/spec.md), [`openspec/specs/fsys/spec.md`](openspec/specs/fsys/spec.md).

If the id has an fsys console kernel, extend the shared grid in the same change:

1. BS/DEL in that kernel `accept` (bytes 8 and 127, `BS SPACE BS`, ignore on an empty line).
2. Manifest in [`tests/con_session.4th`](tests/con_session.4th) and a row in [`tests/con_core_test.4th`](tests/con_core_test.4th).
3. Dictionary JSON via [`doc/j1-word-graph/build.py`](doc/j1-word-graph/build.py).
4. Every JSON name tagged in [`tests/con_words.py`](tests/con_words.py) (`run` / `colon` / `skip` with a reason).
5. Id-only words in a separate `*_test.4th` — do not copy the shared REPL. A chip part does not add a `con_core` row.

```bash
export FSOC_HOME="$HOME/fsoc"
cd tests && gforth con_core_test.4th
fmix test
```

## Related

- [MIT ADR-0003](https://github.com/VitaSound/MIT) — Forth-native SoC builder
- [feco](https://github.com/VitaSound/feco) — ecosystem catalog
- [fhdlgen](https://github.com/VitaSound/fhdlgen) >= 0.5 — Verilog generator (`fhdlgen build <design> --out <dir>`)
