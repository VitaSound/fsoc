# engine-sim browser catalog (этап 1)

Каталог моторов из локального клона [engine-sim](../../../../../../../engine-sim): параметры из `.mr` + отрисовка **их** кодом/мешами. **Без** физики, ЭБУ и ДПКВ.

## Как рисуем

Не переписываем геометрию «на глаз». Цепочка:

1. Меши `Piston` / `ConnectingRod` / `Crankshaft` / `CylinderHead` / `Valve` / … — из `engine-sim/assets/assets.ysce` (`native/extract_ysce_meshes.py` → `native/meshes/meshes.json`).
2. C++ `native/engine_draw` — адаптированные формулы из `*_object.cpp` + `geometry_generator` (line/circle/cam), transforms как `simulation_object::setTransform`.
3. Python `native/draw_bridge.py` вызывает бинарник; `serve_catalog.py` отдаёт `/api/draw` и `/api/meshes`.
4. Браузер только красит drawlist (`catalog/paint_drawlist.js`).

## Быстрый старт

```bash
cd /home/sea/fsoc/projects/soc/soc_ecu_emul/plant

python3 tools/parse_engines.py

cd viz/native
python3 extract_ysce_meshes.py          # один раз / после обновления assets.ysce
g++ -O2 -std=c++17 -o engine_draw src/engine_draw.cpp

cd .. && python3 serve_catalog.py
# → http://127.0.0.1:8765/
```

Или из корня проекта: `make viz` (после ручной сборки `engine_draw`).

## Файлы

| Путь | Назначение |
|------|------------|
| `tools/parse_engines.py` | `.mr` → `viz/engines.json` |
| `viz/native/engine_draw` | C++ drawer (engine-sim objects) |
| `viz/native/draw_bridge.py` | Python → C++ |
| `viz/native/meshes/` | меши из `assets.ysce` |
| `viz/catalog/` | UI |
| `viz/serve_catalog.py` | static + `/api/draw` |

## Attribution

Параметры и меши — Engine Simulator (Ange Yaghi), MIT. Не для тюнинга/инженерии.
