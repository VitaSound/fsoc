#!/usr/bin/env python3
"""Call native engine_draw (adapted engine-sim object code) from Python."""
from __future__ import annotations

import json
import math
import os
import re
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
BIN = ROOT / "engine_draw"
MESHES = ROOT / "meshes" / "meshes.json"


def _to_mm(expr: Any, labels: dict) -> float | None:
    if expr is None or expr == "":
        return None
    s = str(expr).trim() if False else str(expr).strip()
    for k, v in labels.items():
        s = s.replace(k, f"({v})")
    for a, b in (
        ("units.mm", "1"),
        ("units.cm", "10"),
        ("units.inch", "25.4"),
        ("units.thou", "0.0254"),
        ("units.m", "1000"),
        ("units.cc", "1"),
        ("constants.pi", "math.pi"),
    ):
        s = s.replace(a, b)
    import re

    s = re.sub(r"units\.[A-Za-z0-9_]+", "1", s)
    try:
        v = eval(s, {"math": math, "__builtins__": {}}, {})
        return float(v) if math.isfinite(v) else None
    except Exception:
        return None


def _to_rad(expr: Any, labels: dict) -> float | None:
    if expr is None:
        return None
    if isinstance(expr, (int, float)):
        return float(expr) * math.pi / 180.0
    s = str(expr).strip()
    for k, v in labels.items():
        s = s.replace(k, f"({v})")
    if "units.deg" in s:
        s = s.replace("units.deg", "1").replace("constants.pi", "math.pi")
        try:
            return float(eval(s, {"math": math, "__builtins__": {}}, {})) * math.pi / 180.0
        except Exception:
            return None
    s = s.replace("constants.pi", "math.pi")
    try:
        return float(eval(s, {"math": math, "__builtins__": {}}, {}))
    except Exception:
        return None


def engine_to_draw_input(engine: dict, crank_angle: float = 0.0) -> dict:
    labels = engine.get("labels") or {}
    bore = _to_mm(engine.get("bank_params", {}).get("bore"), labels) or _to_mm(labels.get("bore"), labels) or 80.0
    throw = _to_mm(engine.get("crank", {}).get("throw"), labels)
    if throw is None and labels.get("stroke"):
        st = _to_mm(labels.get("stroke"), labels)
        if st is not None:
            throw = st / 2
    throw = throw or 35.0
    slave_throw = _to_mm(labels.get("slave_throw"), labels)
    rod_label = _to_mm(labels.get("rod_length"), labels)
    rod_params = _to_mm(engine.get("connecting_rod", {}).get("length"), labels)
    # Radial: cr_params.length is often (rod_length - slave_throw) for slaves;
    # master / deck use full rod_length. Prefer label when slave_throw is set.
    if slave_throw and rod_label:
        rod = rod_label
        slave_rod = max(1.0, rod_label - slave_throw)
    else:
        rod = rod_params or rod_label or throw * 3.2
        slave_rod = rod
        slave_throw = None
    comp_h = (
        _to_mm(engine.get("piston", {}).get("compression_height"), labels)
        or _to_mm(labels.get("compression_height"), labels)
        or bore * 0.35
    )
    wrist = _to_mm(engine.get("piston", {}).get("wrist_pin_position"), labels) or 0.0
    deck = _to_mm(engine.get("bank_params", {}).get("deck_height"), labels) or (throw + rod + comp_h)
    # Chamber volume in cc from head.chamber_volume (parser resolves imports / input defaults).
    chamber_vol = 40.0
    cv_expr = (engine.get("head") or {}).get("chamber_volume")
    if cv_expr:
        v = _to_mm(cv_expr, labels)
        if v is not None and v > 0:
            chamber_vol = v
    bore_m = bore / 1000.0
    chamber_h = (chamber_vol * 1e-6) / (math.pi * bore_m * bore_m / 4.0) * 1000.0
    cam_lobe = engine.get("cam_lobe") or {}
    cam_lift = _to_mm(cam_lobe.get("lift"), labels) or bore * 0.08
    # harmonic_cam_lobe: duration is crank-space (÷4 → half-angle in cam rad).
    cam_duration = _to_rad(cam_lobe.get("duration_at_50_thou"), labels) or (
        220.0 * math.pi / 180.0
    )
    try:
        cam_gamma = float(str(cam_lobe.get("gamma") or "1").split()[0])
    except (TypeError, ValueError):
        cam_gamma = 1.0
    if cam_gamma <= 0:
        cam_gamma = 1.0
    timing = engine.get("cam_timing") or {}
    # Prefer camshaft base_radius from .mr; cam_lobe rarely has it.
    cam_base = (
        _to_mm(timing.get("base_radius"), labels)
        or _to_mm(engine.get("cam_lobe", {}).get("base_radius"), labels)
        or bore * 0.15
    )
    # labels.cycle: "2 * 360 * units.deg" → 4-stroke (cam half speed); 360 → 2-stroke (1:1)
    cam_ratio = 0.5
    cycle_expr = labels.get("cycle") or engine.get("cycle")
    if cycle_expr:
        try:
            nums = [float(x) for x in re.findall(r"[\d.]+", str(cycle_expr).split("units")[0])]
            cycle_deg = 1.0
            for n in nums:
                cycle_deg *= n
            if cycle_deg > 0 and cycle_deg < 500:
                cam_ratio = 1.0
        except (TypeError, ValueError):
            pass

    # Lobe centers: .mr add_lobe(crank) → Camshaft::setLobeCenterline stores crank/2.
    # Per-bank first lobe from parser (firing-order offsets); fallback rot360±LCA.
    timing_labels = dict(labels)
    for k, v in timing.items():
        timing_labels[k] = v
    lsa = _to_rad(timing.get("lobe_separation") or "110 * units.deg", timing_labels)
    if lsa is None:
        lsa = 110.0 * math.pi / 180.0
    intake_crank = _to_rad(timing.get("intake_lobe_center"), timing_labels)
    exhaust_crank = _to_rad(timing.get("exhaust_lobe_center"), timing_labels)
    if intake_crank is None:
        intake_crank = lsa
    if exhaust_crank is None:
        exhaust_crank = lsa
    twopi = 2.0 * math.pi
    intake_lobe_cam = (twopi + intake_crank) / 2.0
    exhaust_lobe_cam = (twopi - exhaust_crank) / 2.0
    cam_advance = _to_rad(timing.get("advance"), timing_labels) or 0.0

    banks = engine.get("banks") or []
    intake_lobe_cam_banks: list[float] = []
    exhaust_lobe_cam_banks: list[float] = []
    for b in banks:
        ic_deg = b.get("intake_lobe_crank_deg")
        ec_deg = b.get("exhaust_lobe_crank_deg")
        if ic_deg is not None:
            intake_lobe_cam_banks.append(float(ic_deg) * math.pi / 180.0 / 2.0)
        else:
            intake_lobe_cam_banks.append(intake_lobe_cam)
        if ec_deg is not None:
            exhaust_lobe_cam_banks.append(float(ec_deg) * math.pi / 180.0 / 2.0)
        else:
            exhaust_lobe_cam_banks.append(exhaust_lobe_cam)
    if intake_lobe_cam_banks:
        intake_lobe_cam = intake_lobe_cam_banks[0]
    if exhaust_lobe_cam_banks:
        exhaust_lobe_cam = exhaust_lobe_cam_banks[0]
    bank_angles: list[float] = []
    bank_cylinders: list[int] = []
    bank_display_depths: list[float] = []
    # Flat list matching draw order (bank0 cyls, bank1 cyls, …).
    # layer = ConnectingRod::getLayer() (crank journal index; slaves → master).
    cylinder_journals: list[int] = []
    cylinder_mounts: list[dict] = []
    # Script default (cylinder_bank_parameters.display_depth), not C++ ctor 0.4
    params_dd = 0.5
    bp = engine.get("bank_params") or {}
    if bp.get("display_depth") not in (None, ""):
        try:
            params_dd = float(str(bp["display_depth"]).split()[0])
        except (TypeError, ValueError):
            pass

    def _journal_angle(j: dict) -> float:
        # Prefer expr (angle_deg may be stale if parser once multiplied nums)
        if j.get("angle_expr"):
            r = _to_rad(j["angle_expr"], labels)
            if r is not None:
                return r
        if j.get("angle_deg") is not None:
            return float(j["angle_deg"]) * math.pi / 180.0
        return 0.0

    raw_journals = engine.get("journals") or []
    crank_js = [j for j in raw_journals if j.get("role") != "slave"]
    slave_js = [j for j in raw_journals if j.get("role") == "slave"]
    # If roles missing (old JSON), treat all as crank journals
    if not crank_js and raw_journals:
        crank_js = list(raw_journals)
        slave_js = []

    for i, b in enumerate(banks):
        ang = None
        if b.get("angle_expr"):
            ang = _to_rad(b["angle_expr"], labels)
        if ang is None and b.get("angle_deg") is not None:
            ang = float(b["angle_deg"]) * math.pi / 180.0
        bank_angles.append(ang or 0.0)
        n = int(b.get("cylinders") or 0)
        bank_cylinders.append(n)
        dd = b.get("display_depth")
        if dd is None:
            dd = params_dd
        bank_display_depths.append(float(dd))
        mounts = b.get("mounts")
        idxs = b.get("journal_indices")
        if isinstance(mounts, list) and len(mounts) == n and n > 0:
            for mnt in mounts:
                role = mnt.get("role") or "crank"
                idx = int(mnt.get("index") or 0)
                layer = 0 if role == "slave" else idx
                cylinder_journals.append(layer)
                cylinder_mounts.append({"role": role, "index": idx, "layer": layer})
        elif isinstance(idxs, list) and len(idxs) == n and n > 0:
            for ji in idxs:
                ji = int(ji)
                cylinder_journals.append(ji)
                cylinder_mounts.append({"role": "crank", "index": ji % max(1, len(crank_js) or 1), "layer": ji})
        else:
            n_j = max(1, len(crank_js) or n or 1)
            for c in range(n):
                cylinder_journals.append(c % n_j)
                cylinder_mounts.append({"role": "crank", "index": c % n_j, "layer": c % n_j})
    if len(bank_angles) == 2 and all(abs(a) < 1e-9 for a in bank_angles):
        bank_angles = [-math.pi / 4, math.pi / 4]
    if not bank_angles:
        bank_angles = [0.0]
        bank_cylinders = [int(engine.get("n_cylinders") or 1)]
        bank_display_depths = [params_dd]
        cylinder_journals = list(range(bank_cylinders[0]))
        cylinder_mounts = [
            {"role": "crank", "index": i, "layer": i} for i in range(bank_cylinders[0])
        ]

    journals = [_journal_angle(j) for j in crank_js]
    slave_journals = [_journal_angle(j) for j in slave_js]
    if not journals:
        journals = [0.0] * max(1, sum(bank_cylinders))
        cylinder_journals = list(range(sum(bank_cylinders)))
        cylinder_mounts = [
            {"role": "crank", "index": i, "layer": i} for i in range(sum(bank_cylinders))
        ]

    out = {
        "bore": bore,
        "throw": throw,
        "rod": rod,
        "comp_h": comp_h,
        "wrist_pin": wrist,
        "deck": deck,
        "chamber_h": chamber_h,
        "cam_base": cam_base,
        "cam_lift": cam_lift,
        "cam_duration": cam_duration,
        "cam_gamma": cam_gamma,
        "cam_ratio": cam_ratio,
        "cam_advance": cam_advance,
        "intake_lobe_cam": intake_lobe_cam,
        "exhaust_lobe_cam": exhaust_lobe_cam,
        "intake_lobe_cam_banks": intake_lobe_cam_banks or [intake_lobe_cam],
        "exhaust_lobe_cam_banks": exhaust_lobe_cam_banks or [exhaust_lobe_cam],
        "bank_angles": bank_angles,
        "bank_cylinders": bank_cylinders,
        "bank_display_depths": bank_display_depths,
        "journals": journals,
        "cylinder_journals": cylinder_journals,
        "cylinder_mounts": cylinder_mounts,
        # CylinderHead::FlipDisplay from .mr per bank (esim default false).
        "flip_display": [
            (
                1
                if i < len(banks)
                and (banks[i].get("flip_display") is True or banks[i].get("flip_display") == 1)
                else 0
            )
            for i in range(len(bank_angles))
        ],
        "crank_angle": crank_angle,
        "meshes_path": str(MESHES),
    }
    if slave_throw is not None:
        out["slave_throw"] = slave_throw
        out["slave_rod"] = slave_rod
        out["slave_journals"] = slave_journals
    return out


def draw(engine: dict, crank_angle: float = 0.0) -> dict:
    if not BIN.is_file():
        raise FileNotFoundError(f"missing {BIN} — build with: g++ -O2 -std=c++17 -o native/engine_draw native/src/engine_draw.cpp")
    payload = json.dumps(engine_to_draw_input(engine, crank_angle))
    proc = subprocess.run(
        [str(BIN)],
        input=payload.encode(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.decode() or f"engine_draw exit {proc.returncode}")
    return json.loads(proc.stdout.decode())


def load_meshes() -> dict:
    return json.loads(MESHES.read_text())


if __name__ == "__main__":
    import sys

    engines = json.loads(Path(__file__).resolve().parents[1].joinpath("engines.json").read_text())
    name = sys.argv[1] if len(sys.argv) > 1 else "Kohler"
    eng = next(e for e in engines["engines"] if name.lower() in (e.get("identity") or {}).get("name", e.get("id", "")).lower())
    out = draw(eng, 0.4)
    print(json.dumps({"n": len(out["commands"]), "ops": list({c["op"] for c in out["commands"]})}))
