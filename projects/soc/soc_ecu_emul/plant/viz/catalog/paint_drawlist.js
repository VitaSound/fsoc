/** Paint drawlists; Path2D cache for engine-sim meshes. */

const pathCache = new Map();

export async function loadMeshes() {
  const r = await fetch("/api/meshes");
  if (!r.ok) throw new Error("meshes " + r.status);
  pathCache.clear();
  return r.json();
}

export async function fetchScene(engineId) {
  const q = new URLSearchParams({ id: engineId || "" });
  const r = await fetch("/api/scene?" + q);
  const j = await r.json();
  if (!r.ok) throw new Error(j.error || "scene failed");
  return j;
}

function meshPath(meshes, name) {
  let p = pathCache.get(name);
  if (p) return p;
  const mesh = meshes[name];
  if (!mesh) return null;
  p = new Path2D();
  const idx = mesh.indices;
  const v = mesh.vertices;
  for (let i = 0; i + 2 < idx.length; i += 3) {
    const a = v[idx[i]],
      b = v[idx[i + 1]],
      c = v[idx[i + 2]];
    p.moveTo(a[0], a[1]);
    p.lineTo(b[0], b[1]);
    p.lineTo(c[0], c[1]);
    p.closePath();
  }
  pathCache.set(name, p);
  return p;
}

/**
 * @param view {scale,cx,cy,midX,midY}  screen: sx = cx+(x-midX)*scale, sy = cy-(y-midY)*scale
 */
export function paintDrawlist(ctx, canvas, drawlist, meshes, label, view) {
  const w = canvas.width;
  const h = canvas.height;
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.fillStyle = drawlist.bg || "#0E1012";
  ctx.fillRect(0, 0, w, h);

  const { scale, cx, cy, midX, midY } = view;
  // world → screen: translate then scaleY flip
  // sx = cx + (x-midX)*scale; sy = cy - (y-midY)*scale
  // ctx: translate(cx,cy) scale(scale,-scale) translate(-midX,-midY)
  ctx.setTransform(scale, 0, 0, -scale, cx - midX * scale, cy + midY * scale);

  for (const c of drawlist.commands || []) {
    if (c.op === "tris") {
      ctx.fillStyle = c.color;
      const xy = c.xy;
      ctx.beginPath();
      for (let i = 0; i + 5 < xy.length; i += 6) {
        ctx.moveTo(xy[i], xy[i + 1]);
        ctx.lineTo(xy[i + 2], xy[i + 3]);
        ctx.lineTo(xy[i + 4], xy[i + 5]);
        ctx.closePath();
      }
      ctx.fill();
    } else if (c.op === "mesh") {
      const path = meshPath(meshes, c.mesh);
      if (!path) continue;
      const m = c.m;
      ctx.save();
      // world = M * local; canvas already has world→screen
      ctx.transform(m[0], m[1], m[2], m[3], m[4], m[5]);
      ctx.fillStyle = c.color;
      ctx.fill(path, "nonzero");
      ctx.restore();
    }
  }

  ctx.setTransform(1, 0, 0, 1, 0, 0);
  if (label) {
    ctx.fillStyle = "#FFFFFF";
    ctx.font = "600 18px ui-monospace, monospace";
    ctx.fillText(label, 16, 28);
  }
}
