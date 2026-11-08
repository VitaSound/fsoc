#!/usr/bin/env python3
"""Heuristic extractor: engine-sim .mr scripts → engines.json for the browser catalog.

Usage:
  python3 tools/parse_engines.py
  python3 tools/parse_engines.py --root /path/to/engine-sim --out viz/engines.json
"""
from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path

DEFAULT_ROOT = Path("/home/sea/engine-sim")
DEFAULT_OUT = Path(__file__).resolve().parent.parent / "viz" / "engines.json"

# Strip // line comments and /* */ blocks (rough; enough for engine defs)
_COMMENT_LINE = re.compile(r"//[^\n]*")
_COMMENT_BLOCK = re.compile(r"/\*.*?\*/", re.S)


def strip_comments(text: str) -> str:
    text = _COMMENT_BLOCK.sub("", text)
    return _COMMENT_LINE.sub("", text)


def find_balanced(text: str, start: int) -> int | None:
    """Return index after matching ')' for '(' at start, or None."""
    if start >= len(text) or text[start] != "(":
        return None
    depth = 0
    i = start
    while i < len(text):
        c = text[i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return None


def kv_pairs(body: str) -> dict[str, str]:
    """Split top-level key: value pairs inside a node call body.

    Respects quoted strings and nested parentheses so commas inside
    ``name: "Foo [VTEC, I4]"`` stay in the value.
    """
    out: dict[str, str] = {}
    i = 0
    n = len(body)
    while i < n:
        while i < n and body[i] in " \t\n\r,":
            i += 1
        if i >= n:
            break
        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s*:", body[i:])
        if not m:
            # positional arg (e.g. bank_params) — skip one token / call
            if body[i] in "\"'":
                q = body[i]
                i += 1
                while i < n and body[i] != q:
                    if body[i] == "\\" and i + 1 < n:
                        i += 2
                        continue
                    i += 1
                i += 1
            elif body[i] == "(":
                end = find_balanced(body, i)
                i = end if end else i + 1
            else:
                while i < n and body[i] not in ",)\n":
                    if body[i] == "(":
                        end = find_balanced(body, i)
                        i = end if end else i + 1
                        break
                    i += 1
            continue
        key = m.group(1)
        i += m.end()
        while i < n and body[i] in " \t\n\r":
            i += 1
        if i >= n:
            break
        # Value runs until a top-level comma (expressions may start with
        # `(4.0 + 1) * units.inch + …` — must not stop at first `)`).
        start = i
        depth = 0
        while i < n:
            c = body[i]
            if c in "\"'":
                q = c
                i += 1
                while i < n and body[i] != q:
                    if body[i] == "\\" and i + 1 < n:
                        i += 2
                        continue
                    i += 1
                i += 1
                continue
            if c == "(":
                depth += 1
            elif c == ")":
                if depth == 0:
                    break
                depth -= 1
            elif c == "," and depth == 0:
                break
            i += 1
        val = body[start:i].strip()
        out[key] = val
    return out


# `node_name optional_id (`  e.g. rod_journal rj0(  /  engine engine(
_CALL_HEAD = r"(?<![A-Za-z0-9_]){name}(?:\s+[A-Za-z_][A-Za-z0-9_]*)?\s*\("


def iter_calls(text: str, name: str):
    pat = re.compile(_CALL_HEAD.format(name=re.escape(name)))
    for m in pat.finditer(text):
        open_paren = m.end() - 1
        end = find_balanced(text, open_paren)
        if end is None:
            continue
        body = text[open_paren + 1 : end - 1]
        yield kv_pairs(body), m.start(), end


def clean_expr(s: str) -> str:
    s = re.sub(r"\s+", " ", s.strip())
    return s


def parse_labels(text: str) -> dict[str, str]:
    labels: dict[str, str] = {}
    for m in re.finditer(
        r"label\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*([^)]+)\)", text
    ):
        labels[m.group(1)] = clean_expr(m.group(2))
    return labels


def first_call(text: str, name: str) -> dict[str, str] | None:
    for pairs, _, _ in iter_calls(text, name):
        return pairs
    return None


def all_calls(text: str, name: str) -> list[dict[str, str]]:
    return [pairs for pairs, _, _ in iter_calls(text, name)]


def extract_timing_curve(text: str) -> list[dict[str, str]]:
    samples = []
    # timing_curve.add_sample(rpm, angle) or chained .add_sample
    for m in re.finditer(
        r"\.add_sample\s*\(\s*([^,]+)\s*,\s*([^)]+)\)", text
    ):
        samples.append(
            {"rpm": clean_expr(m.group(1)), "advance": clean_expr(m.group(2))}
        )
    return samples


def extract_flow_samples(text: str, which: str) -> list[dict[str, str]]:
    """which: intake_flow or exhaust_flow function bodies nearby."""
    samples = []
    # .add_flow_sample(lift, flow)
    for m in re.finditer(
        r"\.add_flow_sample\s*\(\s*([^,]+)\s*,\s*([^)]+)\)", text
    ):
        samples.append(
            {"lift": clean_expr(m.group(1)), "flow": clean_expr(m.group(2))}
        )
    return samples


def parse_angle_expr(expr: str) -> float | None:
    """Best-effort numeric degrees from `… * units.deg` or bare / radian-ish values."""
    expr = expr.strip()
    m = re.search(r"(.+?)\s*\*\s*units\.deg", expr)
    if m:
        inner = m.group(1).strip()
        # Evaluate (1/5.0)*360 etc. — do NOT multiply all numbers (that made 1800°).
        safe = inner.replace("constants.pi", str(math.pi))
        if re.fullmatch(r"[\d\s./+\-*()]+", safe):
            try:
                v = float(eval(safe, {"__builtins__": {}}, {}))
                if math.isfinite(v):
                    return v
            except Exception:
                pass
        nums = re.findall(r"-?\d+(?:\.\d+)?", inner)
        if len(nums) == 1:
            return float(nums[0])
    if "constants.pi" in expr or re.search(r"(?<![A-Za-z0-9_])pi(?![A-Za-z0-9_])", expr):
        # common: constants.pi → 180°, pi/2 → 90°
        if "/ 2" in expr or "/2" in expr:
            return -90.0 if expr.strip().startswith("-") else 90.0
        if "3.0" in expr or "3 *" in expr:
            return -270.0 if "-" in expr.split("pi")[0] else 270.0
        return -180.0 if expr.strip().startswith("-") else 180.0
    m = re.match(r"^(-?\d+(?:\.\d+)?)$", expr)
    if m:
        v = float(m.group(1))
        if abs(v) <= 6.5:
            return v * 180.0 / 3.141592653589793
        return v
    return None


def infer_layout(bank_angles: list[float], n_cyl: int, n_banks: int) -> str:
    if n_banks <= 0:
        return "unknown"
    # Many V engines in .mr keep bank angle at 0 (visual tilt elsewhere)
    uniq = sorted({round(a, 1) for a in bank_angles}) if bank_angles else [0.0]
    # Radial: many banks spaced around the circle (or all ~0 before angle fix)
    if n_banks >= 5:
        span = (uniq[-1] - uniq[0]) if len(uniq) >= 2 else 0.0
        if span > 200 or all(abs(a) < 1 for a in uniq):
            return f"radial-{n_cyl}"

    if n_banks == 1 or (len(uniq) == 1 and abs(uniq[0]) < 1.0 and n_banks == 1):
        return f"inline-{n_cyl}" if n_cyl else "inline"
    if len(uniq) >= 2:
        span = abs(uniq[-1] - uniq[0])
        if abs(span - 180) < 5:
            return f"boxer-{n_cyl}"
        if span > 1:
            return f"v{int(round(span))}-{n_cyl}"
    if n_banks == 2:
        return f"v90-{n_cyl}"  # default guess when angles not in script
    if len(uniq) == 1 and abs(uniq[0]) >= 1:
        return f"bank@{uniq[0]}-{n_cyl}"
    return f"multi-{n_banks}bank-{n_cyl}"


def _load_local_imports(path: Path, text: str) -> str:
    """Concatenate same-folder import \"foo.mr\" bodies (skip engine_sim.mr)."""
    parts: list[str] = []
    seen: set[Path] = {path.resolve()}
    for m in re.finditer(r'import\s+"([^"]+)"', text):
        rel = m.group(1)
        if rel.endswith("engine_sim.mr") or rel == "engine_sim.mr":
            continue
        cand = (path.parent / rel).resolve()
        if not cand.is_file() or cand in seen:
            continue
        seen.add(cand)
        parts.append(strip_comments(cand.read_text(encoding="utf-8", errors="replace")))
    return "\n".join(parts)


def parse_engine_file(path: Path, root: Path) -> dict | None:
    raw = path.read_text(encoding="utf-8", errors="replace")
    text = strip_comments(raw)
    imported = _load_local_imports(path, text)
    combined = text + ("\n" + imported if imported else "")
    rel = str(path.relative_to(root)) if path.is_relative_to(root) else str(path)

    # Skip pure helper libs (radial builders without engine name sometimes still have engines)
    eng = first_call(text, "engine")
    if not eng or "name" not in eng:
        return {
            "id": rel.replace("/", "__").replace(".mr", "").replace(".MR", ""),
            "source": rel,
            "skipped": True,
            "reason": "no engine(name: ...) found",
        }

    name = eng.get("name", "").strip().strip('"')
    labels = parse_labels(text)

    # rod_journal rj0(angle: ...) — declaration order; role via add_rod/add_slave
    journals = []
    journal_ids: list[str] = []
    journal_pat = re.compile(
        r"(?<![A-Za-z0-9_])rod_journal\s+([A-Za-z_][A-Za-z0-9_]*)\s*\("
    )
    for m in journal_pat.finditer(text):
        open_paren = m.end() - 1
        end = find_balanced(text, open_paren)
        if end is None:
            continue
        body = text[open_paren + 1 : end - 1]
        pairs = kv_pairs(body)
        ang = pairs.get("angle")
        jid = m.group(1)
        journal_ids.append(jid)
        entry = {"id": jid, "angle_expr": clean_expr(ang) if ang else None, "role": "crank"}
        if ang:
            parsed = parse_angle_expr(ang)
            if parsed is not None:
                entry["angle_deg"] = parsed
        journals.append(entry)

    crank_jids = set(
        m.group(1)
        for m in re.finditer(r"\.add_rod_journal\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)", text)
    )
    slave_jids = set(
        m.group(1)
        for m in re.finditer(r"\.add_slave_journal\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)", text)
    )
    for entry in journals:
        jid = entry["id"]
        if jid in slave_jids:
            entry["role"] = "slave"
        elif jid in crank_jids:
            entry["role"] = "crank"

    banks = []
    bank_angles: list[float] = []
    bank_pat = re.compile(
        r"(?<![A-Za-z0-9_])cylinder_bank\s+([A-Za-z_][A-Za-z0-9_]*)\s*\("
    )
    for m in bank_pat.finditer(text):
        open_paren = m.end() - 1
        end = find_balanced(text, open_paren)
        if end is None:
            continue
        body = text[open_paren + 1 : end - 1]
        pairs = kv_pairs(body)
        ang_expr = pairs.get("angle")
        ang = parse_angle_expr(ang_expr) if ang_expr else 0.0
        if ang is None:
            ang = 0.0
        bank_angles.append(ang)
        # es/objects.mr cylinder_bank_parameters.display_depth default = 0.5
        # (C++ ctor 0.4 is overwritten by script params on initialize)
        dd_expr = pairs.get("display_depth")
        dd_val = None
        if dd_expr:
            try:
                dd_val = float(
                    re.sub(r"[^0-9.eE+-]", "", clean_expr(dd_expr).split()[0])
                )
            except (TypeError, ValueError, IndexError):
                dd_val = None
        banks.append(
            {
                "id": m.group(1),
                "angle_expr": clean_expr(ang_expr) if ang_expr else "0",
                "angle_deg": ang,
                "display_depth": dd_val,
                "journal_indices": [],
            }
        )

    # Map each .add_cylinder → bank + rod_journal (crank vs slave mount)
    bank_by_id = {b["id"]: b for b in banks}
    for b in banks:
        b["mounts"] = []
    crank_ids_ord = [j["id"] for j in journals if j.get("role") == "crank"]
    slave_ids_ord = [j["id"] for j in journals if j.get("role") == "slave"]
    crank_by_id = {jid: i for i, jid in enumerate(crank_ids_ord)}
    slave_by_id = {jid: i for i, jid in enumerate(slave_ids_ord)}
    journal_by_id = {jid: i for i, jid in enumerate(journal_ids)}
    current_bank_id: str | None = None
    events: list[tuple[int, str, str]] = []
    for bid in bank_by_id:
        for m in re.finditer(
            rf"(?<![A-Za-z0-9_]){re.escape(bid)}(?=\s*(?:\n\s*)?\.add_cylinder)",
            text,
        ):
            events.append((m.start(), "bank", bid))
    for m in re.finditer(r"\.add_cylinder\s*\(", text):
        open_paren = m.end() - 1
        end = find_balanced(text, open_paren)
        if end is None:
            continue
        pairs = kv_pairs(text[open_paren + 1 : end - 1])
        rj = (pairs.get("rod_journal") or "").strip()
        events.append((m.start(), "cyl", rj))
    events.sort(key=lambda e: e[0])
    for _, typ, data in events:
        if typ == "bank":
            current_bank_id = data
        elif typ == "cyl" and current_bank_id and current_bank_id in bank_by_id:
            bank = bank_by_id[current_bank_id]
            if data in crank_by_id:
                mount = {"role": "crank", "index": crank_by_id[data]}
                layer = crank_by_id[data]
            elif data in slave_by_id:
                # ConnectingRod::getLayer → master journal (usually 0)
                mount = {"role": "slave", "index": slave_by_id[data]}
                layer = 0 if crank_ids_ord else slave_by_id[data]
            else:
                idx = journal_by_id.get(data, len(bank["journal_indices"]))
                mount = {"role": "crank", "index": idx}
                layer = idx
            bank["journal_indices"].append(layer)
            bank["mounts"].append(mount)

    n_cyl = sum(len(b["journal_indices"]) for b in banks) or len(
        re.findall(r"\.add_cylinder\s*\(", text)
    )
    for b in banks:
        if b["journal_indices"]:
            b["cylinders"] = len(b["journal_indices"])
        else:
            b["cylinders"] = 0
    # Even split fallback when .add_cylinder wasn't tied to a bank id
    if banks and n_cyl and not any(b["journal_indices"] for b in banks):
        base, rem = divmod(n_cyl, len(banks))
        for i, b in enumerate(banks):
            b["cylinders"] = base + (1 if i < rem else 0)
            # V / shared-journal heuristic: cylinder c → journal c (wrap)
            n_j = max(1, len(journals))
            b["journal_indices"] = [c % n_j for c in range(b["cylinders"])]

    bank_params = first_call(text, "cylinder_bank_parameters") or {}
    # Resolve display_depth: per-bank override → bank_params → script default 0.5
    params_dd = None
    if bank_params.get("display_depth"):
        try:
            params_dd = float(
                re.sub(
                    r"[^0-9.eE+-]",
                    "",
                    clean_expr(bank_params["display_depth"]).split()[0],
                )
            )
        except (TypeError, ValueError, IndexError):
            params_dd = None
    for b in banks:
        if b.get("display_depth") is None:
            b["display_depth"] = params_dd if params_dd is not None else 0.5
    piston = first_call(text, "piston_parameters") or {}
    rod = first_call(text, "connecting_rod_parameters") or {}
    crank = first_call(text, "crankshaft") or {}
    intake = first_call(text, "intake") or {}
    es_params = first_call(text, "exhaust_system_parameters") or {}

    exhausts = []
    for ex in all_calls(text, "exhaust_system"):
        exhausts.append({k: clean_expr(v) for k, v in ex.items()})

    # head chamber volume often in generic_cylinder_head / generic_small_engine_head
    # (may live in a same-folder import like radial.mr → radial_head).
    head = (
        first_call(text, "generic_cylinder_head")
        or first_call(text, "generic_small_engine_head")
        or first_call(imported, "generic_cylinder_head")
        or first_call(imported, "generic_small_engine_head")
        or {}
    )
    head = {k: clean_expr(v) for k, v in head.items()}
    cv = head.get("chamber_volume")
    if not cv or cv == "chamber_volume":
        m_cv = re.search(
            r"input\s+chamber_volume\s*:\s*([^;\n]+)",
            combined,
        ) or re.search(
            r"chamber_volume\s*:\s*([0-9.]+\s*\*\s*units\.cc)",
            combined,
        )
        if m_cv:
            head["chamber_volume"] = clean_expr(m_cv.group(1))

    cam_lobe = first_call(text, "harmonic_cam_lobe") or first_call(imported, "harmonic_cam_lobe") or {}

    # ignition
    ign_mod = first_call(text, "ignition_module")  # rare
    timing = extract_timing_curve(text)
    rev_limit = None
    for m in re.finditer(r"rev_limit\s*:\s*([^,\n)]+)", text):
        rev_limit = clean_expr(m.group(1))

    # fuel nested in engine()
    fuel = {}
    if "fuel" in eng:
        fm = re.match(r"fuel\s*\((.*)\)\s*$", eng["fuel"], re.S)
        if fm:
            fuel = {k: clean_expr(v) for k, v in kv_pairs(fm.group(1)).items()}

    identity = {
        "name": name,
        "redline": clean_expr(eng["redline"]) if "redline" in eng else None,
        "starter_torque": clean_expr(eng["starter_torque"])
        if "starter_torque" in eng
        else None,
        "starter_speed": clean_expr(eng["starter_speed"])
        if "starter_speed" in eng
        else None,
        "simulation_frequency": clean_expr(eng["simulation_frequency"])
        if "simulation_frequency" in eng
        else None,
        "throttle_gamma": clean_expr(eng["throttle_gamma"])
        if "throttle_gamma" in eng
        else None,
        "hf_gain": clean_expr(eng.get("hf_gain", "")) or None,
        "noise": clean_expr(eng.get("noise", "")) or None,
        "jitter": clean_expr(eng.get("jitter", "")) or None,
    }
    # drop empty Nones later in flatten? keep structure

    flow_samples = extract_flow_samples(text, "flow")

    layout = infer_layout(bank_angles, n_cyl, len(banks))

    return {
        "id": rel.replace("/", "__").replace(".mr", "").replace(".MR", ""),
        "source": rel,
        "skipped": False,
        "identity": {k: v for k, v in identity.items() if v},
        "labels": labels,
        "layout": layout,
        "n_cylinders": n_cyl,
        "n_banks": len(banks),
        "crank": {k: clean_expr(v) for k, v in crank.items()},
        "journals": journals,
        "banks": banks,
        "bank_params": {k: clean_expr(v) for k, v in bank_params.items()},
        "piston": {k: clean_expr(v) for k, v in piston.items()},
        "connecting_rod": {k: clean_expr(v) for k, v in rod.items()},
        "intake": {k: clean_expr(v) for k, v in intake.items()},
        "exhaust_params": {k: clean_expr(v) for k, v in es_params.items()},
        "exhaust_systems": exhausts,
        "head": head,
        "cam_lobe": {k: clean_expr(v) for k, v in cam_lobe.items()},
        "fuel": fuel,
        "ignition": {
            "rev_limit": rev_limit,
            "timing_curve": timing,
        },
        "flow_samples_count": len(flow_samples),
        "raw_engine_keys": sorted(eng.keys()),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--root",
        type=Path,
        default=DEFAULT_ROOT,
        help="engine-sim repo root",
    )
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT, help="output JSON")
    args = ap.parse_args()
    root: Path = args.root.resolve()
    engines_dir = root / "assets" / "engines"
    if not engines_dir.is_dir():
        print(f"missing {engines_dir}", file=sys.stderr)
        return 1

    files = sorted(engines_dir.rglob("*.mr")) + sorted(engines_dir.rglob("*.MR"))
    # dedupe
    seen = set()
    uniq = []
    for f in files:
        rp = f.resolve()
        if rp in seen:
            continue
        seen.add(rp)
        uniq.append(f)

    engines = []
    skipped = 0
    for f in uniq:
        try:
            rec = parse_engine_file(f, root)
        except Exception as e:  # noqa: BLE001
            rec = {
                "id": str(f),
                "source": str(f.relative_to(root)) if f.is_relative_to(root) else str(f),
                "skipped": True,
                "reason": f"parse error: {e}",
            }
        if rec.get("skipped"):
            skipped += 1
        engines.append(rec)

    # Prefer non-skipped first for default picks
    active = [e for e in engines if not e.get("skipped")]
    default_id = None
    for prefer in ("Suzuki Hayabusa I4", "Honda B18C5 [VTEC, I4]", "Kohler CH750"):
        for e in active:
            if e.get("identity", {}).get("name") == prefer:
                default_id = e["id"]
                break
        if default_id:
            break
    if not default_id and active:
        default_id = active[0]["id"]

    payload = {
        "meta": {
            "source_root": str(root),
            "engine_count": len(active),
            "skipped_count": skipped,
            "file_count": len(uniq),
            "default_id": default_id,
            "attribution": "Parameters extracted from Ange Yaghi Engine Simulator (.mr). MIT. Not for engineering/tuning accuracy.",
        },
        "engines": engines,
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {args.out} ({len(active)} engines, {skipped} skipped)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
