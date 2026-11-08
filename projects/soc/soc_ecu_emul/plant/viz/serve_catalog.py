#!/usr/bin/env python3
"""Static + draw API for the engine-sim browser catalog (phase 1).

Drawing: native/engine_draw (adapted engine-sim C++) via native/draw_bridge.py
Meshes:  native/meshes/meshes.json extracted from engine-sim assets.ysce

  cd plant && python3 tools/parse_engines.py
  cd plant/viz/native && g++ -O2 -std=c++17 -o engine_draw src/engine_draw.cpp
  cd plant/viz && python3 serve_catalog.py
"""
from __future__ import annotations

import json
import sys
import urllib.parse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOST = "127.0.0.1"
PORT = 8765
ROOT = Path(__file__).resolve().parent  # viz/
NATIVE = ROOT / "native"
sys.path.insert(0, str(NATIVE))

from draw_bridge import draw, engine_to_draw_input, load_meshes  # noqa: E402


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("[%s] %s\n" % (self.log_date_time_string(), fmt % args))

    def _json(self, code: int, obj: dict) -> None:
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)

        if path in ("/", "/index.html"):
            self.path = "/catalog/index.html"
            return super().do_GET()

        if path == "/api/meshes":
            try:
                return self._json(200, load_meshes())
            except Exception as e:
                return self._json(500, {"error": str(e)})

        if path == "/api/draw":
            # Old clients polled this every frame (spawn C++ → lag). Use /api/scene.
            return self._json(
                410,
                {"error": "deprecated: hard-refresh; animation is local via /api/scene"},
            )

        if path == "/api/scene":
            engines = json.loads((ROOT / "engines.json").read_text())
            eng_id = (qs.get("id") or [None])[0]
            eng = None
            for e in engines.get("engines") or []:
                if e.get("id") == eng_id or e.get("source") == eng_id:
                    eng = e
                    break
                name = (e.get("identity") or {}).get("name")
                if eng_id and name and eng_id.lower() in name.lower():
                    eng = e
                    break
            if eng is None:
                eng = next((e for e in engines["engines"] if not e.get("skipped")), None)
            if eng is None or eng.get("skipped"):
                return self._json(404, {"error": "engine not found"})
            try:
                return self._json(200, engine_to_draw_input(eng, 0.0))
            except Exception as e:
                return self._json(500, {"error": str(e)})

        return super().do_GET()


def main() -> None:
    engines = ROOT / "engines.json"
    if not engines.is_file():
        print("missing engines.json — run: python3 tools/parse_engines.py", file=sys.stderr)
        raise SystemExit(1)
    if not (NATIVE / "engine_draw").is_file():
        print("missing native/engine_draw — compile src/engine_draw.cpp", file=sys.stderr)
        raise SystemExit(1)
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"engine-sim catalog: http://{HOST}:{PORT}/")
    print(f"  draw: C++ native/engine_draw + meshes from assets.ysce")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nstop")


if __name__ == "__main__":
    main()
