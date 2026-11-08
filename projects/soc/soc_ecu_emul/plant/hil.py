"""
Python HIL helpers.

1) Reference angle/spark model (mirrors HDL intent) for closed-loop plant.
2) run_hdl_tb() invokes iverilog self-check (authoritative for diploma timing).
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from crank import Crank36_1
from engine import EnginePlant
from metrics import Metrics, mcu_isr_budget

# plant/ -> soc_ecu_emul -> soc -> projects -> fsoc
ROOT = Path(__file__).resolve().parents[1]
FSOC = Path(__file__).resolve().parents[4]
RTL = FSOC / "rtl"
TB = ROOT / "tb"


def run_hdl_tb() -> int:
    tb_dir = ROOT / "tb"
    srcs = [
        RTL / "trigger_36_1.v",
        RTL / "angle_clock.v",
        RTL / "spark_ch.v",
        RTL / "inj_ch.v",
        RTL / "ecu_csr.v",
        RTL / "ecu_core.v",
        tb_dir / "tb_ecu_core.v",
    ]
    out = tb_dir / "tb_ecu"
    cmd = ["iverilog", "-g2012", "-o", str(out)] + [str(s) for s in srcs]
    print("+", " ".join(cmd))
    subprocess.check_call(cmd, cwd=tb_dir)
    r = subprocess.run([str(out)], cwd=tb_dir)
    return r.returncode


def closed_loop_demo(
    stroke: str = "4T",
    n_cyl: int = 1,
    seconds: float = 2.0,
    btdc: float = 15.0,
    pw_us: float = 2000.0,
) -> Metrics:
    """Simple closed-loop: plant RPM drives crank; sparks assumed on schedule."""
    eng = EnginePlant(stroke=stroke, n_cyl=n_cyl, rpm=1500.0)
    eng.apply_actuators(pw_us, btdc)
    m = Metrics()
    dt = 0.0005
    t = 0.0
    cycle = eng.cycle_deg()
    sparks_expected = 0
    last_fire_slot = -1
    while t < seconds:
        crank = Crank36_1(rpm=eng.rpm)
        # one dt of physics; count scheduled fires
        fires = eng.fires_per_rev() * (eng.rpm / 60.0) * dt
        sparks_expected += fires
        # nominal fire angle for cyl0
        exp = (cycle - btdc) % cycle
        # credit spark if we're near that angle in the revolution fraction
        rev_frac = (t * eng.rpm / 60.0) % 1.0
        ang = rev_frac * 360.0  # crank degrees this rev
        if stroke.upper() == "4T":
            ang = (t * eng.rpm / 60.0 * 360.0) % cycle
        slot = int(ang)
        if abs((slot - exp + cycle / 2) % cycle - cycle / 2) < 2:
            if slot != last_fire_slot:
                m.add_spark(t, float(exp), 0, exp)
                last_fire_slot = slot
        eng.step(dt, spark_ok=True)
        m.max_rpm = max(m.max_rpm, eng.rpm)
        t += dt
    m.expected_count = max(1, int(sparks_expected))
    m.sync_ok = True
    return m


def print_mcu_contrast() -> None:
    print("=== MCU ISR budget contrast (diploma) ===")
    for rpm in (2000, 8000, 15000, 20000):
        b = mcu_isr_budget(rpm)
        print(
            f"  {rpm:5d} RPM  tooth={b['tooth_hz']:.0f} Hz  "
            f"load={100*b['cpu_load_frac']:.1f}%  "
            f"early6°={b['early_window_6deg_us']:.0f} µs  "
            f"late_arm_risk={b['late_arm_risk']}"
        )


if __name__ == "__main__":
    print_mcu_contrast()
    rc = run_hdl_tb()
    print("HDL TB exit", rc)
    m = closed_loop_demo("2T", 1, 1.0)
    print("closed-loop 2T:", m.summary())
    sys.exit(rc)
