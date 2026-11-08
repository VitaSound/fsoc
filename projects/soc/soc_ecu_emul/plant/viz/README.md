# engine-sim browser catalog

Каталог моторов из локального клона [engine-sim](../../../../../../../engine-sim): параметры из `.mr` + отрисовка по формулам/мешам esim.  
**Сейчас:** кинематический 2D-разрез (без physics / звука / дашборда Ange).

Карта + roadmap (steam kb): `../../../../../../steam/kb/engine-sim-catalog.md`  
(если клон рядом: `/home/sea/steam/kb/engine-sim-catalog.md`).

## Как рисуем

1. Меши — из `engine-sim/assets/assets.ysce` → `native/meshes/meshes.json`.
2. Параметры — `tools/parse_engines.py` → `engines.json` (`flip_display`, `add_lobe`, cam lobe…).
3. `serve_catalog.py` — статика + `/api/scene` + `/api/meshes`.
4. Браузер: `engine_draw_runtime.js` считает drawlist каждый кадр; `paint_drawlist.js` красит canvas.

C++ `native/engine_draw` — тот же набор формул (проверка / запасной путь), не на каждый RAF.

## Быстрый старт

```bash
cd /home/sea/fsoc/projects/soc/soc_ecu_emul/plant

python3 tools/parse_engines.py

cd viz/native
python3 extract_ysce_meshes.py   # один раз / после обновления assets.ysce
g++ -O2 -std=c++17 -o engine_draw src/engine_draw.cpp

cd .. && python3 serve_catalog.py
# → http://127.0.0.1:8765/
```

## Файлы

| Путь | Назначение |
|------|------------|
| `tools/parse_engines.py` | `.mr` → `viz/engines.json` |
| `viz/serve_catalog.py` | HTTP :8765 |
| `viz/catalog/` | UI + локальная анимация |
| `viz/native/draw_bridge.py` | сцена для `/api/scene` |
| `viz/native/meshes/` | меши из `assets.ysce` |

## UI сейчас

- Список моторов, параметры из `.mr`
- Разрез: коленвал / шатуны / поршни / клапаны / кулачки
- Пауза (Space), zoom колесом, dblclick — сброс zoom
- Вращение по часовой

## TODO (кратко → полный esim-like UI)

1. **IGNITION circles** — поджиг свечей по порядку цилиндров  
2. **Зажигание + дроссель / RPM** — управление оборотами, связь с plant  
3. **Звук** — MVP от событий / RPM, затем ближе к esim exhaust  
4. **Дашборд** — тахо, MAP/AFR, осциллограммы, остальные панели Ange  

Детали чеклиста — в `steam/kb/engine-sim-catalog.md`.

## Attribution

Параметры и меши — Engine Simulator (Ange Yaghi), MIT. Не для тюнинга/инженерии.
