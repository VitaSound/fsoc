/** engine-sim catalog — meshes/params from server; draw loop fully local (no per-frame C++). */

import { loadMeshes, fetchScene, paintDrawlist } from "./paint_drawlist.js?v=6";
import { prepareScene, buildDrawlist, viewFromScene } from "./engine_draw_runtime.js?v=32";

const $ = (id) => document.getElementById(id);
const THEME = { background: "#0E1012" };

let catalog = null;
let selectedId = null;
let meshes = null;
let scene = null;
let crankAngle = 0.35;
let view = null;
let baseView = null;
let paused = false;

const ZOOM_MIN = 0.35;
const ZOOM_MAX = 8;

function setPaused(next) {
  paused = !!next;
  const btn = $("btn-pause");
  if (!btn) return;
  btn.setAttribute("aria-pressed", paused ? "true" : "false");
  btn.textContent = paused ? "▶ дальше" : "⏸ пауза";
}

/** Zoom view toward canvas bitmap point (sx, sy). */
function zoomAt(sx, sy, factor) {
  if (!view || !baseView) return;
  const next = Math.min(
    ZOOM_MAX,
    Math.max(ZOOM_MIN, (view.scale / baseView.scale) * factor)
  );
  const newScale = baseView.scale * next;
  const f = newScale / view.scale;
  view = {
    ...view,
    scale: newScale,
    cx: sx - (sx - view.cx) * f,
    cy: sy - (sy - view.cy) * f,
  };
}

function resetZoom() {
  if (!baseView) return;
  view = { ...baseView };
}

function engineName(e) {
  if (e.skipped) return `(skip) ${e.source}`;
  return e.identity?.name || e.id;
}

function engineTag(e) {
  if (e.skipped) return e.reason || "skipped";
  return `${e.layout || "?"} · ${e.n_cylinders || 0} cyl · ${e.n_banks || 0} bank`;
}

function flattenSection(obj) {
  if (!obj || typeof obj !== "object") return [];
  if (Array.isArray(obj)) {
    return obj.map((item, i) => ({
      key: String(i),
      value: typeof item === "object" ? JSON.stringify(item) : String(item),
    }));
  }
  return Object.entries(obj).map(([key, value]) => ({
    key,
    value:
      value == null
        ? ""
        : typeof value === "object"
          ? JSON.stringify(value)
          : String(value),
  }));
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function renderParams(e) {
  const root = $("params");
  if (e.skipped) {
    root.innerHTML = `<h2>skipped</h2><p class="empty">${e.reason || "no engine()"}</p>
      <h2>source</h2><table><tr><th>path</th><td>${escapeHtml(e.source)}</td></tr></table>`;
    return;
  }

  const sections = [
    ["identity", e.identity],
    ["labels", e.labels],
    ["layout", { layout: e.layout, n_cylinders: e.n_cylinders, n_banks: e.n_banks }],
    ["crank", e.crank],
    ["journals", e.journals],
    ["banks", e.banks],
    ["bank_params", e.bank_params],
    ["piston", e.piston],
    ["connecting_rod", e.connecting_rod],
    ["intake", e.intake],
    ["exhaust_params", e.exhaust_params],
    ["exhaust_systems", e.exhaust_systems],
    ["head", e.head],
    ["cam_lobe", e.cam_lobe],
    ["fuel", e.fuel],
    ["ignition", e.ignition],
    ["meta", { flow_samples_count: e.flow_samples_count, raw_engine_keys: e.raw_engine_keys }],
  ];

  let html = "";
  for (const [title, data] of sections) {
    const rows = flattenSection(data);
    html += `<h2>${title}</h2>`;
    if (!rows.length) {
      html += `<p class="empty">—</p>`;
      continue;
    }
    html += "<table>";
    for (const r of rows) {
      const v = r.value === "" ? `<span class="empty">—</span>` : escapeHtml(r.value);
      html += `<tr><th>${escapeHtml(r.key)}</th><td>${v}</td></tr>`;
    }
    html += "</table>";
  }
  root.innerHTML = html;
}

function paint() {
  const canvas = $("stage");
  const ctx = canvas.getContext("2d");
  const e = catalog?.engines?.find((x) => x.id === selectedId);
  const label = e && !e.skipped ? engineName(e) : "";
  if (!scene || !meshes || !view) {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.fillStyle = THEME.background;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    return;
  }
  const drawlist = buildDrawlist(scene, crankAngle);
  paintDrawlist(ctx, canvas, drawlist, meshes, label, view);
}

async function loadSelectedScene() {
  const e = catalog.engines.find((x) => x.id === selectedId);
  if (!e || e.skipped) {
    scene = null;
    baseView = null;
    view = null;
    paint();
    return;
  }
  try {
    const raw = await fetchScene(e.id);
    scene = prepareScene(raw);
    const canvas = $("stage");
    // Square bitmap for radials so circular geometry isn't letterboxed into a wide frame.
    const radial =
      !!(scene.slave_throw && (scene.banks?.length || 0) >= 3) || (scene.banks?.length || 0) >= 5;
    const side = radial ? 720 : 0;
    if (radial && (canvas.width !== side || canvas.height !== side)) {
      canvas.width = side;
      canvas.height = side;
    } else if (!radial && (canvas.width !== 860 || canvas.height !== 520)) {
      canvas.width = 860;
      canvas.height = 520;
    }
    baseView = viewFromScene(scene, canvas.width, canvas.height);
    view = { ...baseView };
    paint();
  } catch (err) {
    console.error(err);
    scene = null;
    baseView = null;
    const canvas = $("stage");
    const ctx = canvas.getContext("2d");
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.fillStyle = THEME.background;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = "#EE4445";
    ctx.font = "14px monospace";
    ctx.fillText(String(err.message || err), 16, 28);
  }
}

function selectEngine(id) {
  selectedId = id;
  const e = catalog.engines.find((x) => x.id === id);
  document.querySelectorAll(".engine-list button").forEach((btn) => {
    btn.classList.toggle("active", btn.dataset.id === id);
  });
  if (!e) return;
  $("source").textContent = e.source;
  renderParams(e);
  loadSelectedScene();
}

function buildList(filter = "") {
  const ul = $("engine-list");
  ul.innerHTML = "";
  const q = filter.trim().toLowerCase();
  const items = catalog.engines.filter((e) => {
    if (!q) return true;
    const hay = `${engineName(e)} ${e.layout || ""} ${e.source}`.toLowerCase();
    return hay.includes(q);
  });
  for (const e of items) {
    const li = document.createElement("li");
    if (e.skipped) li.classList.add("skip");
    const btn = document.createElement("button");
    btn.type = "button";
    btn.dataset.id = e.id;
    btn.innerHTML = `<span class="name">${escapeHtml(engineName(e))}</span>
      <span class="tag">${escapeHtml(engineTag(e))}</span>`;
    btn.addEventListener("click", () => selectEngine(e.id));
    if (e.id === selectedId) btn.classList.add("active");
    li.appendChild(btn);
    ul.appendChild(li);
  }
  $("list-meta").textContent = `${items.length} показано · ${catalog.meta.engine_count} моторов · ${catalog.meta.skipped_count} skip`;
}

function tick() {
  // Screen +Y is up; decreasing θ is clockwise (math CCW would be +θ).
  if (!paused) crankAngle -= 0.028;
  if (scene) paint();
  requestAnimationFrame(tick);
}

async function main() {
  document.documentElement.style.setProperty("--bg", THEME.background);
  document.body.style.background = THEME.background;

  const res = await fetch("/engines.json");
  if (!res.ok) throw new Error("engines.json not found — run tools/parse_engines.py");
  catalog = await res.json();
  meshes = await loadMeshes();
  $("attr").textContent =
    (catalog.meta.attribution || "") +
    " · meshes: assets.ysce · draw runtime local (C++ formulas)";
  buildList();
  $("filter").addEventListener("input", (ev) => buildList(ev.target.value));
  $("btn-pause").addEventListener("click", () => setPaused(!paused));
  window.addEventListener("keydown", (ev) => {
    if (ev.code !== "Space") return;
    const tag = (ev.target && ev.target.tagName) || "";
    if (tag === "INPUT" || tag === "TEXTAREA") return;
    ev.preventDefault();
    setPaused(!paused);
  });

  const stage = $("stage");
  stage.addEventListener(
    "wheel",
    (ev) => {
      if (!view || !baseView) return;
      ev.preventDefault();
      const rect = stage.getBoundingClientRect();
      const sx = ((ev.clientX - rect.left) / rect.width) * stage.width;
      const sy = ((ev.clientY - rect.top) / rect.height) * stage.height;
      // deltaY > 0 → zoom out; smooth exponential step
      const factor = Math.exp(-ev.deltaY * 0.0015);
      zoomAt(sx, sy, factor);
      paint();
    },
    { passive: false }
  );
  stage.addEventListener("dblclick", () => {
    resetZoom();
    paint();
  });

  const prefer =
    catalog.engines.find((e) => /kohler/i.test(e.identity?.name || "")) ||
    catalog.engines.find((e) => /hayabusa/i.test(e.identity?.name || "")) ||
    catalog.engines.find((e) => e.id === catalog.meta.default_id) ||
    catalog.engines.find((e) => !e.skipped);
  if (prefer) selectEngine(prefer.id);
  requestAnimationFrame(tick);
}

main().catch((err) => {
  $("params").innerHTML = `<p class="empty">${escapeHtml(err.message)}</p>`;
  console.error(err);
});
