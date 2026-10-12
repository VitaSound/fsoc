#!/usr/bin/env python3
"""
run_all_tools.py — run every fsoc CPU through the five AI-assisted tools.

Auto-discovers CPUs from the filesystem (no hard-coded list) and, for each
CPU, runs the tools that have the required inputs:

  stack_analyze.py   requires  fsys/kernel/<cpu>/kernel*.4th
  cross_lint.py      requires  fsys/host/<cpu>-cross.4th + fsys/kernel/<cpu>/
  con_words_gen.py   requires  fsys/kernel/<cpu>/ + doc/j1-word-graph/fsys-<cpu>*.json
  isa_to_fasm.py     requires  tools/isa_specs/<spec>.json   (spec name derived below)
  cpu_profile_wizard interactive / JSON only — reported, not run (no stdin)

Usage:
  python3 tools/run_all_tools.py                 # run everything, print summary
  python3 tools/run_all_tools.py --json report.json
  python3 tools/run_all_tools.py --only stack,cross,con,isa
  python3 tools/run_all_tools.py --dry-run

Exit code: 0 when no tool *errored* (warnings are not errors).
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
KERNEL = ROOT / "fsys" / "kernel"
HOST = ROOT / "fsys" / "host"
FASM = ROOT / "fsys" / "fasm"
GRAPH = ROOT / "doc" / "j1-word-graph"
ISA = TOOLS / "isa_specs"

# ISA spec filename per cpu id. Some archs differ from the cpu id (mcs51 for 8051).
ISA_SPEC = {
    "j1a": "j1_isa.json",
    "j1b": "j1_isa.json",
    "bcpu": "bcpu_isa.json",
    "z80": "z80_isa.json",
    "avr": "avr_isa.json",
    "cd16": "cd16_isa.json",
    "msl16": "msl16_isa.json",
    "8051": "mcs51_isa.json",
    "stm8": "stm8_isa.json",
}


def discover_cpus() -> dict:
    """Discover CPUs from the filesystem and map each tool to its inputs."""
    cpus = {}
    for d in sorted(KERNEL.glob("*")):
        if not d.is_dir():
            continue
        cpu = d.name
        kernels = sorted(d.glob("kernel*.4th"))
        if not kernels:
            continue  # no kernel file
        cpus[cpu] = {"kernel": [str(k.relative_to(ROOT)) for k in kernels]}

    # host cross: fsys/host/<cpu>-cross.4th  (j1a/j1b are external -> absent)
    for d in sorted(HOST.glob("*-cross.4th")):
        cpu = d.stem.replace("-cross", "")
        if cpu in cpus:
            cpus[cpu]["cross"] = str(d.relative_to(ROOT))

    # dictionary json for con_words: doc/j1-word-graph/fsys-<cpu>*.json
    for j in sorted(GRAPH.glob("fsys-*.json")):
        stem = j.stem  # fsys-<cpu>[-extra-min]
        m = re.match(r"fsys-(.+?)(-extra-min)?$", stem)
        if m:
            cpu = m.group(1)
            if cpu in cpus:
                cpus[cpu]["dict"] = str(j.relative_to(ROOT))

    # fasm presence (informational)
    for d in sorted(FASM.glob("*")):
        if d.is_dir() and d.name in cpus:
            words = d / "words.4th"
            cpus[d.name]["fasm"] = "yes" if words.exists() else "no-words"

    # isa spec presence (informational)
    for cpu in cpus:
        spec = ISA_SPEC.get(cpu)
        if spec and (ISA / spec).exists():
            cpus[cpu]["isa"] = spec
    return cpus


def run(cmd: list[str], cwd: Path = ROOT) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=120)
        out = (p.stdout or "") + (("\n" + p.stderr) if p.stderr else "")
        return p.returncode, out
    except subprocess.TimeoutExpired:
        return 124, "timeout"
    except Exception as e:  # noqa: BLE001
        return 1, str(e)


def analyze_stack(cpu: str, info: dict, out: dict, report: Path) -> None:
    # Pass the kernel directory (stack_analyze globs kernel*.4th there, so an
    # 8051 kernel-b.4th is included). --report keeps the on-disk artifact out
    # of the repo; the stdout JSON still drives this report.
    rc, output = run([sys.executable, str(TOOLS / "stack_analyze.py"),
                      str(KERNEL / cpu), "--report", str(report)])
    words = 0
    try:
        jpart = output[output.index("{"):]
        words = json.loads(jpart).get("summary", {}).get("total_words", 0)
    except Exception:
        pass
    out["stack"] = "ok" if rc == 0 else f"error rc={rc}"
    out["stack_words"] = words
    if rc != 0:
        out["stack_detail"] = output.strip()[:200]


def lint_cross(cpu: str, info: dict, out: dict) -> None:
    if "cross" not in info:
        out["cross"] = "skipped (no host cross; external interpreter)"
        return
    rc, output = run([sys.executable, str(TOOLS / "cross_lint.py"),
                      info["cross"], str(KERNEL / cpu)])
    warn = sum(1 for line in output.splitlines() if line.strip().startswith("⚠"))
    # cross_lint prints "No errors." on success; any ERROR line is a real error.
    err_lines = [l for l in output.splitlines()
                 if l.strip().upper().startswith("ERROR")]
    ok = rc == 0 and "No errors." in output and not err_lines
    out["cross"] = (f"ok ({warn} warnings)" if ok else
                    (f"errors: {len(err_lines)}" if err_lines else f"rc={rc}"))
    out["cross_warnings"] = warn
    if not ok:
        out["cross_detail"] = output.strip()[:300]


def gen_con_words(cpu: str, info: dict, out: dict) -> None:
    if "dict" not in info:
        out["con"] = "skipped (no fsys dictionary json)"
        return
    rc, output = run([sys.executable, str(TOOLS / "con_words_gen.py"), cpu, str(KERNEL / cpu)])
    if rc != 0:
        out["con"] = f"error rc={rc}"
        out["con_detail"] = output.strip()[:200]
        return
    lines = output.splitlines()
    out["con"] = "ok"
    for line in lines:
        if line.startswith("  RUN:"):
            out["con_run"] = line.strip()
        elif line.startswith("  SKIP:"):
            out["con_skip"] = line.strip()


def gen_isa(cpu: str, info: dict, out: dict, dry: bool) -> None:
    spec = info.get("isa")
    if not spec:
        out["isa"] = "skipped (no ISA spec)"
        return
    out["isa"] = "ok (spec present)"
    if dry:
        return
    # Generate into a /tmp scratch dir; do NOT overwrite the hand-written fasm files.
    scratch = Path("/tmp") / "isa_gen_preview" / cpu
    rc, output = run([sys.executable, str(TOOLS / "isa_to_fasm.py"),
                      str(ISA / spec), str(scratch)])
    out["isa"] = "ok (generated preview)" if rc == 0 else f"error rc={rc}"
    if rc != 0:
        out["isa_detail"] = output.strip()[:200]

    # Drift gate: when the CPU has a hand-written fasm words.4th, the spec
    # must agree with every opcode emitted there (catches spec/fasm drift).
    words = FASM / cpu / "words.4th"
    if words.exists():
        rc, output = run([sys.executable, str(TOOLS / "isa_to_fasm.py"), "--check",
                          str(ISA / spec), str(words)])
        out["isa_check"] = "ok" if rc == 0 else "error rc=" + str(rc)
        if rc != 0:
            out["isa_check_detail"] = output.strip()[-300:]


def main() -> int:
    args = sys.argv[1:]
    dry = "--dry-run" in args
    only = None
    if "--only" in args:
        only = set(args[args.index("--only") + 1].split(","))
    json_out = None
    if "--json" in args:
        json_out = Path(args[args.index("--json") + 1])
    # Where stack_analyze writes its own report: a temp path by default so we
    # never touch the committed tools/stack_analysis_report.json.
    stack_report = Path("/tmp/fsoc_stack_analysis.json")
    if "--stack-report" in args:
        stack_report = Path(args[args.index("--stack-report") + 1])

    tools = {"stack", "cross", "con", "isa"}
    if only:
        tools &= only

    cpus = discover_cpus()
    report = {"root": str(ROOT), "cpus": {}}

    print(f"Discovered {len(cpus)} CPUs with kernels: {', '.join(cpus)}\n")

    any_error = False
    for cpu in sorted(cpus):
        out: dict = {"kernel": cpus[cpu]["kernel"]}
        if "stack" in tools:
            analyze_stack(cpu, cpus[cpu], out, stack_report)
        if "cross" in tools:
            lint_cross(cpu, cpus[cpu], out)
        if "con" in tools:
            gen_con_words(cpu, cpus[cpu], out)
        if "isa" in tools:
            gen_isa(cpu, cpus[cpu], out, dry)
        report["cpus"][cpu] = out

        # console line
        parts = []
        for t in ("stack", "cross", "con", "isa"):
            if t in out:
                parts.append(f"{t}={out[t].split(' (')[0]}")
        print(f"  {cpu:6}  " + "  ".join(parts))

        for t in ("stack", "cross", "con", "isa"):
            if t in out and out[t].startswith("error"):
                any_error = True
        if str(out.get("isa_check", "")).startswith("error"):
            any_error = True

    print()

    # Validate every ISA spec in the tree is well-formed JSON, independent of
    # CPU discovery (stm8 has a spec but no fsoc kernel, so it never shows up
    # above). A corrupt spec here would break isa_to_fasm.py silently later.
    spec_files = sorted(ISA.glob("*.json")) if ISA.exists() else []
    bad_specs = []
    for sf in spec_files:
        try:
            json.loads(sf.read_text())
        except Exception as e:  # noqa: BLE001
            bad_specs.append(f"{sf.name}: {e}")
    report["isa_specs"] = {"checked": len(spec_files), "bad": bad_specs}
    if bad_specs:
        any_error = True
    print(f"ISA specs: {len(spec_files)} checked, {len(bad_specs)} invalid")
    for b in bad_specs:
        print(f"  - {b}")

    # per-tool summary
    counts = {}
    for cpu, out in report["cpus"].items():
        for t in ("stack", "cross", "con", "isa"):
            if t in out:
                key = "ok" if out[t].startswith("ok") else ("skip" if out[t].startswith("skipped") else "error")
                counts.setdefault(t, {"ok": 0, "skip": 0, "error": 0})
                counts[t][key] += 1
    print("Tool summary:")
    for t in ("stack", "cross", "con", "isa"):
        c = counts.get(t, {"ok": 0, "skip": 0, "error": 0})
        print(f"  {t:6} ok={c['ok']}  skip={c['skip']}  error={c['error']}")

    if json_out:
        json_out.write_text(json.dumps(report, indent=2))
        print(f"\nReport written to {json_out}")

    return 1 if any_error else 0


if __name__ == "__main__":
    sys.exit(main())
