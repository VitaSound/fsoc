# soc_ecu_emul — FPGA ECU stand (diploma)

**Thesis:** MCU aftermarket ECUs hit ISR walls on high-RPM 2-stroke and high cylinder counts; FPGA keeps trigger + angle clock + N× spark/inj in hardware. Soft-core **j1b** only runs tables → setpoints.

No real engine. Proof = HDL sim + Python plant metrics.

## Quick proof

```bash
make hdl-test      # 2k / 15k 2T / N=8 @ 6k — ALL PASSED
make stress-2t     # Stress A + MCU ISR contrast
make stress-v12    # Stress B multi-cyl
make contrast      # tooth-ISR budget table
make viz           # engine-sim catalog → http://127.0.0.1:8765/
make viz-legacy    # old realtime plant animation
```

## Layout

| Path | Role |
|------|------|
| `../../rtl/trigger_36_1.v` … `ecu_core.v` | HDL timing (param `N_CH`) |
| `tb/tb_ecu_core.v` | Icarus self-check |
| `plant/` | crank, MVEM, metrics, stress_*; **viz catalog** from engine-sim `.mr` |
| `plant/tools/parse_engines.py` | extract `.mr` → `viz/engines.json` |
| `plant/viz/catalog/` | browser catalog UI (phase 1) |
| `firmware/ecu_ctrl.fs` | j1b table-only ctrl (fsoc `ecu=1` option) |
| `target.4th` | fsoc project: j1b + ecu |

## KB

See `steam/kb/ice-ecu-fpga.md`.
