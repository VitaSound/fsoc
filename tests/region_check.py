#!/usr/bin/env python3
"""A spiflash region sits beside the bit devices and is not a boot ROM."""
import json
import sys

j = json.load(open("csr.json", encoding="utf-8"))
regs = j["regions"]
if len(regs) != 1:
    sys.exit("count")
r = regs[0]
if r.get("name") != "spiflash":
    sys.exit("name")
if r.get("base") != 0x10000 or r.get("size") != 4194304 or r.get("mode") != "ro":
    sys.exit("fields")
if set(r) != {"name", "base", "size", "mode"}:
    sys.exit("shape")
names = [x["name"] for x in regs]
if "rom" in names or "main_ram" in names:
    sys.exit("reserved")
led = next(d for d in j["devices"] if d["name"] == "led")
if led.get("addr") != 0x400 or "bit" not in led:
    sys.exit("led")
sys.exit(0)
