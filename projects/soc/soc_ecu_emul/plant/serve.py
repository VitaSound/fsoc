#!/usr/bin/env python3
"""Realtime plant server: SSE telemetry + static viz UI.

  cd plant && python3 serve.py
  open http://127.0.0.1:8765/
"""
from __future__ import annotations

import json
import math
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
VIZ = ROOT / "viz"
sys.path.insert(0, str(ROOT))

from engine import EnginePlant  # noqa: E402

HOST = "127.0.0.1"
PORT = 8765


class Sim:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.eng = EnginePlant(stroke="4T", n_cyl=1, rpm=1200.0, load_nm=5.0)
        self.eng.apply_actuators(2200.0, 15.0)
        self.target_rpm = 1200.0
        self.layout = "inline"  # inline | v60 | v90 | boxer — схема; тайминг even-fire
        self.angle = 0.0
        self.cycle_ang = 0.0  # 0…cycle_deg (720 for 4T, 360 for 2T)
        self.sparks = 0
        self.sync = True
        self.spark_events: list[dict] = []
        self.running = True
        self.hz = 240.0  # physics rate — denser steps at high RPM

    def apply_preset(self, name: str) -> None:
        e = self.eng
        if name == "idle":
            e.stroke, e.n_cyl = "4T", 1
            self.layout = "inline"
            self.target_rpm = 900.0
            e.load_nm, e.map_kpa = 3.0, 45.0
            e.apply_actuators(1800.0, 12.0)
        elif name == "cruise":
            e.stroke, e.n_cyl = "4T", 4
            self.layout = "inline"
            self.target_rpm = 2800.0
            e.load_nm, e.map_kpa = 8.0, 70.0
            e.apply_actuators(2400.0, 22.0)
        elif name == "stress2t":
            e.stroke, e.n_cyl = "2T", 1
            self.layout = "inline"
            self.target_rpm = 15000.0
            e.load_nm, e.map_kpa = 4.0, 90.0
            e.apply_actuators(1600.0, 18.0)
        elif name == "v8":
            e.stroke, e.n_cyl = "4T", 8
            self.layout = "v90"  # классический V8
            self.target_rpm = 6000.0
            e.load_nm, e.map_kpa = 12.0, 85.0
            e.apply_actuators(2000.0, 28.0)
        elif name == "v12":
            e.stroke, e.n_cyl = "4T", 12
            self.layout = "v60"  # типичный V12
            self.target_rpm = 7000.0
            e.load_nm, e.map_kpa = 14.0, 88.0
            e.apply_actuators(1900.0, 30.0)
        e.rpm = self.target_rpm
        self.cycle_ang = 0.0

    def snapshot(self) -> dict:
        with self.lock:
            ev = self.spark_events
            self.spark_events = []
            return {
                "rpm": self.eng.rpm,
                "angle": self.angle % 360.0,
                "stroke": self.eng.stroke,
                "n_cyl": self.eng.n_cyl,
                "layout": self.layout,
                "target_rpm": self.target_rpm,
                "btdc": self.eng.last_btdc,
                "pw_us": self.eng.last_pw_us,
                "map_kpa": self.eng.map_kpa,
                "load_nm": self.eng.load_nm,
                "sparks": self.sparks,
                "sync": self.sync,
                "spark_events": ev,
            }

    @staticmethod
    def _crossed(a0: float, a1: float, mark: float, cycle: float) -> bool:
        """True if angle advanced from a0→a1 (mod cycle) and passed mark."""
        if a1 >= a0:
            return a0 <= mark < a1
        # wrapped past 0
        return mark >= a0 or mark < a1

    def tick(self, dt: float) -> None:
        with self.lock:
            e = self.eng
            # Viz governor: hold near target, load pulls RPM down a bit
            sag = 1.0 - min(0.45, e.load_nm / 80.0)
            want = self.target_rpm * sag * (0.85 + 0.15 * (e.map_kpa / 100.0))
            e.rpm += (want - e.rpm) * min(1.0, 3.0 * dt)
            e.rpm = max(400.0, min(22000.0, e.rpm))
            e.t += dt

            dtheta = e.rpm * 360.0 * dt / 60.0
            self.angle = (self.angle + dtheta) % 360.0
            cycle = float(e.cycle_deg())
            n = max(1, e.n_cyl)
            prev = self.cycle_ang
            # Sub-step if we would jump more than ~half a fire spacing
            # (high RPM / many cyl) so we don't skip sparks.
            spacing = cycle / n
            steps = max(1, int(dtheta / max(1.0, spacing * 0.45)) + 1)
            step_d = dtheta / steps
            ang = prev
            for _ in range(steps):
                a0 = ang
                ang = (ang + step_d) % cycle
                for i in range(n):
                    tdc = (i * cycle) / n
                    fire = (tdc - e.last_btdc) % cycle
                    if self._crossed(a0, ang, fire, cycle):
                        self.sparks += 1
                        self.spark_events.append({"ch": i, "angle": fire})
            self.cycle_ang = ang


SIM = Sim()


def physics_loop() -> None:
    t0 = time.perf_counter()
    while SIM.running:
        t1 = time.perf_counter()
        dt = min(0.05, max(0.001, t1 - t0))
        t0 = t1
        SIM.tick(dt)
        time.sleep(1.0 / SIM.hz)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("[%s] %s\n" % (self.log_date_time_string(), fmt % args))

    def _send(self, code: int, body: bytes, ctype: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path in ("/", "/index.html"):
            self._send(200, (VIZ / "index.html").read_bytes(), "text/html; charset=utf-8")
            return
        if path == "/app.js":
            self._send(200, (VIZ / "app.js").read_bytes(), "application/javascript; charset=utf-8")
            return
        if path == "/style.css":
            self._send(200, (VIZ / "style.css").read_bytes(), "text/css; charset=utf-8")
            return
        if path == "/api/state":
            body = json.dumps(SIM.snapshot()).encode()
            self._send(200, body, "application/json")
            return
        if path == "/api/stream":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.end_headers()
            try:
                while SIM.running:
                    payload = json.dumps(SIM.snapshot())
                    self.wfile.write(f"data: {payload}\n\n".encode())
                    self.wfile.flush()
                    time.sleep(1.0 / 30.0)
            except (BrokenPipeError, ConnectionResetError):
                return
            return
        self._send(404, b"not found", "text/plain")

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path != "/api/control":
            self._send(404, b"not found", "text/plain")
            return
        n = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(n) if n else b"{}"
        try:
            data = json.loads(raw.decode() or "{}")
        except json.JSONDecodeError:
            self._send(400, b"bad json", "text/plain")
            return
        with SIM.lock:
            if "preset" in data:
                SIM.apply_preset(str(data["preset"]))
            e = SIM.eng
            if "stroke" in data:
                s = str(data["stroke"]).upper()
                if s in ("2T", "4T"):
                    e.stroke = s
                    SIM.cycle_ang = 0.0
            if "n_cyl" in data:
                e.n_cyl = max(1, min(16, int(data["n_cyl"])))
                SIM.cycle_ang = 0.0
            if "layout" in data:
                lay = str(data["layout"]).lower()
                if lay == "v":
                    lay = "v90"
                if lay in ("inline", "v60", "v90", "boxer"):
                    SIM.layout = lay
            if "target_rpm" in data:
                SIM.target_rpm = max(400.0, min(22000.0, float(data["target_rpm"])))
            if "btdc" in data or "pw_us" in data:
                btdc = float(data["btdc"]) if "btdc" in data else e.last_btdc
                pw = float(data["pw_us"]) if "pw_us" in data else e.last_pw_us
                e.apply_actuators(pw, btdc)
            if "load_nm" in data:
                e.load_nm = float(data["load_nm"])
            if "map_kpa" in data:
                e.map_kpa = float(data["map_kpa"])
        self._send(200, b'{"ok":true}', "application/json")


def main() -> None:
    threading.Thread(target=physics_loop, daemon=True).start()
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"FPGA-ECU viz: http://{HOST}:{PORT}/")
    print("  presets: idle / cruise / stress2t / v8 / v12")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        SIM.running = False
        print("\nstop")


if __name__ == "__main__":
    main()
