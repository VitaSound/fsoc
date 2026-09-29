# Changelog

## [0.9.0] - 2026-09-29

### Changed

- j1b firmware RAM reads on the clock, so Yosys maps the 8192×32 array to 16 ECP5 `DP16KD` blocks instead of LUT RAM. The instruction word is latched whole and the half is chosen after that register. `@` waits one cycle for `mem_din`. Colorlight nextpnr fit: j1b 3653/24288 LUT4, 0/3036 RAM LUT, 16/56 `DP16KD`, 67.13 MHz. j1a stays 4 `DP16KD`. The numbers are in `doc/j1-word-graph/soc-fit.md`.

- The interval timer stays at 0 until the next write. It no longer reloads the period on the following clock, so the lamp poll sees the zero on j1b as well as on j1a.

### Added

- `tests/avr_con_test.4th`: extra-min UART under `tools/avr-con` (simavr). Covers `1 2 + .`, two-digit `.`, `.s` on the next line after `1 2 3`, and `words`. Skips when `simavr` / `libsimavr-dev` are missing.

- HDL `blinky_*` projects live under `projects/baremetal/`. `projects/baremetal/blinky_atmega` is task `blinky` with `s" avr" cpu:`: fasm assembles `firmware/blink_avr.4th` (PB0), no Forth kernel. AVR `--build` prints `Hardware` / `atmega8(avr)` then `Software` / `image tool: fasm` / `firmware.hex: <used> bytes of 8192`.

- How to add another CPU/MCU: always-on rule `.cursor/rules/fsoc-cpu-target.mdc`, skill `add-cpu-target`, and OpenSpec requirements in `forth-cross` / `fsys`. A new `cpu:` id is an ISA family (fasm, kernel console, host cross, extra, firmware). A new chip of the same ISA is a part file under `fsys/fasm/<id>/`. `soc.4th` still names no MCU id; the CG emitter branches.

- ATmega8 profile `avr` (class 1, MM=D, EX-C=S, CG=F, BM=C). Empty `sys:` stops; `s" fsys" sys:` assembles the STC console kernel, host `avr-cross` compiles `fsys/avr/extra-min.4th` (console) or `fsys/avr/extra.4th` (blink), and writes Intel HEX. `s" blink" s" 1" option:` with `s" image" s" release" option:` appends `firmware/blink.fs` (PB0 and USART text), not `fsys/kernel/avr`. `avra` is not called. `z80` still stops before a hex image. Target `proteus` does not launch a simulator. `projects/soc_atmega8` is the extra-min console; `projects/soc_atmega8_blink` is a release blink image. The AVR assembler covers the classic opcode set. `atmega8`, `atmega328p`, and `atmega2560` each carry their own flash, SRAM, EEPROM, vector length, and register addresses. The Proteus schematic is in `doc/atmega8-proteus.md`.

### Fixed

- AVR console hung in Proteus after `ok`: `okmsg` and `wordsw` called Forth `emit` (which pops TOS) as if it were putchar, and `accept` stored TOS instead of the UART byte. A `tx` primitive writes UDR without touching the stack. CR and LF both end a line (VT100 Enter is CR). After extra-min the reset `seed` is patched so `cr` / `type` are in the target dictionary.

### Added

- Colorlight lamp fit table. `python3 doc/j1-word-graph/build.py fit` runs nextpnr for j1a and j1b, full and release, and rewrites `doc/j1-word-graph/soc-fit.md`. The command is not part of `fsoc --build`.

- fsys release image for a named program. `s" fsys" sys:` and `s" image" s" release" option:` next to an application option such as `lamp` load the program's word closure plus `fsys/<cpu>/release.4th`, not the whole dictionary layers. On `projects/soc_blink`, j1a release is `firmware.hex: 2822 bytes of 8192` and debug is `7752 bytes of 8192`. j1b release is `2956 bytes of 32768` and debug is `9156 bytes of 32768`. The lamp still runs; the console compiler stays in the image.

- j1b host compiler packs colon bodies two instructions per 32-bit cell. `constant`, `create`, and `variable` keep the literal and `exit` in separate cells and the data at `cfa + 2 cells`, so console `lit!` and `does>` still write a whole cell. `here` at byte 16384 stops the build (`call out of range`). A call of a literal word followed by `@` becomes a literal and `[T]`; `dup @`, `2dup rshift`, and `2dup lshift` fuse on j1b only. `!` stays a call. j1a hex is unchanged (shared 7550, extra-min 8008). j1b shared 8280 of 32768, with extra 8934 (was 11636 and 12692).

- Host fsys dictionary: Gforth on the build machine compiles `fsys/common` (and j1b `extra.4th`, optional j1a `extra-min.4th`) into the kernel image with call shortcut, j1a `@i`, and ALU pairs. The target only runs `firmware.hex`; this path does not use `Vtop_feed`. Console `;` stays call→jump. j1a shared layer 7550 of 8192; with `s" extra-min" s" 1" option:` 8008 (below TIB 8066). j1b shared 11636, with extra 12692 of 32768. Lamp on j1a is 7754. SwapForth j1a full image remains 5006 of 8192 (nuc alone historically 3404).

- j1a console extras in `fsys/j1a/extra-min.4th` (16-bit cell), loaded only when `extra-min=1`: `nib`, `.x`, `.x2`, `nbytes`, `dump`, `ms`, `leds`, `convert`, `2rot`, `tneg`, `t*`, `t/`, `m*/`, `throw`, `new` with `floor`/`flink`. Not j1b `extra.4th` and not halfword words. `package.4th` lists `key-list flint-exclude fsys/j1a/extra-min.4th` so flint does not treat those names as duplicates of j1b's extra.

### Changed

- j1b fsys dictionary ends at `fsys/j1b/extra.4th`. Empty `sys:` remains `swapforth`.

### Added

- `cpu-compare` reports one task and one scenario for a list of `cpu:` profiles: MM, EX-C, CG, cell width, image bytes, and Verilator cycles. The cycle winner is only among rows that share MM, EX-C, and CG and have a filled cycle count. A smaller image at a different cell width is not ranked. Rows from different synthesis toolchains are not marked as a core comparison. A profile with no image leaves the cycle cell empty. The report does not run Yosys, nextpnr, or Quartus.

- Command SPI NOR read into an internal buffer. The part is not a boot ROM: `firmware.hex` and the J1 reset stay in internal RAM, and the names `rom` and `main_ram` are refused. Chip rows `w25q32jv` and `w25q64jv` share `rtl/spi_nor.v` (opcode, dummy clocks, address width). `csr.json` carries a `regions` array beside `devices`. A memory-map window and `main_ram` are not in this slice.

- Host assembler `fsys/fasm` for j1a and j1b. Comma words emit one J1 instruction. `[asm]` … `[endasm]` writes `$readmemh` lines and does not start a UART feed. j1b packs two instructions into each output word.

- The Software section names the image tool on its own line (`image tool: SwapForth` or `image tool: fsys`). Both tools then print the same size line, `firmware.hex: <used> bytes of <ram>`.

- Manifest field `sys:` names the image tool. Empty is `swapforth`, so current `target.4th` files stay on that console. The tool lives in `swapforth/<cpu>/` (`j1a/`, `j1b/`, `common/`), not under `cpu/j1/`. An unknown id stops before `gforth`. `s" fsys" sys:` assembles `fsys/kernel` for j1a or j1b, then that kernel compiles `fsys/common/common.4th` and `fsys/common/core.4th`. `words` lists the dictionary, `1 2 + .` prints `3` and ` ok`, `variable x  5 x !  x @ .` prints `5`, and `10 3 / .` prints `3`. `firmware/lamp.fs` is appended only when `s" lamp" s" 1" option:` is set. Core kits no longer name a cross directory.

- fsys dictionary names are packed bytes on j1a and j1b. Two link bytes carry the immediate flag in the low bit, then a length byte and the letters, then alignment to the cell, then the code. `here` stays the only pointer. After the shared layer the image is 5108 bytes of 8192 on j1a and 7300 of 32768 on j1b.

- Shared fsys words for both cell widths: `j`, `char+`, `chars`, `align`, `>body`, `within`, `erase`, `move`, `/string`, `2>r`, `2r>`, `2r@`, `pick`, `roll`, `s>d`, `d0=`, `d0<`, `dabs`, `d=`, `d<`, `du<`, `d-`, `d2/`, `d>s`, `dmax`, `dmin`. After them the image is 5668 bytes of 8192 on j1a and 8264 of 32768 on j1b.

- Shared fsys words `leave`, `?do`, `parse`, `>number`, `d.`, and `d.r`. `leave` jumps past the current loop, including a loop inside another loop. `d.` and `d.r` take digits by a bit walk, so a wide cell does not subtract its way through the quotient. After them the image is 6420 bytes of 8192 on j1a and 9664 of 32768 on j1b. On j1a the terminal buffer and the `here` cell sit higher in RAM, so the dictionary can grow past the old buffer.

- Shared fsys words `fm/mod`, `source`, `sliteral`, and `abort"`. `fm/mod` keeps the remainder with the sign of the divisor. `source` is the input line, one byte per character. `abort` clears both stacks and returns to the outer text loop. After them the image is 6628 bytes of 8192 on j1a and 10016 of 32768 on j1b.

- Shared fsys words `]`, `[`, `.(`, and `[compile]`, plus kernel `exit` and `unloop`. `[` returns to interpretation and `]` to compilation. `exit` leaves the current word. `unloop` drops the loop index and limit. After them the image is 6750 bytes of 8192 on j1a and 10204 of 32768 on j1b.

- Shared fsys words `evaluate` and `word`, plus kernel `quit`, `accept`, and the input base `src`. `quit` clears the return stack and leaves the data stack. `accept` reads the line. `evaluate` interprets a string. `word` returns a counted string. After them the image is 7054 bytes of 8192 on j1a and 10712 of 32768 on j1b.

- Shared fsys words `:noname`, `value`, `to`, `buffer:`, and `source-id`. `:noname` leaves the token of a nameless colon word. `to` replaces a value. `buffer:` names a byte buffer. `source-id` is 0 at the console and -1 while `evaluate` runs. After them the image is 7172 bytes of 8192 on j1a and 10904 of 32768 on j1b.

- Shared fsys words `defer`, `defer!`, `defer@`, `is`, and `action-of`. A defer starts as `abort`. `is` and `defer!` replace the action. `defer@` and `action-of` fetch it. After them the image is 7302 bytes of 8192 on j1a and 11124 of 32768 on j1b.

- Shared fsys words `case`, `of`, `endof`, `endcase`, `holds`, `pad`, and `unused`. `case` runs the arm whose value equals the selector and leaves the selector when none does. `holds` prepends a string to the pictured output. `pad` is a transient buffer above `here`. `unused` is the bytes left below the terminal buffer. After them the image is 7432 bytes of 8192 on j1a and 11336 of 32768 on j1b.

- Shared fsys words `c"`, `s\"`, `refill`, `save-input`, and `restore-input`. `c"` compiles a counted string. `s\"` reads the escape letters. `refill` reads the next console line and returns false while `evaluate` is running. `save-input` and `restore-input` keep the four input cells. On j1a the console line is 88 bytes, the same limit as j1b, leaving room for the dictionary. After them the image is 7862 bytes of 8192 on j1a and 12112 of 32768 on j1b.

- j1b-only words `.x`, `.x2`, `dump`, `ms`, `leds`, `convert`, `new`, `w@`, `w!`, `uw@`, `w,`, `calign`, `caligned`, `2rot`, `m*/`, and `throw`, fed from `fsys/j1b/extra.4th`. `.x` prints eight hex digits and `.x2` prints two. `dump` prints hex bytes, sixteen on a line. `ms` waits with a short counted loop because this console has no timer. `leds` writes bit 0 to the LED. `convert` reads the digits after the first character. `new` forgets definitions made after the image. `w@` sign-extends a halfword. `throw` with zero returns, and any other code prints the code and aborts to the text loop. The shared layer does not include this file, so the j1a image stays 7862 of 8192. After these words the j1b image is 13248 bytes of 32768.

- Shared fsys colon words, one text for both cell widths: `until`, signed `.`, `.s`, `'`, `[']`, `\`, variable `'BOOT`, and `."` without the space after the quote. A line that does not fit the terminal buffer is not written past that buffer.

- Manifest field `cpu:` names a Forth profile. Task `soc` with an empty field still cross-compiles `swapforth/j1a`. An unknown id stops the build and does not substitute `j1a`. Profiles `stm8` (class 1, CG=E, stm8ef) and `z80` (class 2, CG=F, cerberus-z80) stop before an image is built. `j1a` and `j1b` are core kits under `cpu/j1/<id>/`: the build copies that kit's core, stack, and memory wrap. `j1b` is the 32-bit core and cross from AFCK_J1B_FORTH `original/j1b`, with `j1b_wrap.v` (`WIDTH 32`, `mem_din`).

## [0.7.0] - 2026-09-27

### Added

- Quartus writes `IO_STANDARD "3.3-V LVTTL"` when the board pin says `LVTTL`, lists `SDC_FILE`, and appends `derive_clock_uncertainty` so TimeQuest fills clock uncertainty. An output pin also gets `CURRENT_STRENGTH_NEW 8MA` and `SLEW_RATE 2`, the Cyclone defaults written out so the fitter does not call them incomplete. Warning 169177 (AN 447 on a 3.3-V LVTTL input) is suppressed: Quartus has no assignment that clears it.

- Quartus emit writes `<project>.qpf` (`QUARTUS_VERSION` 11.0, `PROJECT_REVISION` equal to the `.qsf` name). Quartus II 11 opens that file; a `.qsf` alone is not in the Open Project list. `FAMILY` is quoted, so `Cyclone IV E` is one assignment value. Each name in `includes.lst` is a `VERILOG_FILE`, and those `` `include `` lines are removed from the top so Quartus does not define the module twice.

- Board `terasic_de0nano`: Terasic DE0-Nano, Cyclone IV E `EP4CE22F17C6` (22320 LEs), pins from litex-boards. Clock `clk50` is `R8` at 50 MHz. `user_led` 0 is `A15`. Serial `tx`/`rx` are `B5`/`B4` (LiteX `JP1:10` / `JP1:8`). Working project: `projects/baremetal/blinky_terasic_de0nano` on the Quartus target.

## [0.8.0] - 2026-09-27

### Added

- Quartus II 11.1 fit of `projects/soc_terasic_de0nano` on `EP4CE22F17C6` (2026-09-27 02:10:30): 1001 / 22320 logic elements (4%), 625 / 22320 registers (3%), 65536 / 608256 memory bits (11%, 4096×16). Setup slack 9.752 ns (slow 85°C). See README.
- `doc/quartus-ii-11.md`: what failed in that Quartus II 11 flow and how each failure was closed.
- OpenSpec change `xilinx-soc`: check the console on the DE0-Nano, then add a Xilinx build.

### Fixed

- The SwapForth console instantiates the LED register (`USE_REGIO`). A write of `1` to `IO-LED` (`$400 io!`) drives `led`. The pin is no longer tied to ground.
- Quartus strip of `` `include `` keeps a Verilog line that is longer than the read buffer. A split token (`.led` written as `.le` / `d`) is a syntax error in Quartus II 11.
- A Verilog `` `include `` of a `.vh` inside a leaf is `VERILOG_INCLUDE_FILE` in the `.qsf`, so Quartus lists `iomap.vh` in the project files. It stays out of `VERILOG_FILE`.
- A `$readmemh` file that sits in the project directory is `HEX_FILE` in the `.qsf`, so the Quartus II 11 file list shows `firmware.hex`. The RAM image is still read by `$readmemh`.

### Changed

- Quartus SoC working project is `projects/soc_terasic_de0nano` (task `soc`, target `quartus`, board `terasic_de0nano`, design `designs/soc_console.4th`). Removed projects `soc_vitasound_ep4ce10`, `blinky_vitasound_ep4ce10`, `blinky_rz_easyfpga` and boards `vitasound_ep4ce10`, `rz_easyfpga`.

## [0.6.0] - 2026-09-26

### Added

- `projects/soc_emul_colorlight_5a_75e_v6_0`: the SwapForth console in Verilator at the Colorlight 5A-75E v6.0 clock, 25 MHz. UART, `rst`, and `dump` stay on the simulated top. `sim.sh` takes `CLK_HZ` from that clock, so `1 2 + .` answers `3 ok`.

### Changed

- An emulation target with a board keeps `sim.sh` and does not emit the board netlist (`BOARD`, `NO_UART`, `LED_LOW`, `TIMER_DIV`). Quartus and Yosys still replace the top after the firmware feed and drop `sim.sh`.

## [0.5.0] - 2026-09-26

### Added

- `projects/soc_blink_colorlight_5a_75e_v6_0`: the J1 lamp image on Colorlight 5A-75E v6.0 through the Yosys target. The clock is the board's 25 MHz `clk25` (`P6`). The board has no UART pins, so the board top ties `uart_rx` to 1 and does not bring `uart_tx`, `rst`, or `dump` out. `user_led` is active-low (`LED_LOW=1`, pin `T6`).
- `active-low` / `io.low@` on a board resource. The three Colorlight `user_led` resources set it.
- Timer parameter `TIMER_DIV` (default 1). On a board it is `CLK_HZ/1000`, so the lamp's period of 500 is about half a second. With `DIV` greater than 1 the counter holds 0 until the next write.

### Changed

- The SwapForth feed that writes `firmware.hex` stays at 50 MHz, matching emulation. The board `top.v` is generated again at the board clock.
- Yosys reads Verilog with `-DSYNTHESIS`. `$writememh` in `j1_wrap.v` sits inside `ifndef SYNTHESIS`, so synthesis ignores the simulator dump and Verilator still writes `firmware.hex`.

### Notes

- Routed nextpnr on `LFE5U-25F` (`--25k`), 2026-09-26: 1135/24288 LUT4 (1017 logic, 118 carry), 697/24288 DFF, 0/3036 RAM LUT, 4/56 `DP16KD`, 2/197 `TRELLIS_IO`. The four blocks hold the 8 KB firmware (64 Kbit of data inside 72 Kbit reserved, of 1008 Kbit block RAM). Fmax 71.55 MHz, constraint 25.00 MHz, pass. `soc.bit` is 591641 bytes. `load.sh` still stops without a `cable` option.

## [0.4.0] - 2026-09-26

### Added

- Yosys target: `--build` writes `<project>.lpf`, `build.sh` and `load.sh`, then runs `yosys`, `nextpnr-ecp5` and `ecppack`. Tools already on `PATH` are used as they are. Otherwise the run sources `~/oss-cad-suite/environment` when that install exists. `FSOC_SYNTH_SKIP` writes the files and skips the tools. `load.sh` calls `openFPGALoader` only when the manifest has a `cable` option.
- Colorlight 5A-75E boards `colorlight_5a_75e_v6_0`, `v7_1` and `v8_2` (package, speed, density, one 25 MHz clock). The working project is `projects/baremetal/blinky_colorlight_5a_75e_v6_0`.
- `fsoc --clean` deletes build output in the project directory and keeps `target.4th`. Without that file it stops. `--clean --build` wipes the output and builds again.
- Optional emulation VCD: `FSOC_EMU_TRACE=1` at `--build` passes Verilator `--trace` for the viewer binary and writes `trace.vcd` (4096 cycles, or `FSOC_EMU_CYCLES` if longer). `tools/peek.sh` sends that file to WavePeek. The skill is `.cursor/skills/wavepeek`.

### Changed

- Blinky takes the single board clock and the constraint period from that frequency. Quartus on a 50 MHz board still writes period `20.000`.
- README / AGENTS.md: a `projects/*` directory is a working copy. Git tracks only `target.4th`; `--build` emits the rest locally. Task and design are debugged on `emulation`; a board project reuses the same design with `quartus` or `yosys` plus `board:`.

## [0.3.0] - 2026-09-25

### Added

- `projects/soc_vitasound_ep4ce10` writes Quartus files and `firmware.hex`. `--build` does not run Quartus; `--load` runs `load.sh`. `fterm` opens a device path (`gforth tools/fterm.4th /dev/ttyUSB0`); without a path it still answers `ok` from memory.
- Board clock: `io.clock-hz` / `plat-clock-hz` (50 MHz on `clk50`). Quartus maps `serial` subsignals (`quartus-map-sub`: `PIN_114` → `uart_tx`, `PIN_115` → `uart_rx`). Design parameter `BOARD=1` ties `rst` and `dump` to 0.

### Changed

- **BREAKING** SoC UART divider follows `CLK_HZ/BAUD` (50 MHz / 115200). Emulation no longer hard-codes 104 clocks/bit.

### Notes

- Quartus `build.sh` / `load.sh` were not run here (no Quartus in WSL). A live USB-UART line `3  ok` is not recorded; `tests/fterm_test.4th` covers the mock backend.

## [0.2.0] - 2026-09-25

### Changed

- **BREAKING** Designs no longer read `FSOC_SOC_TOP`, `FSOC_BLINKY_TOP`, or `FSOC_BLINKY_LED_BIT`. The builder calls `fhdlgen build <design> --out <dir> [--param LED_BIT=n]` (fhdlgen >= 0.5). Leaf copies come from `includes.lst`, not from `awk` on `top.v`.
- Emulation library in `emu/`: `clock` (`Clock`, `env_int` / `env_str`, `FSOC_EMU_CYCLES`), `uart` (`RxShift` / `TxDec`; bit period `-DFSOC_UART_BIT` from `sim.sh`), `script` (`Session`, `EnvLines`, `HostLines`). Task mains live in `fsoc/tasks/` (`blinky_main.cpp`, `soc_main.cpp`, `soc_feed.cpp`).
- **BREAKING** `FSOC_EMU_SNAPSHOT` is gone. SwapForth `include` is flattened in Forth (`soc-flatten`); `Vtop_feed` pulses `dump` and the wrapper writes `firmware.hex` with `$writememh`. `soc_blink` without a scripted line no longer stops on lamp text; set `FSOC_EMU_CYCLES`.
- **BREAKING** The LiteX-style `csr.4th` / `cores.4th` map is gone. One J1 io map in `fsoc/soc/iomap.4th` writes `csr.fs`, `iomap.vh`, and `csr.json`. `lamp.fs` uses `IO-LED` / `IO-TIMER`.
- **BREAKING** `target.4th` manifest: `s" <task>" task:`, `s" <target>" target:`, `s" <board>" board:`, `s" <path>" design:`, `s" <name>" s" <value>" option:`. `fsoc-task!`, `fsoc-target!`, `fsoc-board!`, `fsoc-design!` and `soc-lamp-on` are gone; `soc_blink` uses `s" lamp" s" 1" option:`. `design:` is a path from `FSOC_HOME`.
- Builder core (`fsoc/core.4th`): `paths.4th` (`fsoc-root`, `fsoc-path`, `cwd@`), `sh.4th` (`sh-run`, `sh-cp`, `sh-mkdir`), `log.4th` (`fsoc-note`), `project.4th` (`project%`, manifest words, `project-copy-in`), `registry.4th` (`task-register`, `target-register`), `hdl.4th` (`fhdlgen-build`), `build.4th` (`fsoc-build`: task emit → target emit → target run; `fsoc-load`). Tasks live in `fsoc/tasks/blinky.4th` and `fsoc/tasks/soc.4th` and register themselves; the CLI names no task and no script.
- Targets have `emit` / `run` / `load` hooks. `emulation` copies `emu/con.*` and the task harness (`project.harness$`) and writes `sim.sh`; `quartus` writes `.qsf`, `.sdc`, `build.sh`, `load.sh` with `FAMILY` from the board (`plat-family`; `ep2c5_mini` is `Cyclone II`). `board-load` lives in the core and checks the stack.
- Strings use `fjson.str-*` and `fjson.emit`; lists use `ulist-each`. `fsoc-append`, `fsoc-str-dup`, `fsoc-u>str`, `fsoc-streq`, `pick3`, `blinky-cp` / `soc-cp` and the `../../` path guessing are removed. `csr.json` is written with `fjson.emit-*`.
- Tests run every build in a temporary directory (`tests/fixture.4th`: `TS{`/`test-setup`, `tmp-use-project`, `in-tmp-fsoc`) and end with `expect-stack-clean`; `projects/*` are not touched. New `paths_test`, `sh_test`, `project_test`, `registry_test`, `layers_test`.
- Coverage (`fcov run`): 95% of instrumented definitions (173/182). Uncovered: `fsoc.version`, `fsoc.help`, `fterm`, `fterm-open`, `stty-append`, `fterm-mock`, `sh-rm`, `connector`, `misc`. `fsoc/soc/iomap.4th` is 18/18.

- OpenSpec: `con-term`, `j1-forth`, `soc-emulation`, `soc-io-blink` archived; `soc-build-log` closed, its open tasks moved to `design-out-contract`. Layer changes `builder-hygiene` through `iomap` are implemented (see `doc/roadmap.md`).
- `package.4th`: `fmix ~> 0.8`; dependency `f` and `fcov-exclude tests/golden` dropped. frules installed in `.cursor/rules/`, `fmix hook install --stage all`.

### Removed

- `FSOC_EMU_SNAPSHOT`, C++ `load_forth` / `snapshot_ram` / `top__DOT__` RAM peeks, and the lamp-text oracle in `soc_main`.
- `fsoc/blinky.4th`, `fsoc/soc.4th`, `designs/blinky.4th`, `fsoc/toolchains/quartus.4th`, `tests/load.4th` duplicate include list.
- Dead code: `firmware/ok.4th`, `firmware/j1asm.4th`, `firmware/hex2readmem.4th` (J1 assembler superseded by the SwapForth cross-compiler), `cpu/j1/j1_prompt.v`, `cpu/j1/tb_prompt.v`, `tests/j1_prompt_test.4th`, `fsoc/toolchains/icarus.4th`, `targets/base_soc.4th`, `tests/build/`.
- `firmware/firmware.hex` is no longer tracked; each project writes its own.

## [0.1.1] - 2026-09-24

### Added

- SoC `--build` prints `fsoc: <project> - Start build`, then `Hardware` and `Software`. fhdlgen prints each Verilog include from the top fragment as `fhdlgen: <file>`. The log then says `Hardware complete`, lists the firmware sources and size, says `Software complete`, and `Start emulation` before `sim.sh`. Ctrl+C then prints `Emulation stopped`.
- `projects/soc_blink` starts a Forth loop from `'BOOT` and does not return to the prompt. The loop stores `0` and `1` at `h# 400`, so the `led` port toggles, and waits on the counter at `h# 800`. `FSOC_EMU_CON=term` shows `lamp on` and `lamp off`. `FSOC_EMU_CON=pin` prints only `pin led 0` and `pin led 1`.
- SoC emulation `projects/soc_emul` boots SwapForth J1a. The dictionary is its ANS CORE set without `environment?`, and a line on the UART is answered with ` ok`.
- UART console: `FSOC_EMU_CON=term` writes the byte stream as text. On a tty ncurses shows that text above a host input row; Enter sends the row. `FSOC_EMU_CON=log` keeps `t=<ns> uart <name> <byte>`. Unset follows stdout: a terminal is text, a file stays the log.
- Blinky emulation `main` lives in `fsoc/blinky_main.cpp`. `emu/` keeps only the shared `con` console.
- A project's `target.4th` names its fhdlgen design. That file is the chip composition: `soc_emul` builds `designs/soc_console.4th` (UART, no timer, no `regio`), `soc_blink` builds `designs/soc_top.4th`. Leaf copies follow the design's `` `include `` lines.
- The top module name is the design property `project.top`. `FSOC_SOC_TOP` and `FSOC_BLINKY_TOP` are the output directory; the file is `<dir>/<project.top>.v`. Verilator `--top-module` and Quartus read the same value from `top-module`.
- Builder runs from the project directory: `fsoc --build`, `fsoc --load`, `fsoc --build --load`. Task and board come from `projects/*/target.4th`.
- `bin/fsoc` launcher (`FSOC_HOME` + `PATH`), same pattern as fhdlgen.
- Blinky emulation runs under Verilator in realtime until Ctrl+C. Console events are `t=<ns> pin <name> <value>` on change, and `t=<ns> uart <name> <byte>` for a future decoded serial port.
- Working solutions live in `projects/` (`blinky_emul`, `blinky_vitasound_ep4ce10`, `blinky_rz_easyfpga`), each with its own copies of `top.v` / `blinky.v`. Leaf stays in `rtl/`.

## [0.1.0] - 2026-09-23

### Added

- Platform DSL: `platform-new`, `io-begin` / `pins` / `iostd` / `subsignal` / `io-end`, `connector`, `request` / `request-all`.
- Boards: `vitasound_ep4ce10`, `rz_easyfpga`, `ep2c5_mini`.
- Toolchains: Quartus (`.qsf` `.sdc` `build.sh` `load.sh`), Icarus/Verilator sim scripts.
- Blinky target: Verilog + Icarus TB + Quartus project.
- CSR layout, `csr.4th` HAL, `csr.json`; cores uart/gpio/timer/ctrl.
- J1 wrapper + prompt UART model; `fterm`; `hex2readmem`; FOOTSWITCH-SCAN host firmware.
