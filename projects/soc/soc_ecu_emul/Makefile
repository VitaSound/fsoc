# Diploma FPGA-ECU stand (no engine hardware)

FSOC_ROOT := $(abspath ../../..)
RTL := $(FSOC_ROOT)/rtl
TB := tb

.PHONY: hdl-test stress-2t stress-v12 plant-demo contrast viz viz-legacy engines-json

hdl-test:
	cd $(TB) && iverilog -g2012 -o tb_ecu \
	  $(RTL)/trigger_36_1.v $(RTL)/angle_clock.v \
	  $(RTL)/spark_ch.v $(RTL)/inj_ch.v \
	  $(RTL)/ecu_csr.v $(RTL)/ecu_core.v \
	  tb_ecu_core.v && ./tb_ecu

stress-2t:
	cd plant && python3 stress_2t.py

stress-v12:
	cd plant && python3 stress_v12.py

plant-demo:
	cd plant && python3 hil.py

contrast:
	cd plant && python3 -c 'from hil import print_mcu_contrast; print_mcu_contrast()'

# Refresh engines.json from /home/sea/engine-sim
engines-json:
	cd plant && python3 tools/parse_engines.py

# Phase-1 catalog: params + native engine_draw (engine-sim meshes/objects)
viz-draw:
	cd plant/viz/native && python3 extract_ysce_meshes.py
	cd plant/viz/native && g++ -O2 -std=c++17 -o engine_draw src/engine_draw.cpp

# Phase-1 catalog UI: http://127.0.0.1:8765/
viz: engines-json viz-draw
	cd plant/viz && python3 serve_catalog.py

# Old realtime plant animation
viz-legacy:
	cd plant && python3 serve.py
