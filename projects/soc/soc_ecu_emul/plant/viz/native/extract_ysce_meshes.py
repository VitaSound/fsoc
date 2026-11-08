#!/usr/bin/env python3
"""Extract engine-sim DrawModel meshes from assets/assets.ysce (delta CompiledHeader).

Format (delta-studio AssetManager::LoadSceneFile / ysGeometryExportFile):
  int ObjectCount
  ObjectOutputHeader (252 bytes packed) + vertex bytes + uint16 indices * faces*3
  Vertex stride 40: px,py,pz,1, u,v, nx,ny,nz,0
"""
from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path

HEADER_SIZE = 252
DEFAULT_YSCE = Path("/home/sea/engine-sim/assets/assets.ysce")
KEEP = (
    "Crankshaft",
    "ConnectingRod",
    "Piston",
    "CylinderHead",
    "Valve",
    "CrankSnout",
    "CrankSnoutThreads",
)


def extract(ysce: Path) -> dict:
    data = ysce.read_bytes()
    n_obj = struct.unpack_from("<i", data, 0)[0]
    off = 4
    out: dict = {}
    for _ in range(n_obj):
        name = data[off : off + 64].split(b"\x00", 1)[0].decode()
        o = off + 128
        _mi, _pi, _pii, _si, _otype = struct.unpack_from("<5i", data, o)
        o += 20
        o += 12 + 12 + 16 + 12 + 12 + 12  # pos,euler,orient,scale,min,max
        _nuv, n_v, n_f = struct.unpack_from("<3i", data, o)
        o += 12
        n_bones, _mb = struct.unpack_from("<2i", data, o)
        o += 8
        _flags, vsize = struct.unpack_from("<Ii", data, o)
        o += 8
        assert o - off == HEADER_SIZE
        stride = vsize // n_v if n_v else 0
        verts = []
        for vi in range(n_v):
            px, py, _pz, _pw = struct.unpack_from("<4f", data, o + vi * stride)
            verts.append([round(px, 6), round(py, 6)])
        ioff = o + vsize
        indices = list(struct.unpack_from(f"<{n_f * 3}H", data, ioff)) if n_f else []
        off = ioff + n_f * 3 * 2 + n_bones * 4
        key = "Valve" if name.startswith("Valve") else name
        if key in KEEP and key not in out:
            out[key] = {"vertices": verts, "indices": indices}
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ysce", type=Path, default=DEFAULT_YSCE)
    ap.add_argument(
        "-o",
        type=Path,
        default=Path(__file__).resolve().parent / "meshes" / "meshes.json",
    )
    args = ap.parse_args()
    meshes = extract(args.ysce)
    args.o.parent.mkdir(parents=True, exist_ok=True)
    args.o.write_text(json.dumps(meshes, separators=(",", ":")))
    print(f"wrote {args.o} models={list(meshes)}")


if __name__ == "__main__":
    main()
