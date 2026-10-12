---
name: Why Adding a New CPU/MCU Is Hard in fsoc
overview: Analysis of 8051 integration challenges and proposal for AI-assisted Forth development tooling (stack analyzers, instruction spec validators, CPU profile generators)
todos:
  - id: analyze-8051-layers
    content: Document the 6+ layers required for 8051 integration and where manual errors occur
    status: completed
  - id: design-stack-analyzer
    content: Design stack effect analyzer for target Forth kernels (parse k- words, infer stack contracts)
    status: completed
  - id: design-isa-to-fasm
    content: Design ISA spec → comma word generator (JSON/YAML → fasm words.4th + validation)
    status: completed
  - id: design-profile-wizard
    content: Design interactive CPU profile wizard (FMAP axes → cpu.4th + cg-<id>.4th + con_session.4th)
    status: completed
  - id: design-test-synthesizer
    content: Design REPL test vector synthesizer (kernel word list → con_words.py RUN/COLON/SKIP)
    status: completed
  - id: design-cross-linter
    content: Design host cross-compiler linter (bx-* words vs k-* primitives alignment)
    status: completed
  - id: create-plan
    content: Present consolidated plan with file paths and integration points
    status: completed
isProject: false
---

# Why Adding a New CPU/MCU Is Hard in fsoc

## The 8051 Case Study

The 8051 integration took ~1 day because it requires **6+ distinct layers** that must align perfectly:

| Layer | Files | Complexity |
|-------|-------|------------|
| **Profile** | `fsoc/cpu.4th` | FMAP classification (Class 1, MM=D, EX-C=S, CG=F), kit wiring |
| **Assembler (fasm)** | `fsys/fasm/8051/*.4th` | Comma words for 111+ MCS-51 opcodes, chip variants (`at89c52.4th`), hex emission |
| **Kernel** | `fsys/kernel/8051/kernel.4th` + `kernel-b.4th` | 600+ lines of STC Forth in 8051 assembly: stacks, UART, `@` `!`, `:` `;`, `quit`, `words` |
| **Host Cross** | `fsys/host/8051-cross.4th` | Full Forth compiler targeting 8051 (LCALL/RET colons), lexical analysis, number parsing |
| **Extra/Release** | `fsys/8051/extra-min.4th` | Chip words on the kernel |
| **CG Emitter** | `fsoc/tasks/cg-8051.4th` | Image builder: soft (Verilator + R8051) + hard (Proteus Intel HEX) |
| **Tests** | `tests/con_core_test.4th`, `tests/con_words.py`, `tests/8051_fasm_test.4th` | REPL grid membership, dictionary JSON, behavior validation |

**Each layer is hand-written in Forth/Verilog with zero automation.** A mistake in any layer cascades silently (wrong stack depth, broken forward refs, hex format mismatch).

## Root Causes of Difficulty

1. **No specification-to-code pipeline** — ISA docs → comma words → kernel primitives → cross compiler → test vectors are all manual translations
2. **No stack effect verification** — 8051 kernel words (`kdup`, `kplus`, etc.) manipulate registers (r2-r7) and XRAM manually; one `drop` vs `2drop` error breaks the REPL
3. **No instruction encoding validator** — `fasm` comma words (`mov-di#`, `lcall,`, `ljmp,`) must match `r8051.v` opcode map exactly
4. **No profile generator** — `cpu-new` + 15 `cpu-*` setters + `cg-register` + `cpu-bind-cg` are all manual
4. **Test oracle is hand-crafted** — `con_words.py` recipes per CPU (516 lines) with `MCS51_RUN`/`MCS51_SKIP` tables

## Proposed Tooling (AI-Friendly, Incremental, All Python)

### 1. Stack Effect Analyzer for Target Forth Kernels
- Parse `kernel.4th` / `kernel-b.4th` → extract every `k-` word → infer `( before -- after )` from register usage patterns (r2-r7, XRAM access patterns)
- Cross-check against ANS stack contracts in `con_words.py` RUN table
- Flag depth mismatches before emulation
- Output: JSON report + suggested fixes

### 2. Instruction Spec → Comma Word Generator
- Input: JSON/YAML of ISA (opcode, mnemonic, operands, cycles, flags)
- Output: `fsys/fasm/<id>/words.4th` comma words + `chip.4th` register/bit defs
- Validate: round-trip `fasm` assembled bytes → Verilog `instruction.v` decoder match
- Handles chip variants (at89c52, at89s52, etc.) via overlay configs

### 3. CPU Profile Wizard (Interactive CLI)
- Questions → FMAP axes (Class, MM, EX-C, CG, BM) → emits `cpu.4th` `cpu-new` block + `cg-<id>.4th` skeleton + `con_session.4th` manifest
- Ensures `cpu-bind-cg` wiring matches CG emitter
- Generates starter `target.4th` for baremetal/soc/blinky

### 4. REPL Test Vector Synthesizer
- From `kernel.4th` word list + ANS contracts → auto-generate `con_words.py` RUN/COLON/SKIP entries
- Reduces 516-line hand maintenance per CPU
- Infers SKIP reasons from word names (e.g., `p1!` → "pin side effect")

### 5. Cross-Compiler Linter
- Parse `fsys/host/<id>-cross.4th` → verify every `bx-*` word has matching kernel primitive
- Check `bx-find`/`bx-call`/`bx-lit`/`bx-ret` alignment with `k-lit`/`k-call`/`k-ret`/`k-exit`
- Detects missing compiler words, immediate/compile-only mismatches

## Implementation Priority

1. **Stack analyzer** (immediate ROI — catches 80% of kernel bugs)
2. **Instruction spec → fasm** (removes 200+ lines of error-prone comma words)
3. **Profile wizard** (eliminates `cpu.4th` copy-paste errors)
4. **Test vector synthesizer** (maintains `con_words.py` automatically)
5. **Cross-compiler linter** (catches host/target drift)

## Files to Create/Modify

| Tool | New File | Integrates With |
|------|----------|-----------------|
| Stack analyzer | `tools/stack_analyze.py` | `fsys/kernel/<id>/kernel.4th` |
| ISA → fasm | `tools/isa_to_fasm.py` | `fsys/fasm/<id>/words.4th` |
| Profile wizard | `tools/cpu_profile_wizard.py` | `fsoc/cpu.4th`, `fsoc/tasks/cg-<id>.4th` |
| Test synthesizer | `tools/con_words_gen.py` | `tests/con_words.py` |
| Cross linter | `tools/cross_lint.py` | `fsys/host/<id>-cross.4th` |

All tools are Python CLI scripts that integrate with existing `fmix test`, `flint`, `gforth` workflows. Output is valid Forth/Verilog/JSON that the build system consumes directly.