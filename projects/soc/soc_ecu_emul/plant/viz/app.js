(() => {
  const canvas = document.getElementById("stage");
  const ctx = canvas.getContext("2d");
  const $ = (id) => document.getElementById(id);

  let state = {
    rpm: 0,
    angle: 0,
    stroke: "4T",
    n_cyl: 1,
    layout: "inline",
    target_rpm: 1200,
    btdc: 15,
    pw_us: 2000,
    map_kpa: 80,
    load_nm: 5,
    sparks: 0,
    sync: false,
  };

  const LAYOUT_RU = {
    inline: "рядный",
    v60: "V60°",
    v90: "V90°",
    v: "V90°",
    boxer: "оппозит",
  };

  const sparksVisual = []; // {ch, until}
  let suppressSync = false; // don't fight user while dragging

  /** Engine synth — simple graph, cancelable gains (no silent-after-mute bug). */
  const audio = {
    ctx: null,
    master: null,
    rumbleGain: null,
    filter: null,
    tone1: null,
    tone2: null,
    toneGain: null,
    toneLP: null,
    enabled: false,
    volume: 0.45,
    lastSparkAt: 0,
    twoStroke: false,

    _setGain(param, value) {
      const t = this.ctx.currentTime;
      param.cancelScheduledValues(t);
      param.setValueAtTime(value, t);
    },

    async start() {
      try {
        if (!this.ctx) {
          const AC = window.AudioContext || window.webkitAudioContext;
          this.ctx = new AC();
          this.master = this.ctx.createGain();
          this.master.gain.value = this.volume;
          this.master.connect(this.ctx.destination);

          const len = Math.floor(this.ctx.sampleRate * 1.5);
          const buf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
          const data = buf.getChannelData(0);
          for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;
          const noise = this.ctx.createBufferSource();
          noise.buffer = buf;
          noise.loop = true;
          this.filter = this.ctx.createBiquadFilter();
          this.filter.type = "lowpass";
          this.filter.frequency.value = 400;
          this.rumbleGain = this.ctx.createGain();
          this.rumbleGain.gain.value = 0.08;
          noise.connect(this.filter);
          this.filter.connect(this.rumbleGain);
          this.rumbleGain.connect(this.master);
          noise.start();

          this.tone1 = this.ctx.createOscillator();
          this.tone1.type = "sawtooth";
          this.tone1.frequency.value = 40;
          this.tone2 = this.ctx.createOscillator();
          this.tone2.type = "triangle";
          this.tone2.frequency.value = 80;
          this.toneLP = this.ctx.createBiquadFilter();
          this.toneLP.type = "lowpass";
          this.toneLP.frequency.value = 2000;
          this.toneGain = this.ctx.createGain();
          this.toneGain.gain.value = 0.18;
          const harm = this.ctx.createGain();
          harm.gain.value = 0.5;
          this.tone1.connect(this.toneLP);
          this.tone2.connect(harm);
          harm.connect(this.toneLP);
          this.toneLP.connect(this.toneGain);
          this.toneGain.connect(this.master);
          this.tone1.start();
          this.tone2.start();
        }
        if (this.ctx.state === "suspended") await this.ctx.resume();
        this.enabled = true;
        this._setGain(this.master.gain, this.volume);
        this.update(state);
      } catch (err) {
        console.error("audio start failed", err);
        this.enabled = false;
        throw err;
      }
    },

    stop() {
      this.enabled = false;
      if (!this.ctx || !this.master) return;
      this._setGain(this.master.gain, 0);
      if (this.ctx.state === "running") this.ctx.suspend();
    },

    setVolume(pct) {
      this.volume = Math.max(0, Math.min(1, pct / 100));
      if (this.master && this.enabled) this._setGain(this.master.gain, this.volume);
    },

    update(s) {
      if (!this.enabled || !this.ctx || !this.tone1) return;
      const t = this.ctx.currentTime;
      const rpm = Math.max(400, s.rpm || 800);
      const is2t = s.stroke === "2T";
      this.twoStroke = is2t;
      const crankHz = rpm / 60;
      const load = (s.map_kpa || 80) / 100;

      this.tone1.frequency.setTargetAtTime(crankHz, t, 0.05);
      this.tone2.frequency.setTargetAtTime(crankHz * 2, t, 0.05);
      const bright = is2t
        ? 2200 + Math.min(4000, rpm * 0.22)
        : 900 + Math.min(2200, rpm * 0.15);
      this.toneLP.frequency.setTargetAtTime(bright, t, 0.08);
      // louder bed so it's obvious the synth is alive
      const toneLvl = (is2t ? 0.22 : 0.14) * (0.7 + 0.3 * load);
      this._setGain(this.toneGain.gain, toneLvl);
      this.filter.frequency.setTargetAtTime(is2t ? 600 : 350 + rpm * 0.02, t, 0.1);
      this._setGain(this.rumbleGain.gain, is2t ? 0.04 : 0.09);
      this._setGain(this.master.gain, this.volume);
    },

    sparkClick() {
      if (!this.enabled || !this.ctx || !this.master) return;
      const now = performance.now();
      const minGap = this.twoStroke ? 45 : 16;
      if (now - this.lastSparkAt < minGap) return;
      this.lastSparkAt = now;
      const t = this.ctx.currentTime;
      const o = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      o.type = "triangle";
      o.frequency.value = (this.twoStroke ? 380 : 650) + Math.random() * 180;
      const lvl = (this.twoStroke ? 0.03 : 0.06) * this.volume;
      g.gain.setValueAtTime(lvl, t);
      g.gain.exponentialRampToValueAtTime(0.001, t + 0.03);
      o.connect(g);
      g.connect(this.master);
      o.start(t);
      o.stop(t + 0.035);
    },
  };

  /** Cylinder seats: local bore is vertical (plug at -Y); ang tilts the bank. */
  function layoutSeats(layout, n, ox, oy) {
    const seats = [];
    let lay = layout || "inline";
    if (lay === "v") lay = "v90";
    if (lay === "v60" || lay === "v90") {
      const left = Math.ceil(n / 2);
      const right = n - left;
      // bank tilt from vertical = half of included V angle
      const included = lay === "v60" ? 60 : 90;
      const bank = ((included / 2) * Math.PI) / 180;
      const spread = included >= 90 ? 52 : 38;
      for (let i = 0; i < left; i++) {
        const t = left <= 1 ? 0.5 : i / (left - 1);
        seats.push({
          ch: i,
          x: ox - spread - t * 16,
          y: oy - 95 + t * 28,
          ang: -bank,
        });
      }
      for (let i = 0; i < right; i++) {
        const t = right <= 1 ? 0.5 : i / (right - 1);
        seats.push({
          ch: left + i,
          x: ox + spread + t * 16,
          y: oy - 95 + t * 28,
          ang: bank,
        });
      }
    } else if (lay === "boxer") {
      const left = Math.ceil(n / 2);
      const right = n - left;
      for (let i = 0; i < left; i++) {
        const t = left <= 1 ? 0.5 : i / Math.max(1, left - 1);
        seats.push({
          ch: i,
          x: ox - 100,
          y: oy - 55 + t * 100,
          ang: -Math.PI / 2, // horizontal, plug to the left
        });
      }
      for (let i = 0; i < right; i++) {
        const t = right <= 1 ? 0.5 : i / Math.max(1, right - 1);
        seats.push({
          ch: left + i,
          x: ox + 100,
          y: oy - 55 + t * 100,
          ang: Math.PI / 2, // horizontal, plug to the right
        });
      }
    } else {
      // inline — upright bores in a row along the crank (side view)
      const span = Math.min(300, 40 * n);
      for (let i = 0; i < n; i++) {
        const t = n === 1 ? 0.5 : i / (n - 1);
        seats.push({
          ch: i,
          x: ox - span / 2 + t * span,
          y: oy - 95,
          ang: 0, // vertical
        });
      }
    }
    return seats;
  }

  function drawCylinder(seat, piston, flashing) {
    const len = 52;
    const w = 22;
    ctx.save();
    ctx.translate(seat.x, seat.y);
    ctx.rotate(seat.ang);
    // bore
    ctx.fillStyle = "#1a222e";
    ctx.strokeStyle = flashing ? "#ffb020" : "#4a5d75";
    ctx.lineWidth = flashing ? 2.5 : 1.5;
    ctx.beginPath();
    ctx.rect(-w / 2, -len / 2, w, len);
    ctx.fill();
    ctx.stroke();
    // piston
    const py = -len / 2 + 8 + piston * (len - 22);
    ctx.fillStyle = flashing ? "#ffb020" : "#6b7c93";
    ctx.fillRect(-w / 2 + 3, py, w - 6, 12);
    // spark plug end
    ctx.fillStyle = flashing ? "#ffe08a" : "#3d4f66";
    ctx.beginPath();
    ctx.arc(0, -len / 2 - 4, flashing ? 5 : 3, 0, Math.PI * 2);
    ctx.fill();
    // channel #
    ctx.rotate(-seat.ang);
    ctx.fillStyle = "#9aa8bc";
    ctx.font = "10px ui-monospace, monospace";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(String(seat.ch), 0, len / 2 + 14);
    ctx.restore();
  }

  function draw() {
    const w = canvas.width;
    const h = canvas.height;
    ctx.clearRect(0, 0, w, h);

    const n = Math.max(1, state.n_cyl | 0);
    const cycle = state.stroke === "2T" ? 360 : 720;
    const lay = state.layout || "inline";
    const now = performance.now();

    // --- left: crank timing wheel ---
    const cx = 150;
    const cy = h * 0.55;
    const R = 78;

    ctx.fillStyle = "#8b9bb0";
    ctx.font = "12px system-ui, sans-serif";
    ctx.textAlign = "left";
    ctx.fillText("угол коленвала · 36-1", 24, 28);
    ctx.fillStyle = "#e8eef7";
    ctx.font = "600 26px ui-monospace, monospace";
    ctx.fillText(`${Math.round(state.rpm)}`, 24, 58);
    ctx.fillStyle = "#8b9bb0";
    ctx.font = "11px system-ui, sans-serif";
    ctx.fillText("об/мин", 24, 74);

    ctx.beginPath();
    ctx.arc(cx, cy, R + 18, 0, Math.PI * 2);
    ctx.strokeStyle = "#1c2736";
    ctx.lineWidth = 10;
    ctx.stroke();

    const rad = (state.angle * Math.PI) / 180;
    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(rad);
    ctx.fillStyle = "#2a3648";
    ctx.beginPath();
    ctx.arc(0, 0, R * 0.22, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#6b7c93";
    ctx.lineWidth = 8;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(R * 0.72, 0);
    ctx.stroke();
    ctx.strokeStyle = "#3d4f66";
    ctx.lineWidth = 2;
    for (let i = 0; i < 35; i++) {
      const a = (i * 10 * Math.PI) / 180;
      ctx.beginPath();
      ctx.moveTo(Math.cos(a) * (R + 4), Math.sin(a) * (R + 4));
      ctx.lineTo(Math.cos(a) * (R + 12), Math.sin(a) * (R + 12));
      ctx.stroke();
    }
    ctx.restore();

    for (let i = 0; i < n; i++) {
      const tdc = (i * cycle) / n;
      const fire = (tdc - state.btdc + cycle) % cycle;
      const fa = ((fire % 360) * Math.PI) / 180;
      const markR = R + 18 + (cycle > 360 && fire >= 360 ? 8 : 0);
      ctx.beginPath();
      ctx.arc(cx + Math.cos(fa) * markR, cy + Math.sin(fa) * markR, 2.5, 0, Math.PI * 2);
      ctx.fillStyle = "#3d9cf0";
      ctx.fill();
    }

    // --- right: engine layout schematic ---
    const ox = 560;
    const oy = h * 0.58;
    ctx.fillStyle = "#8b9bb0";
    ctx.font = "12px system-ui, sans-serif";
    ctx.textAlign = "left";
    const title = `${LAYOUT_RU[lay] || lay} · ${state.stroke} · ${n} цил.`;
    ctx.fillText(title, 340, 28);
    ctx.fillStyle = "#5a6a80";
    ctx.font = "11px system-ui, sans-serif";
    ctx.fillText("схема блока (компоновка) · вспышка = искра", 340, 46);

    // crank center mark under block
    ctx.strokeStyle = "#2a3648";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(ox - 120, oy + 10);
    ctx.lineTo(ox + 120, oy + 10);
    ctx.stroke();
    ctx.fillStyle = "#3d4f66";
    ctx.beginPath();
    ctx.arc(ox, oy + 10, 8, 0, Math.PI * 2);
    ctx.fill();

    const seats = layoutSeats(lay, n, ox, oy);
    for (const seat of seats) {
      const tdc = (seat.ch * cycle) / n;
      // piston position along bore from crank phase (visual only)
      const phase = ((state.angle - (tdc % 360)) * Math.PI) / 180;
      const piston = (1 - Math.cos(phase)) * 0.5; // 0 at TDC-ish visual
      const flashing = sparksVisual.some((s) => s.ch === seat.ch && s.until > now);
      drawCylinder(seat, piston, flashing);
    }

    requestAnimationFrame(draw);
  }

  function syncControlsFromState() {
    if (suppressSync) return;
    $("stroke").textContent = state.stroke;
    $("ncyl").textContent = state.n_cyl;
    $("layout").textContent = LAYOUT_RU[state.layout] || state.layout;
    $("btdc").textContent = state.btdc;
    $("pw").textContent = Math.round(state.pw_us);
    $("ctrl-stroke").value = state.stroke;
    $("ctrl-ncyl").value = String(state.n_cyl);
    $("ctrl-layout").value = state.layout || "inline";
    $("ctrl-rpm").value = String(Math.round(state.target_rpm));
    $("ctrl-rpmv").textContent = Math.round(state.target_rpm);
    $("ctrl-btdc").value = String(Math.round(state.btdc));
    $("ctrl-btdcv").textContent = Math.round(state.btdc);
    $("ctrl-pw").value = String(Math.round(state.pw_us));
    $("ctrl-pwv").textContent = Math.round(state.pw_us);
    $("load").value = String(state.load_nm);
    $("loadv").textContent = state.load_nm;
    $("map").value = String(Math.round(state.map_kpa));
    $("mapv").textContent = Math.round(state.map_kpa);
  }

  function applyReadouts() {
    $("rpm").textContent = Math.round(state.rpm);
    $("angle").textContent = state.angle.toFixed(0);
    $("sparks").textContent = state.sparks;
    $("sync").textContent = state.sync ? "ok" : "—";
    syncControlsFromState();
  }

  function onSparkEvents(evts) {
    const now = performance.now();
    // Flash must be shorter than inter-spark gap, else circles stay orange forever.
    const cycle = state.stroke === "2T" ? 1 : 2;
    const n = Math.max(1, state.n_cyl | 0);
    const gapMs = (60000 * cycle) / Math.max(400, state.rpm) / n;
    const flashMs = Math.max(30, Math.min(90, gapMs * 0.35));
    for (const e of evts || []) {
      const ch = e.ch | 0;
      // one active flash per channel
      const idx = sparksVisual.findIndex((s) => s.ch === ch);
      if (idx >= 0) sparksVisual[idx].until = now + flashMs;
      else sparksVisual.push({ ch, until: now + flashMs });
      audio.sparkClick();
    }
    for (let i = sparksVisual.length - 1; i >= 0; i--) {
      if (sparksVisual[i].until < now) sparksVisual.splice(i, 1);
    }
  }

  async function postControl(body) {
    await fetch("/api/control", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  }

  function bindControl(id, key, cast, labelId) {
    const el = $(id);
    const start = () => { suppressSync = true; };
    const end = () => { suppressSync = false; };
    el.addEventListener("pointerdown", start);
    el.addEventListener("pointerup", end);
    el.addEventListener("change", end);
    el.addEventListener("input", (e) => {
      const v = cast(e.target.value);
      if (labelId) $(labelId).textContent = v;
      postControl({ [key]: v });
    });
  }

  function connect() {
    const es = new EventSource("/api/stream");
    const st = $("status");
    es.onopen = () => {
      st.textContent = "live · SSE";
      st.className = "status ok";
    };
    es.onerror = () => {
      st.textContent = "нет связи с serve.py";
      st.className = "status bad";
    };
    es.onmessage = (msg) => {
      try {
        const data = JSON.parse(msg.data);
        state = { ...state, ...data };
        onSparkEvents(data.spark_events);
        applyReadouts();
        audio.update(state);
      } catch (_) { /* ignore */ }
    };
  }

  document.querySelectorAll("[data-preset]").forEach((btn) => {
    btn.addEventListener("click", () => {
      suppressSync = false;
      postControl({ preset: btn.dataset.preset });
    });
  });

  bindControl("ctrl-stroke", "stroke", String);
  bindControl("ctrl-ncyl", "n_cyl", (v) => Number(v));
  bindControl("ctrl-layout", "layout", String);
  bindControl("ctrl-rpm", "target_rpm", Number, "ctrl-rpmv");
  bindControl("ctrl-btdc", "btdc", Number, "ctrl-btdcv");
  bindControl("ctrl-pw", "pw_us", Number, "ctrl-pwv");
  bindControl("load", "load_nm", Number, "loadv");
  bindControl("map", "map_kpa", Number, "mapv");

  const soundBtn = $("sound-toggle");
  soundBtn.addEventListener("click", async () => {
    try {
      if (audio.enabled) {
        audio.stop();
        soundBtn.textContent = "включить";
      } else {
        await audio.start();
        soundBtn.textContent = "выключить";
      }
    } catch (_) {
      soundBtn.textContent = "ошибка звука";
    }
  });
  $("sound-vol").value = "45";
  $("sound-volv").textContent = "45";
  $("sound-vol").addEventListener("input", (e) => {
    const v = Number(e.target.value);
    $("sound-volv").textContent = v;
    audio.setVolume(v);
  });

  connect();
  requestAnimationFrame(draw);
})();
