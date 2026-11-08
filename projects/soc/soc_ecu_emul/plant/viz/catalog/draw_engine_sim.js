/**
 * Canvas port of engine-sim simulation objects:
 *   cylinder_bank_object.cpp
 *   connecting_rod_object.cpp
 *   piston_object.cpp
 *   crankshaft_object.cpp
 *   cylinder_head_object.cpp
 *   simulation_object.cpp (tintByLayer, setTransform)
 *   geometry_generator.cpp (generateLine2d, generateCircle2d, generateCam simplified)
 *   assets/themes/default.mr colors
 *
 * Mesh assets (Piston / ConnectingRod / Crankshaft / CylinderHead / Valve) are
 * approximated with the same transforms + scales the C++ uses when DrawModel()'ing.
 */

export const THEME = {
  background: "#0E1012",
  foreground: "#FFFFFF",
  pink: "#F394BE",
  orange: "#F4802A",
  yellow: "#FDBD2E",
  blue: "#77CEE0",
  green: "#BDD869",
  red: "#EE4445",
};

// --- theme helpers (ui_utilities mix / tintByLayer) ---

/** Accept #RRGGBB or rgb(r,g,b) — mixHex() returns rgb(), tint must parse both. */
function parseColor(c) {
  if (typeof c === "string" && c[0] === "#") {
    const v = parseInt(c.slice(1), 16);
    return [(v >> 16) & 255, (v >> 8) & 255, v & 255];
  }
  const m = String(c).match(/(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
  if (m) return [+m[1], +m[2], +m[3]];
  return [0, 0, 0];
}
function rgb([r, g, b]) {
  return `rgb(${r|0},${g|0},${b|0})`;
}
function mixHex(a, b, t) {
  const A = parseColor(a), B = parseColor(b);
  return rgb([
    A[0] + (B[0] - A[0]) * t,
    A[1] + (B[1] - A[1]) * t,
    A[2] + (B[2] - A[2]) * t,
  ]);
}
/** simulation_object.cpp tintByLayer — each layer: col*0.3 + bg*0.7 */
function tintByLayer(col, layers) {
  let c = parseColor(col);
  const bg = parseColor(THEME.background);
  for (let i = 0; i < layers; i++) {
    c = [
      c[0] * 0.3 + bg[0] * 0.7,
      c[1] * 0.3 + bg[1] * 0.7,
      c[2] * 0.3 + bg[2] * 0.7,
    ];
  }
  return rgb(c);
}

// --- GeometryGenerator ports ---

function generateLine2d(ctx, x0, y0, x1, y1, lineWidth, color) {
  const dx = x1 - x0, dy = y1 - y0;
  const len = Math.hypot(dx, dy) || 1;
  const px = (-dy / len) * (lineWidth / 2);
  const py = (dx / len) * (lineWidth / 2);
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.moveTo(x0 + px, y0 + py);
  ctx.lineTo(x1 + px, y1 + py);
  ctx.lineTo(x1 - px, y1 - py);
  ctx.lineTo(x0 - px, y0 - py);
  ctx.closePath();
  ctx.fill();
}

function generateCircle2d(ctx, cx, cy, radius, color) {
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.arc(cx, cy, Math.max(0.5, radius), 0, Math.PI * 2);
  ctx.fill();
}

/** generateCam — teardrop lobe; liftFn(angleRad) → extra lift beyond base */
function generateCam(ctx, cx, cy, baseRadius, rollerRadius, liftFn, color, maxEdge = 0.05) {
  let angle = Math.asin(Math.min(0.99, maxEdge / (2 * baseRadius))) * 2;
  angle = Math.min(angle, Math.PI - 0.05);
  let segmentCount = Math.ceil((Math.PI * 2) / angle);
  segmentCount = Math.max(3, segmentCount);
  const angleStep = (Math.PI * 2) / segmentCount;
  const baseRoller = baseRadius + rollerRadius;
  const positions = [];
  let lastX = 0, lastY = 0;
  for (let i = 0; i < segmentCount; i++) {
    const a0 = angleStep * i;
    const x = Math.cos(a0 + Math.PI / 2);
    const y = Math.sin(a0 + Math.PI / 2);
    const lift = liftFn ? liftFn(a0 - Math.PI) : 0;
    const rollerPos = baseRoller + lift;
    const rx = cx + x * rollerPos;
    const ry = cy + y * rollerPos;
    let dx = -1, dy = 0;
    if (i !== 0) {
      dx = rx - lastX;
      dy = ry - lastY;
      const mag = Math.hypot(dx, dy) || 1;
      dx /= mag;
      dy /= mag;
    }
    lastX = rx;
    lastY = ry;
    positions.push({ x: rx - dy * rollerRadius, y: ry + dx * rollerRadius });
  }
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.moveTo(positions[0].x, positions[0].y);
  for (let i = 1; i < positions.length; i++) ctx.lineTo(positions[i].x, positions[i].y);
  ctx.closePath();
  ctx.fill();
}

// --- unit / angle parse (from engines.json expressions) ---

export function toMm(expr, labels = {}) {
  if (expr == null || expr === "") return null;
  let s = String(expr).trim();
  for (const [k, v] of Object.entries(labels)) {
    s = s.replace(new RegExp(`\\b${k}\\b`, "g"), `(${v})`);
  }
  s = s
    .replace(/units\.mm/g, "1")
    .replace(/units\.cm/g, "10")
    .replace(/units\.inch/g, "25.4")
    .replace(/units\.thou/g, "0.0254")
    .replace(/units\.m\b/g, "1000")
    .replace(/units\.cc/g, "1")
    .replace(/units\.[A-Za-z0-9_]+/g, "1")
    .replace(/constants\.pi/g, "Math.PI");
  try {
    // eslint-disable-next-line no-new-func
    const v = Function(`"use strict"; return (${s});`)();
    return Number.isFinite(v) ? v : null;
  } catch {
    return null;
  }
}

function toRad(expr, labels = {}) {
  if (expr == null) return null;
  if (typeof expr === "number") return (expr * Math.PI) / 180;
  let s = String(expr).trim();
  for (const [k, v] of Object.entries(labels)) {
    s = s.replace(new RegExp(`\\b${k}\\b`, "g"), `(${v})`);
  }
  if (/units\.deg/.test(s)) {
    s = s.replace(/units\.deg/g, "1").replace(/constants\.pi/g, "Math.PI");
    try {
      // eslint-disable-next-line no-new-func
      const deg = Function(`"use strict"; return (${s});`)();
      return Number.isFinite(deg) ? (deg * Math.PI) / 180 : null;
    } catch {
      return null;
    }
  }
  s = s.replace(/constants\.pi/g, "Math.PI");
  try {
    // eslint-disable-next-line no-new-func
    const v = Function(`"use strict"; return (${s});`)();
    return Number.isFinite(v) ? v : null;
  } catch {
    return null;
  }
}

// --- build model from engines.json ---

export function buildDrawModel(engine) {
  const labels = engine.labels || {};
  const bore = toMm(engine.bank_params?.bore, labels) || toMm(labels.bore, labels) || 80;
  let throwMm = toMm(engine.crank?.throw, labels);
  if (throwMm == null && labels.stroke) {
    const st = toMm(labels.stroke, labels);
    if (st != null) throwMm = st / 2;
  }
  throwMm = throwMm ?? 35;
  const rodLen =
    toMm(engine.connecting_rod?.length, labels) ||
    toMm(labels.rod_length, labels) ||
    throwMm * 3.2;
  const compH =
    toMm(engine.piston?.compression_height, labels) ||
    toMm(labels.compression_height, labels) ||
    bore * 0.35;
  const wristPin = toMm(engine.piston?.wrist_pin_position, labels) || 0;
  const deck =
    toMm(engine.bank_params?.deck_height, labels) || throwMm + rodLen + compH;

  let chamberVolCc = 40;
  if (engine.head?.chamber_volume) {
    const v = toMm(String(engine.head.chamber_volume).replace(/units\.cc/g, "1"), labels);
    if (v != null) chamberVolCc = v;
  }
  const boreM = bore / 1000;
  const chamberH = ((chamberVolCc * 1e-6) / ((Math.PI * boreM * boreM) / 4)) * 1000;

  // cam lobe (harmonic) — optional
  let camLift = toMm(engine.cam_lobe?.lift, labels) || bore * 0.08;
  let camBase = toMm(engine.cam_lobe?.base_radius, labels) || bore * 0.15;
  let camDuration = 160; // deg at 50 thou, default-ish
  if (engine.cam_lobe?.duration_at_50_thou) {
    const d = toRad(engine.cam_lobe.duration_at_50_thou, labels);
    if (d != null) camDuration = (d * 180) / Math.PI;
  }

  const banks = (engine.banks || []).map((b, i) => {
    let ang = b.angle_deg != null ? (b.angle_deg * Math.PI) / 180 : 0;
    if (b.angle_expr) {
      const r = toRad(b.angle_expr, labels);
      if (r != null) ang = r;
    }
    return {
      index: i,
      angle: ang,
      cylinders: b.cylinders || 0,
      journal_indices: Array.isArray(b.journal_indices) ? b.journal_indices : null,
      // cylinder_bank.cpp
      dx: Math.cos(ang + Math.PI / 2),
      dy: Math.sin(ang + Math.PI / 2),
      x: 0,
      y: 0,
      // Script default 0.5; per-bank / bank_params may override
      displayDepth: b.display_depth != null ? b.display_depth : 0.5,
    };
  });
  if (banks.length === 2 && banks.every((b) => Math.abs(b.angle) < 1e-6)) {
    banks[0].angle = (-45 * Math.PI) / 180;
    banks[1].angle = (45 * Math.PI) / 180;
    for (const b of banks) {
      b.dx = Math.cos(b.angle + Math.PI / 2);
      b.dy = Math.sin(b.angle + Math.PI / 2);
    }
  }
  if (!banks.length) {
    banks.push({
      index: 0,
      angle: 0,
      cylinders: engine.n_cylinders || 1,
      dx: 0,
      dy: 1,
      x: 0,
      y: 0,
      displayDepth: 0.5,
    });
  }

  const journals = (engine.journals || []).map((j, i) => {
    if (j.angle_deg != null) return (j.angle_deg * Math.PI) / 180;
    if (j.angle_expr) {
      const r = toRad(j.angle_expr, labels);
      if (r != null) return r;
    }
    return (i * Math.PI * 2) / Math.max(1, engine.journals.length);
  });
  if (!journals.length) {
    const n = engine.n_cylinders || 1;
    for (let i = 0; i < n; i++) journals.push(0);
  }

  const cylinders = [];
  const nJ = Math.max(1, journals.length);
  for (const bank of banks) {
    const mapped = Array.isArray(bank.journal_indices) ? bank.journal_indices : null;
    for (let c = 0; c < (bank.cylinders || 0); c++) {
      // ConnectingRod::getLayer() == journal index (shared pins share brightness)
      const journalIndex =
        mapped && mapped[c] != null ? mapped[c] % nJ : c % nJ;
      cylinders.push({
        bank,
        journalIndex,
        layer: journalIndex,
        cylinderIndex: c,
        flipDisplay: bank.index % 2 === 1,
      });
    }
  }
  if (!cylinders.length) {
    cylinders.push({
      bank: banks[0],
      journalIndex: 0,
      layer: 0,
      cylinderIndex: 0,
      flipDisplay: false,
    });
  }

  // connecting_rod.cpp
  const centerOfMass = 0;
  const bigEndLocal = -(rodLen / 2) + centerOfMass;
  const littleEndLocal = rodLen / 2 - centerOfMass;

  return {
    name: engine.identity?.name || engine.id,
    layout: engine.layout,
    bore,
    throwMm,
    rodLen,
    compH,
    wristPin,
    deck,
    chamberH,
    camLift,
    camBase,
    camDuration,
    banks,
    journals,
    cylinders,
    bigEndLocal,
    littleEndLocal,
  };
}

// --- kinematic pose (stand-in for SCS rigid bodies) ---

function poseCylinder(model, cyl, crankAngle) {
  const bank = cyl.bank;
  const ja = model.journals[cyl.journalIndex] + crankAngle;
  const jx = Math.cos(ja) * model.throwMm;
  const jy = Math.sin(ja) * model.throwMm;

  const px = -bank.dy;
  const py = bank.dx;
  const along = jx * bank.dx + jy * bank.dy;
  const across = jx * px + jy * py;
  const disc = Math.max(0, model.rodLen * model.rodLen - across * across);
  const wristAlong = along + Math.sqrt(disc);
  const wx = bank.dx * wristAlong;
  const wy = bank.dy * wristAlong;

  // rod angle in world (Y-up): from big end (journal) to little end (wrist)
  const rodTheta = Math.atan2(wy - jy, wx - jx) - Math.PI / 2;
  // placeCylinder: piston->m_body.theta = bank->getAngle() + π
  // wrist pin at piston local (0, wristPin); body origin such that world wrist = (wx,wy)
  const pistonTheta = bank.angle + Math.PI;

  return {
    journal: { x: jx, y: jy },
    wrist: { x: wx, y: wy },
    rodTheta,
    pistonTheta,
    // rod body origin = midpoint shifted by COM — place at journal transformed
    // ConnectingRod mesh: setTransform(body, throw, 0, bigEndLocal)
    // We put rod body p at geometric center of journal↔wrist in rod frame
    rodP: {
      x: (jx + wx) / 2,
      y: (jy + wy) / 2,
    },
    pistonP: {
      // wrist world = R(pistonTheta) * (0, wristPin) + pistonP
      // with wristPin≈0 → pistonP ≈ wrist
      x: wx,
      y: wy,
    },
  };
}

// --- object draw functions (mirroring *.cpp render/generateGeometry) ---

function drawCylinderBankObject(ctx, toS, model, bank) {
  // cylinder_bank_object.cpp generateGeometry — EXACT formulas
  const lineWidth = model.bore * 0.1;
  const margin = lineWidth * 0.25;
  const displayDepth = 1.0 - bank.displayDepth; // 0.6 when displayDepth=0.4
  const dxWall = -bank.dy * (margin + model.bore / 2 + lineWidth / 2);
  const dyWall = bank.dx * (margin + model.bore / 2 + lineWidth / 2);
  const top_x = bank.x + bank.dx * (model.deck + model.chamberH);
  const top_y = bank.y + bank.dy * (model.deck + model.chamberH);
  const bottom_x = bank.x + bank.dx * (displayDepth * model.deck);
  const bottom_y = bank.y + bank.dy * (displayDepth * model.deck);

  const col = THEME.pink;
  const [x0a, y0a] = toS(top_x + dxWall, top_y + dyWall);
  const [x1a, y1a] = toS(bottom_x + dxWall, bottom_y + dyWall);
  const [x0b, y0b] = toS(top_x - dxWall, top_y - dyWall);
  const [x1b, y1b] = toS(bottom_x - dxWall, bottom_y - dyWall);
  const lw = lineWidth * toS.scale;

  generateLine2d(ctx, x0a, y0a, x1a, y1a, lw, col);
  generateCircle2d(ctx, x1a, y1a, lw / 2, col);
  generateLine2d(ctx, x0b, y0b, x1b, y1b, lw, col);
  generateCircle2d(ctx, x1b, y1b, lw / 2, col);
}

function drawCrankshaftObject(ctx, toS, model, crankAngle, viewLayer0, viewLayer1) {
  // crankshaft_object.cpp — mesh approx: circular crank web at each journal angle
  const grey0 = mixHex(THEME.background, THEME.foreground, 0.7);
  const grey1 = mixHex(THEME.background, THEME.foreground, 0.6);
  const grey2 = mixHex(THEME.background, THEME.foreground, 0.2);
  const throwR = model.throwMm;

  // CrankSnout at origin, scale=throw
  const [ox, oy] = toS(0, 0);
  generateCircle2d(ctx, ox, oy, throwR * 0.55 * toS.scale, grey1);
  generateCircle2d(ctx, ox, oy, throwR * 0.25 * toS.scale, grey2);

  // Far journals first (esim draw priority 0x32 - layer) so near/bright sits on top.
  for (let i = model.journals.length - 1; i >= 0; i--) {
    if (i < viewLayer0 || i > viewLayer1) continue;
    const col = tintByLayer(grey0, i - viewLayer0);
    // setTransform(body, throw, 0, 0, journalAngle) — mesh "Crankshaft"
    // approx: counterweight disk offset along journal angle
    const a = model.journals[i] + crankAngle;
    const jx = Math.cos(a) * throwR;
    const jy = Math.sin(a) * throwR;
    const [sx, sy] = toS(jx, jy);
    // web from center to pin
    generateLine2d(ctx, ox, oy, sx, sy, throwR * 0.55 * toS.scale, col);
    generateCircle2d(ctx, sx, sy, throwR * 0.32 * toS.scale, col);
    // counterweight opposite
    const [cx2, cy2] = toS(-jx * 0.85, -jy * 0.85);
    generateCircle2d(ctx, cx2, cy2, throwR * 0.5 * toS.scale, col);
  }
}

function drawConnectingRodObject(ctx, toS, model, cyl, pose, viewLayer0) {
  // connecting_rod_object — grey0/grey1 by bank index, DrawModel ConnectingRod + generateGeometry body
  const layer = cyl.layer;
  if (layer < viewLayer0) return;
  const grey0 = mixHex(THEME.background, THEME.foreground, 0.9333);
  const grey1 = mixHex(THEME.background, THEME.foreground, 0.8667);
  let color = cyl.bank.index % 2 === 0 ? grey0 : grey1;
  color = tintByLayer(color, layer - viewLayer0);

  const [jx, jy] = toS(pose.journal.x, pose.journal.y);
  const [wx, wy] = toS(pose.wrist.x, pose.wrist.y);

  // generateGeometry line: width = throw * 0.5
  const lineWidth = model.throwMm * 0.5 * toS.scale;
  generateLine2d(ctx, jx, jy, wx, wy, lineWidth, color);
  // big-end boss (approx ConnectingRod mesh eye)
  generateCircle2d(ctx, jx, jy, model.throwMm * 0.38 * toS.scale, color);
  // little-end
  generateCircle2d(ctx, wx, wy, model.bore * 0.12 * toS.scale, color);
}

function drawPistonObject(ctx, toS, model, cyl, pose, viewLayer0) {
  // piston_object.cpp — DrawModel Piston with scale=bore/2, ly=-(compH+wristPin)
  const layer = cyl.layer;
  if (layer < viewLayer0) return;
  const col = tintByLayer(THEME.foreground, layer - viewLayer0);
  const holeCol = tintByLayer(THEME.background, layer - viewLayer0);

  const s = model.bore / 2; // scale used in setTransform
  const [wx, wy] = toS(pose.wrist.x, pose.wrist.y);

  // Screen rotation: bank angle, Y-up → canvas flip
  const sdx = cyl.bank.dx;
  const sdy = -cyl.bank.dy;
  const angle = Math.atan2(sdy, sdx) - Math.PI / 2;

  ctx.save();
  ctx.translate(wx, wy);
  ctx.rotate(angle);
  // Mesh local: after scale s, piston ~ width 2 → screen width bore.
  // Origin at wrist; crown toward +Y local (head) = -compH offset was applied in C++
  // as ly on transform — crown is above wrist by ~compH in bank dir.
  const halfW = s * toS.scale; // bore/2 * scale
  const h = (model.compH + Math.abs(model.wristPin) * 0.5) * toS.scale;
  // Piston body: rectangle centered slightly toward crank (skirt) / crown toward head
  ctx.fillStyle = col;
  ctx.beginPath();
  const x0 = -halfW * 0.95;
  const yCrown = -h * 0.15; // toward head (local -Y after our rotate? bank dir is local +Y up in engine-sim)
  // In engine-sim Y-up bank dir; after canvas flip rotate, local +Y should go toward head.
  // Our angle maps bank screen dir to local +Y.
  const y0 = -h * 0.55; // crown (toward head = up local)
  ctx.rect(x0, y0, halfW * 1.9, h);
  ctx.fill();
  // wrist pin hole — generateGeometry circle at (0, wristPin)
  generateCircle2d(ctx, 0, model.wristPin * toS.scale, (model.bore / 10) * 0.75 * toS.scale, holeCol);
  ctx.restore();
}

function drawCylinderHeadObject(ctx, toS, model, bank, flipDisplay, crankAngle) {
  // cylinder_head_object.cpp — CylinderHead mesh + Valve + cams
  const s = model.bore / 2;
  let hx = bank.x + bank.dx * (model.deck + model.chamberH);
  let hy = bank.y + bank.dy * (model.deck + model.chamberH);
  const [ox, oy] = toS(hx, hy);

  const sdx = bank.dx;
  const sdy = -bank.dy;
  const angle = Math.atan2(sdy, sdx); // head local +X along… C++ rotates by bank.angle
  // C++: RotationTransform(Z, bank.angle) then scale by s
  // bank.angle 0 → identity; our screen needs bank orientation
  const headAngle = Math.atan2(sdy, sdx) - Math.PI / 2;

  ctx.save();
  ctx.translate(ox, oy);
  ctx.rotate(headAngle);
  // Scale by s in model space → multiply coords by s*scale for drawing in px
  const S = s * toS.scale;

  // Approximate CylinderHead mesh: pink block spanning ~±1 in local X (bore units after scale)
  ctx.fillStyle = THEME.pink;
  ctx.beginPath();
  ctx.rect(-1.05 * S, -0.15 * S, 2.1 * S, 0.85 * S);
  ctx.fill();
  // deck face / chamber cut
  ctx.fillStyle = THEME.background;
  ctx.fillRect(-0.85 * S, 0.15 * S, 1.7 * S, 0.35 * S);

  const intakeValvePosition = flipDisplay ? 0.5 : -0.5;

  // Valve stems (from valveShadow generateGeometry) + Valve mesh approx as T
  function drawValve(localX, color, lift) {
    const lx = localX * S;
    const ly = (-lift / s) * S; // lift in world mm / s → local
    // stem
    generateLine2d(ctx, lx, 0.2 * S + ly, lx, 1.5 * S + ly, 0.1 * S, color);
    // head (T)
    generateLine2d(ctx, lx - 0.22 * S, 0.15 * S + ly, lx + 0.22 * S, 0.15 * S + ly, 0.12 * S, color);
    // roller
    generateCircle2d(ctx, lx, 1.99 * S + ly, 0.12 * S, color);
    generateCircle2d(ctx, lx, 1.99 * S + ly, 0.04 * S, THEME.background);
  }

  // synthetic lifts oscillating with crank (visual only — no real cam table)
  const intakeLift = model.camLift * 0.5 * (0.5 + 0.5 * Math.sin(crankAngle * 2 + bank.angle));
  const exhaustLift = model.camLift * 0.5 * (0.5 + 0.5 * Math.sin(crankAngle * 2 + bank.angle + Math.PI));

  drawValve(intakeValvePosition, THEME.blue, intakeLift);
  drawValve(-intakeValvePosition, THEME.yellow, exhaustLift);

  // Cams above rollers — generateCam at cylinder_head_object positions
  const rollerRadius = 0.3; // mm thou-ish → in bore-units ~ 300thou/s
  const rr = (0.3 / s) * S; // screen px — keep relative
  const camY =
    rr +
    0.02 * S +
    1.99 * S +
    (model.camBase / s) * S;

  function lobeLift(a) {
    // crude harmonic: lift near 0 angle
    const half = ((model.camDuration / 2) * Math.PI) / 180;
    const aa = ((a % (Math.PI * 2)) + Math.PI * 3) % (Math.PI * 2) - Math.PI;
    if (Math.abs(aa) > half) return 0;
    return (model.camLift / s) * S * Math.cos((aa / half) * (Math.PI / 2));
  }

  const camBasePx = (model.camBase / s) * S;
  const intakeCamX = intakeValvePosition * S;
  const exhaustCamX = -intakeValvePosition * S;

  ctx.save();
  ctx.translate(intakeCamX, camY);
  ctx.rotate(crankAngle * 2 + bank.angle); // cam spins ~2:1 visually
  generateCam(ctx, 0, 0, camBasePx, rr, lobeLift, THEME.blue, 0.08 * S);
  generateCircle2d(ctx, 0, 0, rr * 0.35, THEME.background);
  ctx.restore();

  ctx.save();
  ctx.translate(exhaustCamX, camY);
  ctx.rotate(crankAngle * 2 + bank.angle + Math.PI * 0.3);
  generateCam(ctx, 0, 0, camBasePx, rr, lobeLift, THEME.orange, 0.08 * S);
  generateCircle2d(ctx, 0, 0, rr * 0.35, THEME.background);
  ctx.restore();

  ctx.restore();
}

// --- main entry ---

export function drawEngineSim(ctx, canvas, model, crankAngleRad) {
  const w = canvas.width;
  const h = canvas.height;
  ctx.fillStyle = THEME.background;
  ctx.fillRect(0, 0, w, h);

  if (!model) {
    ctx.fillStyle = "#888";
    ctx.font = "14px monospace";
    ctx.fillText("no model", 20, 30);
    return;
  }

  ctx.fillStyle = THEME.foreground;
  ctx.font = "600 18px ui-monospace, monospace";
  ctx.fillText(model.name, 16, 28);
  ctx.fillStyle = mixHex(THEME.foreground, THEME.background, 0.45);
  ctx.font = "12px ui-monospace, monospace";
  ctx.fillText(
    `${model.layout} · ${model.cylinders.length} cyl · bore ${model.bore.toFixed(1)} mm`,
    16,
    48
  );

  // Fit: head cams stick above deck+chamber by ~2.5*bore
  const span = model.deck + model.chamberH + model.bore * 2.5 + model.throwMm;
  const scale = (Math.min(w, h) * 0.5) / span;
  const cx = w * 0.5;
  const cy = h * 0.72;
  const toS = (x, y) => [cx + x * scale, cy - y * scale];
  toS.scale = scale;

  const viewLayer0 = 0;
  const viewLayer1 = 99;

  // Render order ≈ engine_sim_application.cpp sublayers:
  // 0: banks + heads, rods/pistons; 2: crank
  for (const bank of model.banks) {
    drawCylinderBankObject(ctx, toS, model, bank);
  }

  drawCrankshaftObject(ctx, toS, model, crankAngleRad, viewLayer0, viewLayer1);

  // Back→front (high layer first): matches esim 0x32-layer so bright front is visible.
  const sorted = [...model.cylinders].sort((a, b) => b.layer - a.layer);
  for (const cyl of sorted) {
    const pose = poseCylinder(model, cyl, crankAngleRad);
    drawConnectingRodObject(ctx, toS, model, cyl, pose, viewLayer0);
    drawPistonObject(ctx, toS, model, cyl, pose, viewLayer0);
  }

  // Heads once per bank (foremost piston) — cylinder_head_object
  for (const bank of model.banks) {
    const front = [...model.cylinders]
      .filter((c) => c.bank === bank)
      .sort((a, b) => a.layer - b.layer)[0];
    if (front) {
      drawCylinderHeadObject(ctx, toS, model, bank, front.flipDisplay, crankAngleRad);
    }
  }
}
