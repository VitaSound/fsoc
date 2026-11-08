/**
 * Browser runtime of native/src/engine_draw.cpp (same transforms / colors / ops).
 * Meshes stay from assets.ysce; kinematics run locally so we don't spawn C++ every frame.
 */

const BG = "#0E1012";
const FG = "#FFFFFF";
const PINK = "#F394BE";
const ORANGE = "#F4802A";
const YELLOW = "#FDBD2E";
const BLUE = "#77CEE0";

/** Accept #RRGGBB or rgb(r,g,b) — mix() returns rgb(), tint must parse both. */
function parseColor(c) {
  if (typeof c === "string" && c[0] === "#") {
    const v = parseInt(c.slice(1), 16);
    return [(v >> 16) & 255, (v >> 8) & 255, v & 255];
  }
  const m = String(c).match(/(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
  if (m) return [+m[1], +m[2], +m[3]];
  return [0, 0, 0];
}
function css([r, g, b]) {
  return `rgb(${r | 0},${g | 0},${b | 0})`;
}
function mix(a, b, t) {
  const A = parseColor(a),
    B = parseColor(b);
  return css([A[0] + (B[0] - A[0]) * t, A[1] + (B[1] - A[1]) * t, A[2] + (B[2] - A[2]) * t]);
}
function tintByLayer(col, layers) {
  let c = parseColor(col);
  const bg = parseColor(BG);
  for (let i = 0; i < layers; i++) {
    c = [c[0] * 0.3 + bg[0] * 0.7, c[1] * 0.3 + bg[1] * 0.7, c[2] * 0.3 + bg[2] * 0.7];
  }
  return css(c);
}

/** Mat3 as [a,b,c,d,e,f]: x'=a*x+c*y+e, y'=b*x+d*y+f */
function T(x, y) {
  return [1, 0, 0, 1, x, y];
}
function R(th) {
  const ct = Math.cos(th),
    st = Math.sin(th);
  return [ct, st, -st, ct, 0, 0];
}
function S(s) {
  return [s, 0, 0, s, 0, 0];
}
function mul(A, B) {
  return [
    A[0] * B[0] + A[2] * B[1],
    A[1] * B[0] + A[3] * B[1],
    A[0] * B[2] + A[2] * B[3],
    A[1] * B[2] + A[3] * B[3],
    A[0] * B[4] + A[2] * B[5] + A[4],
    A[1] * B[4] + A[3] * B[5] + A[5],
  ];
}
function apply(m, x, y) {
  return [m[0] * x + m[2] * y + m[4], m[1] * x + m[3] * y + m[5]];
}
function setTransform(bx, by, theta, scale, lx = 0, ly = 0, angle = 0, scaleY = null) {
  // simulation_object::setTransform — scaleY defaults to scale; pass -scale to mirror mesh
  const ct = Math.cos(theta),
    st = Math.sin(theta);
  const px = bx + ct * lx - st * ly;
  const py = by + st * lx + ct * ly;
  const sy = scaleY == null ? scale : scaleY;
  return mul(mul(T(px, py), R(theta + angle)), [scale, 0, 0, sy, 0, 0]);
}

function line2d(xform, x0, y0, x1, y1, lineWidth, color, cmds) {
  const dx = x1 - x0,
    dy = y1 - y0;
  const len = Math.hypot(dx, dy) || 1;
  const px = (-dy / len) * (lineWidth / 2);
  const py = (dx / len) * (lineWidth / 2);
  const pts = [
    [x0 + px, y0 + py],
    [x0 - px, y0 - py],
    [x1 + px, y1 + py],
    [x1 - px, y1 - py],
  ].map(([x, y]) => apply(xform, x, y));
  cmds.push({
    op: "tris",
    color,
    xy: [pts[0][0], pts[0][1], pts[1][0], pts[1][1], pts[2][0], pts[2][1], pts[1][0], pts[1][1], pts[3][0], pts[3][1], pts[2][0], pts[2][1]],
  });
}

function circle2d(xform, cx, cy, radius, color, cmds) {
  if (radius <= 0) return;
  const segs = Math.max(12, Math.min(48, (radius * 4) | 0));
  const xy = [];
  const [ox, oy] = apply(xform, cx, cy);
  for (let i = 0; i < segs; i++) {
    const a0 = (Math.PI * 2 * i) / segs;
    const a1 = (Math.PI * 2 * (i + 1)) / segs;
    const [x1, y1] = apply(xform, cx + Math.cos(a0) * radius, cy + Math.sin(a0) * radius);
    const [x2, y2] = apply(xform, cx + Math.cos(a1) * radius, cy + Math.sin(a1) * radius);
    xy.push(ox, oy, x1, y1, x2, y2);
  }
  cmds.push({ op: "tris", color, xy });
}

function cam2d(xform, cx, cy, baseRadius, rollerRadius, liftAmp, color, cmds) {
  const segs = 36;
  const angleStep = (Math.PI * 2) / segs;
  const baseRoller = baseRadius + rollerRadius;
  const px = new Float64Array(segs);
  const py = new Float64Array(segs);
  let lastx = 0,
    lasty = 0;
  for (let i = 0; i < segs; i++) {
    const a0 = angleStep * i;
    const x = Math.cos(a0 + Math.PI / 2);
    const y = Math.sin(a0 + Math.PI / 2);
    let aa = a0 - Math.PI;
    while (aa > Math.PI) aa -= Math.PI * 2;
    while (aa < -Math.PI) aa += Math.PI * 2;
    let lift = 0;
    if (Math.abs(aa) < Math.PI / 3) lift = liftAmp * Math.cos((aa / (Math.PI / 3)) * (Math.PI / 2));
    const rp = baseRoller + lift;
    const rx = cx + x * rp,
      ry = cy + y * rp;
    let dx = -1,
      dy = 0;
    if (i !== 0) {
      dx = rx - lastx;
      dy = ry - lasty;
      const mag = Math.hypot(dx, dy) || 1;
      dx /= mag;
      dy /= mag;
    }
    lastx = rx;
    lasty = ry;
    px[i] = rx - dy * rollerRadius;
    py[i] = ry + dx * rollerRadius;
  }
  const [ox, oy] = apply(xform, cx, cy);
  const xy = [];
  for (let i = 0; i < segs; i++) {
    const prev = (i - 1 + segs) % segs;
    const next = (i + 1) % segs;
    const [x1, y1] = apply(xform, (px[prev] + px[next]) * 0.5, (py[prev] + py[next]) * 0.5);
    const [x2, y2] = apply(
      xform,
      (px[i] + px[next]) * 0.5,
      (py[i] + py[next]) * 0.5
    );
    // fan approx: center → averaged ring points
    const j = (i + 1) % segs;
    const pj = (j - 1 + segs) % segs;
    const nj = (j + 1) % segs;
    const [xa, ya] = apply(xform, (px[prev] + px[next]) * 0.5, (py[prev] + py[next]) * 0.5);
    const [xb, yb] = apply(xform, (px[pj] + px[nj]) * 0.5, (py[pj] + py[nj]) * 0.5);
    xy.push(ox, oy, xa, ya, xb, yb);
  }
  cmds.push({ op: "tris", color, xy });
}

function poseFromPin(scene, bank, jx, jy, rodLen) {
  const px = -bank.dy,
    py = bank.dx;
  const along = jx * bank.dx + jy * bank.dy;
  const across = jx * px + jy * py;
  const disc = Math.max(0, rodLen * rodLen - across * across);
  const wristAlong = along + Math.sqrt(disc);
  const wx = bank.dx * wristAlong;
  const wy = bank.dy * wristAlong;
  const rodTheta = Math.atan2(wy - jy, wx - jx) - Math.PI / 2;
  // engine-sim placeCylinder: piston->m_body.theta = bank->getAngle() + π
  const pistonTheta = bank.angle + Math.PI;
  const bigEndLocal = -rodLen / 2;
  const ct = Math.cos(rodTheta),
    st = Math.sin(rodTheta);
  const rodBodyX = jx - (ct * 0 - st * bigEndLocal);
  const rodBodyY = jy - (st * 0 + ct * bigEndLocal);
  const wct = Math.cos(pistonTheta),
    wst = Math.sin(pistonTheta);
  const pistonBodyX = wx - -wst * scene.wrist_pin;
  const pistonBodyY = wy - wct * scene.wrist_pin;
  return {
    jx,
    jy,
    wx,
    wy,
    rodTheta,
    pistonTheta,
    rodBodyX,
    rodBodyY,
    pistonBodyX,
    pistonBodyY,
    bigEndLocal,
    rodLen,
  };
}

function poseCylinder(scene, bank, journalAngle, crankAngle) {
  const ja = journalAngle + crankAngle;
  const jx = Math.cos(ja) * scene.throw;
  const jy = Math.sin(ja) * scene.throw;
  return poseFromPin(scene, bank, jx, jy, scene.rod);
}

/**
 * Slave rod on master: connecting_rod_node sets angle as (mr_angle + π/2),
 * then getRodJournalPositionLocal/Global about the master body.
 */
function poseSlaveCylinder(scene, bank, slaveJournalAngle, masterPose) {
  const ST = scene.slave_throw || 0;
  const slaveRod = scene.slave_rod || scene.rod;
  // setRodJournalAngle(i, angle + π/2) in connecting_rod_node.h
  const a = slaveJournalAngle + Math.PI / 2;
  const bigEndLocal = masterPose.bigEndLocal;
  const lx = Math.cos(a) * ST;
  const ly = Math.sin(a) * ST + bigEndLocal;
  const ct = Math.cos(masterPose.rodTheta),
    st = Math.sin(masterPose.rodTheta);
  const jx = masterPose.rodBodyX + ct * lx - st * ly;
  const jy = masterPose.rodBodyY + st * lx + ct * ly;
  return poseFromPin(scene, bank, jx, jy, slaveRod);
}

/** Build banks from /api/scene payload */
export function prepareScene(raw) {
  const journals = raw.journals?.length ? raw.journals : [0];
  const banks = (raw.bank_angles || [0]).map((angle, i) => ({
    index: i,
    angle,
    dx: Math.cos(angle + Math.PI / 2),
    dy: Math.sin(angle + Math.PI / 2),
    x: 0,
    y: 0,
    cylinders: (raw.bank_cylinders && raw.bank_cylinders[i]) || 1,
    // Script default 0.5 (cylinder_bank_parameters); not C++ ctor 0.4
    displayDepth:
      raw.bank_display_depths && raw.bank_display_depths[i] != null
        ? raw.bank_display_depths[i]
        : 0.5,
    flip: (raw.flip_display && raw.flip_display[i]) || i % 2,
  }));
  // ConnectingRod::getLayer() == crank rod-journal index (not cylinder ordinal).
  // Shared journals (V-twin / V8) → same layer → same brightness.
  let cylinderJournals = Array.isArray(raw.cylinder_journals)
    ? raw.cylinder_journals.map((x) => x | 0)
    : null;
  let cylinderMounts = Array.isArray(raw.cylinder_mounts) ? raw.cylinder_mounts : null;
  if (!cylinderJournals || cylinderJournals.length === 0) {
    cylinderJournals = [];
    cylinderMounts = [];
    for (const bank of banks) {
      for (let c = 0; c < bank.cylinders; c++) {
        const idx = c % journals.length;
        cylinderJournals.push(idx);
        cylinderMounts.push({ role: "crank", index: idx, layer: idx });
      }
    }
  }
  if (!cylinderMounts || cylinderMounts.length !== cylinderJournals.length) {
    cylinderMounts = cylinderJournals.map((ji) => ({
      role: "crank",
      index: ji % journals.length,
      layer: ji,
    }));
  }
  return {
    ...raw,
    banks,
    journals,
    cylinder_journals: cylinderJournals,
    cylinder_mounts: cylinderMounts,
    slave_journals: raw.slave_journals || [],
    slave_throw: raw.slave_throw,
    slave_rod: raw.slave_rod,
  };
}

export function buildDrawlist(scene, crankAngle) {
  const cmds = [];
  const I = [1, 0, 0, 1, 0, 0];

  for (const bank of scene.banks) {
    const lineWidth = scene.bore * 0.1;
    const margin = lineWidth * 0.25;
    // Same cutaway as esim CylinderBankObject (script default display_depth 0.5).
    const displayDepth = 1.0 - bank.displayDepth;
    const dx = -bank.dy * (margin + scene.bore / 2 + lineWidth / 2);
    const dy = bank.dx * (margin + scene.bore / 2 + lineWidth / 2);
    const top_x = bank.x + bank.dx * (scene.deck + scene.chamber_h);
    const top_y = bank.y + bank.dy * (scene.deck + scene.chamber_h);
    const bottom_x = bank.x + bank.dx * (displayDepth * scene.deck);
    const bottom_y = bank.y + bank.dy * (displayDepth * scene.deck);
    line2d(I, top_x + dx, top_y + dy, bottom_x + dx, bottom_y + dy, lineWidth, PINK, cmds);
    circle2d(I, bottom_x + dx, bottom_y + dy, lineWidth / 2, PINK, cmds);
    line2d(I, top_x - dx, top_y - dy, bottom_x - dx, bottom_y - dy, lineWidth, PINK, cmds);
    circle2d(I, bottom_x - dx, bottom_y - dy, lineWidth / 2, PINK, cmds);
  }

  const grey0 = mix(BG, FG, 0.7);
  const grey1 = mix(BG, FG, 0.6);
  const grey2 = mix(BG, FG, 0.2);
  // Crankshaft is esim Sublayer 2 — emit after rods (below), not here.

  const rodGrey0 = mix(BG, FG, 0.9333);
  const rodGrey1 = mix(BG, FG, 0.8667);
  let cylOrd = 0;
  const nJ = Math.max(1, scene.journals.length);
  // Collect per-cylinder cmds, then emit back→front so layer 0 (bright) sits on top.
  const cylDraw = [];
  // Radial: pose crank-mounted masters first so slaves can read master pin.
  const cylSpecs = [];
  for (const bank of scene.banks) {
    for (let c = 0; c < bank.cylinders; c++, cylOrd++) {
      const mount = scene.cylinder_mounts[cylOrd] || {
        role: "crank",
        index: c % nJ,
        layer: c % nJ,
      };
      cylSpecs.push({ bank, c, mount, ord: cylOrd });
    }
  }
  const poses = new Array(cylSpecs.length);
  for (const spec of cylSpecs) {
    if ((spec.mount.role || "crank") !== "crank") continue;
    const ji = spec.mount.index % nJ;
    poses[spec.ord] = poseCylinder(scene, spec.bank, scene.journals[ji], crankAngle);
  }
  // One master pose for radial slaves (first crank-mounted cylinder).
  const masterPose = poses.find(Boolean) || null;
  for (const spec of cylSpecs) {
    if ((spec.mount.role || "crank") !== "slave") continue;
    const sj = scene.slave_journals || [];
    const sjAng = sj.length ? sj[spec.mount.index % sj.length] : 0;
    if (masterPose && scene.slave_throw) {
      poses[spec.ord] = poseSlaveCylinder(scene, spec.bank, sjAng, masterPose);
    } else {
      // Fallback: treat as crank journal (old behaviour)
      const ji = spec.mount.index % nJ;
      poses[spec.ord] = poseCylinder(scene, spec.bank, scene.journals[ji], crankAngle);
    }
  }

  for (const spec of cylSpecs) {
    const pose = poses[spec.ord];
    if (!pose) continue;
    const layer = spec.mount.layer != null ? spec.mount.layer : 0;
    const rcol = tintByLayer(spec.bank.index % 2 === 0 ? rodGrey0 : rodGrey1, layer);
    const pcol = tintByLayer(FG, layer);
    const s = scene.bore / 2;
    const littleEndLocal = (pose.rodLen || scene.rod) / 2;
    const items = [];
    items.push({
      op: "mesh",
      mesh: "ConnectingRod",
      color: rcol,
      m: setTransform(pose.rodBodyX, pose.rodBodyY, pose.rodTheta, scene.throw, 0, pose.bigEndLocal),
    });
    const rodXform = setTransform(pose.rodBodyX, pose.rodBodyY, pose.rodTheta, 1);
    const isSlaveRod = (spec.mount.role || "crank") === "slave";
    // esim beam starts at bigEnd+0.6*throw; slaves need a bearing disc so the gap
    // doesn't look like a detached rod (mesh alone is easy to miss at catalog scale).
    line2d(
      rodXform,
      0,
      isSlaveRod ? pose.bigEndLocal : pose.bigEndLocal + scene.throw * 0.6,
      0,
      littleEndLocal,
      scene.throw * 0.5,
      rcol,
      items
    );
    if (isSlaveRod) {
      circle2d(rodXform, 0, pose.bigEndLocal, scene.throw * 0.35, rcol, items);
    }
    // Master rod hub + slave journal pins (ConnectingRodObject::generateGeometry).
    const isMasterRod =
      (spec.mount.role || "crank") === "crank" && scene.slave_throw && (scene.slave_journals || []).length;
    if (isMasterRod) {
      circle2d(rodXform, 0, pose.bigEndLocal, scene.slave_throw * 1.5, rcol, items);
      const pinCol = tintByLayer(mix(BG, FG, 0.05), layer);
      const pinR = scene.throw * 0.2;
      for (const sjAng of scene.slave_journals) {
        const a = sjAng + Math.PI / 2;
        const lx = Math.cos(a) * scene.slave_throw;
        const ly = Math.sin(a) * scene.slave_throw + pose.bigEndLocal;
        circle2d(rodXform, lx, ly, pinR, pinCol, items);
      }
    }
    items.push({
      op: "mesh",
      mesh: "Piston",
      color: pcol,
      m: setTransform(
        pose.pistonBodyX,
        pose.pistonBodyY,
        pose.pistonTheta,
        s,
        0,
        -(scene.comp_h + scene.wrist_pin)
      ),
    });
    const pinXform = setTransform(pose.pistonBodyX, pose.pistonBodyY, pose.pistonTheta, 1);
    const isMaster =
      (spec.mount.role || "crank") === "crank" && scene.slave_throw && (scene.slave_journals || []).length;
    // esim: Sublayer 0 = slaves, Sublayer 1 = master (hub + pin holes).
    cylDraw.push({
      layer,
      sublayer: isMaster ? 1 : 0,
      items,
      pin: { xform: pinXform, y: scene.wrist_pin, ring: pcol },
    });
  }
  // Far journal layers first, then slaves before master.
  cylDraw.sort((a, b) => b.layer - a.layer || a.sublayer - b.sublayer);
  const pinMarks = [];
  for (const cd of cylDraw) {
    for (const item of cd.items) cmds.push(item);
    pinMarks.push(cd.pin);
  }

  // Sublayer 2: crank throw/snout on top of rod hub (CrankshaftObject).
  for (let i = scene.journals.length - 1; i >= 0; i--) {
    const col = tintByLayer(grey0, i);
    const m = setTransform(0, 0, crankAngle, scene.throw, 0, 0, scene.journals[i]);
    cmds.push({ op: "mesh", mesh: "Crankshaft", color: col, m });
  }
  {
    const m = setTransform(0, 0, crankAngle, scene.throw, 0, 0, 0);
    cmds.push({ op: "mesh", mesh: "CrankSnout", color: grey1, m });
    cmds.push({ op: "mesh", mesh: "CrankSnoutThreads", color: grey2, m });
  }

  const rollerRadius_mm = 7.62;
  for (const bank of scene.banks) {
    const s = scene.bore / 2;
    const hx = bank.x + bank.dx * (scene.deck + scene.chamber_h);
    const hy = bank.y + bank.dy * (scene.deck + scene.chamber_h);
    const T_headObject = mul(T(hx, hy), R(bank.angle));
    const T_head = mul(T_headObject, S(s));
    cmds.push({ op: "mesh", mesh: "CylinderHead", color: PINK, m: T_head });

    line2d(T_head, -0.689352, 0.085, -0.88632, -0.077975, 0.2, BG, cmds);
    {
      let x0 = -0.689352,
        x1 = -0.88632;
      line2d(T_head, -(x0 + 0.5) - 0.5, 0.085, -(x1 + 0.5) - 0.5, -0.077975, 0.2, BG, cmds);
      x0 = 0.689352;
      x1 = 0.88632;
      line2d(T_head, x0, 0.085, x1, -0.077975, 0.2, BG, cmds);
      line2d(T_head, -(x0 - 0.5) + 0.5, 0.085, -(x1 - 0.5) + 0.5, -0.077975, 0.2, BG, cmds);
      line2d(T_head, -0.5, 0.2, -0.5, 1.5, 0.0917, BG, cmds);
      line2d(T_head, 0.5, 0.2, 0.5, 1.5, 0.0917, BG, cmds);
    }

    const intakeValvePosition = bank.flip ? 0.5 : -0.5;
    const intakeLift = scene.cam_lift * 0.35 * (0.5 + 0.5 * Math.sin(crankAngle * 2 + bank.angle));
    const exhaustLift = scene.cam_lift * 0.35 * (0.5 + 0.5 * Math.sin(crankAngle * 2 + bank.angle + Math.PI));
    const rr_local = rollerRadius_mm / s;

    const drawValve = (localX, color, lift) => {
      const Tv = mul(T_head, T(localX, -lift / s));
      cmds.push({ op: "mesh", mesh: "Valve", color, m: Tv });
      circle2d(Tv, 0, 1.99, (rollerRadius_mm + 0.5) / s, BG, cmds);
      circle2d(Tv, 0, 1.99, rr_local, color, cmds);
      circle2d(Tv, 0, 1.99, rr_local * 0.25, BG, cmds);
    };
    drawValve(intakeValvePosition, BLUE, intakeLift);
    drawValve(-intakeValvePosition, YELLOW, exhaustLift);

    const camY = rollerRadius_mm + 0.5 + 1.99 * s + scene.cam_base;
    const T_inCam = mul(mul(T_headObject, T(intakeValvePosition * s, camY)), R(crankAngle * 2 + bank.angle));
    cam2d(T_inCam, 0, 0, scene.cam_base, rollerRadius_mm, scene.cam_lift, BLUE, cmds);
    circle2d(T_inCam, 0, 0, rollerRadius_mm * 0.25, BG, cmds);
    const T_exCam = mul(
      mul(T_headObject, T(-intakeValvePosition * s, camY)),
      R(crankAngle * 2 + bank.angle + 0.3)
    );
    cam2d(T_exCam, 0, 0, scene.cam_base, rollerRadius_mm, scene.cam_lift, ORANGE, cmds);
    circle2d(T_exCam, 0, 0, rollerRadius_mm * 0.25, BG, cmds);
  }

  // Wrist pins last (above rods/pistons). Larger than engine-sim formula so they read at catalog scale.
  const pinR = Math.max(scene.bore * 0.08, 5);
  for (const p of pinMarks) {
    circle2d(p.xform, 0, p.y, pinR * 1.25, p.ring, cmds);
    circle2d(p.xform, 0, p.y, pinR, "#000000", cmds);
  }

  return { bg: BG, commands: cmds };
}

/** Fixed view fit from scene extents (no per-frame AABB). */
export function viewFromScene(scene, canvasW, canvasH) {
  const span = scene.deck + scene.chamber_h + scene.bore * 2.8 + scene.throw;
  const nBanks = scene.banks?.length || 1;
  const isRadial = nBanks >= 5 || (scene.slave_throw != null && nBanks >= 3);
  if (isRadial) {
    // Crank-centered: fit full diameter so circles stay round and no bank is clipped.
    const radius = span;
    const scale = (Math.min(canvasW, canvasH) * 0.92) / (2 * radius);
    return { scale, cx: canvasW * 0.5, cy: canvasH * 0.5, midX: 0, midY: 0 };
  }
  const scale = (Math.min(canvasW, canvasH) * 0.48) / span;
  return { scale, cx: canvasW * 0.5, cy: canvasH * 0.72, midX: 0, midY: span * 0.35 };
}
