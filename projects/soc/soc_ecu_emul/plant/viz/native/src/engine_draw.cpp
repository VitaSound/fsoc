// Headless drawer adapted from ange-yaghi/engine-sim:
//   cylinder_bank_object.cpp, connecting_rod_object.cpp, piston_object.cpp,
//   crankshaft_object.cpp, cylinder_head_object.cpp, simulation_object.cpp,
//   geometry_generator.cpp (generateLine2d / generateCircle2d / generateCam)
//
// Meshes: same assets as DrawModel("Piston"|…) from assets/assets.ysce
// (loaded from meshes.json produced by extract_ysce_meshes.py).
//
// stdin  JSON: engine params + crank_angle
// stdout JSON: drawlist {bg, commands:[{op,color,xy|mesh,m}]}

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

constexpr float PI = 3.14159265358979323846f;
constexpr float TWO_PI = 6.28318530717958647692f;

struct Vec2 {
    float x = 0, y = 0;
};
struct Color {
    float r, g, b;
};

Color hex(const char *h) {
    unsigned v = 0;
    if (h[0] == '#') ++h;
    std::sscanf(h, "%x", &v);
    return {float((v >> 16) & 255) / 255.f, float((v >> 8) & 255) / 255.f, float(v & 255) / 255.f};
}
Color mix(Color a, Color b, float t) {
    return {a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t};
}
Color tintByLayer(Color col, Color bg, int layers) {
    // simulation_object.cpp tintByLayer
    for (int i = 0; i < layers; ++i)
        col = {col.r * 0.3f + bg.r * 0.7f, col.g * 0.3f + bg.g * 0.7f, col.b * 0.3f + bg.b * 0.7f};
    return col;
}
std::string css(Color c) {
    char buf[16];
    std::snprintf(buf, sizeof buf, "#%02X%02X%02X",
                  int(c.r * 255 + 0.5f), int(c.g * 255 + 0.5f), int(c.b * 255 + 0.5f));
    return buf;
}

// Affine 2D: column-major-ish as [a c e; b d f]  →  x' = a*x + c*y + e
struct Mat3 {
    float a = 1, b = 0, c = 0, d = 1, e = 0, f = 0;
    static Mat3 T(float x, float y) { return {1, 0, 0, 1, x, y}; }
    static Mat3 R(float th) {
        float ct = std::cos(th), st = std::sin(th);
        return {ct, st, -st, ct, 0, 0};
    }
    static Mat3 S(float s) { return {s, 0, 0, s, 0, 0}; }
    Mat3 operator*(const Mat3 &o) const {
        // this * o
        return {a * o.a + c * o.b, b * o.a + d * o.b, a * o.c + c * o.d, b * o.c + d * o.d,
                a * o.e + c * o.f + e, b * o.e + d * o.f + f};
    }
    Vec2 apply(float x, float y) const { return {a * x + c * y + e, b * x + d * y + f}; }
};

// --- minimal JSON helpers (read flat numbers / arrays we need) ---
std::string readAllStdin() {
    std::ostringstream ss;
    ss << std::cin.rdbuf();
    return ss.str();
}

bool findKey(const std::string &j, const char *key, size_t &pos) {
    std::string pat = std::string("\"") + key + "\"";
    size_t p = j.find(pat, pos);
    if (p == std::string::npos) return false;
    p = j.find(':', p);
    if (p == std::string::npos) return false;
    pos = p + 1;
    while (pos < j.size() && (j[pos] == ' ' || j[pos] == '\n' || j[pos] == '\t')) ++pos;
    return true;
}

double readNumber(const std::string &j, const char *key, double def = 0) {
    size_t p = 0;
    if (!findKey(j, key, p)) return def;
    return std::strtod(j.c_str() + p, nullptr);
}

std::string readString(const std::string &j, const char *key, const std::string &def = {}) {
    size_t p = 0;
    if (!findKey(j, key, p) || j[p] != '"') return def;
    size_t e = j.find('"', p + 1);
    return j.substr(p + 1, e - p - 1);
}

std::vector<double> readArray(const std::string &j, const char *key) {
    size_t p = 0;
    std::vector<double> out;
    if (!findKey(j, key, p) || j[p] != '[') return out;
    ++p;
    while (p < j.size() && j[p] != ']') {
        while (p < j.size() && (j[p] == ' ' || j[p] == ',' || j[p] == '\n')) ++p;
        if (p >= j.size() || j[p] == ']') break;
        char *end = nullptr;
        out.push_back(std::strtod(j.c_str() + p, &end));
        p = end - j.c_str();
    }
    return out;
}

// --- GeometryGenerator lite → triangle list ---
struct DrawCmd {
    std::string op; // "tris" | "mesh"
    std::string color;
    std::string mesh;
    std::vector<float> xy; // flat tris for procedural
    Mat3 m;                // for mesh
};

struct Emitter {
    std::vector<DrawCmd> cmds;
    Color cur{1, 1, 1};
    Mat3 xform;

    void setColor(Color c) { cur = c; }
    void setXform(Mat3 m) { xform = m; }

    void trisLocal(const std::vector<Vec2> &pts, const std::vector<int> &idx) {
        DrawCmd c;
        c.op = "tris";
        c.color = css(cur);
        c.xy.reserve(idx.size() * 2);
        for (int i : idx) {
            Vec2 w = xform.apply(pts[i].x, pts[i].y);
            c.xy.push_back(w.x);
            c.xy.push_back(w.y);
        }
        cmds.push_back(std::move(c));
    }

    void mesh(const char *name) {
        DrawCmd c;
        c.op = "mesh";
        c.mesh = name;
        c.color = css(cur);
        c.m = xform;
        cmds.push_back(std::move(c));
    }

    // geometry_generator.cpp generateLine2d
    void line2d(float x0, float y0, float x1, float y1, float lineWidth) {
        float dx = x1 - x0, dy = y1 - y0;
        float length = std::sqrt(dx * dx + dy * dy);
        if (length < 1e-9f) return;
        float dir_x = dx / length, dir_y = dy / length;
        float perp_x = -dir_y, perp_y = dir_x;
        float hw = lineWidth / 2;
        std::vector<Vec2> v = {
            {x0 + perp_x * hw, y0 + perp_y * hw},
            {x0 - perp_x * hw, y0 - perp_y * hw},
            {x1 + perp_x * hw, y1 + perp_y * hw},
            {x1 - perp_x * hw, y1 - perp_y * hw},
        };
        trisLocal(v, {0, 1, 2, 1, 3, 2});
    }

    // geometry_generator.cpp generateCircle2d (fan)
    void circle2d(float cx, float cy, float radius, float maxEdge = 0.05f) {
        if (radius <= 0) return;
        float angle = std::asin(std::min(0.99f, maxEdge / (2 * radius))) * 2;
        angle = std::min(angle, PI * 0.95f);
        int segs = std::max(3, (int)std::ceil(TWO_PI / angle));
        std::vector<Vec2> v;
        v.push_back({cx, cy});
        for (int i = 0; i < segs; ++i) {
            float a = TWO_PI * i / segs;
            v.push_back({cx + std::cos(a) * radius, cy + std::sin(a) * radius});
        }
        std::vector<int> idx;
        for (int i = 0; i < segs; ++i) {
            idx.push_back(0);
            idx.push_back(1 + i);
            idx.push_back(1 + ((i + 1) % segs));
        }
        trisLocal(v, idx);
    }

    // geometry_generator.cpp generateCam — harmonic lift stand-in when no Function*
    void cam(float cx, float cy, float baseRadius, float rollerRadius, float liftAmp, float maxEdge = 0.05f) {
        float angle = std::asin(std::min(0.99f, maxEdge / (2 * std::max(baseRadius, 1e-4f)))) * 2;
        angle = std::min(angle, PI - 0.05f);
        int segs = std::max(3, (int)std::ceil(TWO_PI / angle));
        float angleStep = TWO_PI / segs;
        float baseRoller = baseRadius + rollerRadius;
        std::vector<float> px(segs), py(segs);
        float lastx = 0, lasty = 0;
        for (int i = 0; i < segs; ++i) {
            float a0 = angleStep * i;
            float x = std::cos(a0 + PI / 2);
            float y = std::sin(a0 + PI / 2);
            // crude lobe: lift near a0≈0
            float aa = a0 - PI;
            while (aa > PI) aa -= TWO_PI;
            while (aa < -PI) aa += TWO_PI;
            float lift = 0;
            if (std::fabs(aa) < PI / 3)
                lift = liftAmp * std::cos(aa / (PI / 3) * (PI / 2));
            float rp = baseRoller + lift;
            float rx = cx + x * rp, ry = cy + y * rp;
            float dx = -1, dy = 0;
            if (i != 0) {
                dx = rx - lastx;
                dy = ry - lasty;
                float mag = std::sqrt(dx * dx + dy * dy);
                if (mag > 1e-9f) {
                    dx /= mag;
                    dy /= mag;
                }
            }
            lastx = rx;
            lasty = ry;
            px[i] = rx - dy * rollerRadius;
            py[i] = ry + dx * rollerRadius;
        }
        std::vector<Vec2> v;
        v.push_back({cx, cy});
        for (int i = 0; i < segs; ++i) {
            int prev = (i - 1 + segs) % segs;
            int next = (i + 1) % segs;
            v.push_back({(px[prev] + px[next]) * 0.5f, (py[prev] + py[next]) * 0.5f});
        }
        std::vector<int> idx;
        for (int i = 0; i < segs; ++i) {
            idx.push_back(0);
            idx.push_back(i + 1);
            idx.push_back(1 + ((i + 1) % segs));
        }
        trisLocal(v, idx);
    }
};

// setTransform from simulation_object.cpp — body at (bx,by) with theta, local (lx,ly), scale, extra angle
Mat3 setTransform(float bx, float by, float theta, float scale, float lx = 0, float ly = 0, float angle = 0) {
    // localToWorld(lx,ly): rotate by theta then + body pos
    float ct = std::cos(theta), st = std::sin(theta);
    float px = bx + ct * lx - st * ly;
    float py = by + st * lx + ct * ly;
    return Mat3::T(px, py) * Mat3::R(theta + angle) * Mat3::S(scale);
}

struct Bank {
    float angle = 0;
    float dx = 0, dy = 1;
    float x = 0, y = 0;
    int cylinders = 1;
    int index = 0;
    float displayDepth = 0.5f; // script cylinder_bank_parameters default
};

struct Input {
    float bore = 80, throwMm = 35, rod = 100, compH = 30, wristPin = 0;
    float deck = 160, chamberH = 5;
    float camBase = 12, camLift = 6;
    float crankAngle = 0;
    std::vector<Bank> banks;
    std::vector<float> journals;
    std::vector<int> cylinderJournals; // draw-order → journal index (= getLayer)
    std::vector<int> flip; // per bank
    std::string meshesPath;
};

Input parseInput(const std::string &j) {
    Input in;
    in.bore = (float)readNumber(j, "bore", 80);
    in.throwMm = (float)readNumber(j, "throw", 35);
    in.rod = (float)readNumber(j, "rod", 100);
    in.compH = (float)readNumber(j, "comp_h", 30);
    in.wristPin = (float)readNumber(j, "wrist_pin", 0);
    in.deck = (float)readNumber(j, "deck", 160);
    in.chamberH = (float)readNumber(j, "chamber_h", 5);
    in.camBase = (float)readNumber(j, "cam_base", in.bore * 0.15);
    in.camLift = (float)readNumber(j, "cam_lift", in.bore * 0.08);
    in.crankAngle = (float)readNumber(j, "crank_angle", 0);
    in.meshesPath = readString(j, "meshes_path");
    auto angs = readArray(j, "bank_angles");
    auto ncyl = readArray(j, "bank_cylinders");
    auto flips = readArray(j, "flip_display");
    auto ddepths = readArray(j, "bank_display_depths");
    for (double v : readArray(j, "journals")) in.journals.push_back((float)v);
    for (double v : readArray(j, "cylinder_journals"))
        in.cylinderJournals.push_back((int)v);
    if (angs.empty()) angs = {0};
    for (size_t i = 0; i < angs.size(); ++i) {
        Bank b;
        b.index = (int)i;
        b.angle = (float)angs[i];
        b.dx = std::cos(b.angle + PI / 2);
        b.dy = std::sin(b.angle + PI / 2);
        b.cylinders = (i < ncyl.size()) ? (int)ncyl[i] : 1;
        b.displayDepth = (i < ddepths.size()) ? (float)ddepths[i] : 0.5f;
        in.banks.push_back(b);
        in.flip.push_back((i < flips.size()) ? (int)flips[i] : (int)(i % 2));
    }
    if (in.journals.empty()) {
        int n = 0;
        for (auto &b : in.banks) n += b.cylinders;
        in.journals.assign(std::max(1, n), 0.f);
    }
    if (in.cylinderJournals.empty()) {
        // Shared-journal V heuristic: cyl c on each bank → journal c
        int nJ = std::max(1, (int)in.journals.size());
        for (auto &b : in.banks) {
            for (int c = 0; c < b.cylinders; ++c)
                in.cylinderJournals.push_back(c % nJ);
        }
    }
    return in;
}

struct Pose {
    float jx, jy, wx, wy, rodTheta, pistonTheta;
    float rodBodyX, rodBodyY;       // SCS COM (centerOfMass=0 → geometric mid)
    float pistonBodyX, pistonBodyY; // piston body origin (wrist at local 0,wristPin)
};

Pose poseCylinder(const Input &in, const Bank &bank, float journalAngle) {
    // slider-crank stand-in for SCS
    float ja = journalAngle + in.crankAngle;
    float jx = std::cos(ja) * in.throwMm;
    float jy = std::sin(ja) * in.throwMm;
    float px = -bank.dy, py = bank.dx;
    float along = jx * bank.dx + jy * bank.dy;
    float across = jx * px + jy * py;
    float disc = std::max(0.f, in.rod * in.rod - across * across);
    float wristAlong = along + std::sqrt(disc);
    float wx = bank.dx * wristAlong;
    float wy = bank.dy * wristAlong;
    Pose p;
    p.jx = jx;
    p.jy = jy;
    p.wx = wx;
    p.wy = wy;
    // rod +Y local along journal→wrist (mesh ConnectingRod grows +Y from big end)
    p.rodTheta = std::atan2(wy - jy, wx - jx) - PI / 2;
    // placeCylinder: piston->m_body.theta = bank->getAngle() + π
    p.pistonTheta = bank.angle + PI;
    // body.p such that localToWorld(0, bigEndLocal) = journal
    // bigEndLocal = -rod/2 (centerOfMass 0)
    float bigEndLocal = -(in.rod / 2.f);
    float ct = std::cos(p.rodTheta), st = std::sin(p.rodTheta);
    p.rodBodyX = jx - (ct * 0 - st * bigEndLocal);
    p.rodBodyY = jy - (st * 0 + ct * bigEndLocal);
    // piston: wrist at local (0, wristPin); body.p so localToWorld(0,wristPin)=wrist
    float wct = std::cos(p.pistonTheta), wst = std::sin(p.pistonTheta);
    p.pistonBodyX = wx - (-wst * in.wristPin);
    p.pistonBodyY = wy - (wct * in.wristPin);
    return p;
}

void emitJson(const Emitter &em, Color bg) {
    std::ostringstream o;
    o << "{\"bg\":\"" << css(bg) << "\",\"commands\":[";
    for (size_t i = 0; i < em.cmds.size(); ++i) {
        const auto &c = em.cmds[i];
        if (i) o << ',';
        o << "{\"op\":\"" << c.op << "\",\"color\":\"" << c.color << "\"";
        if (c.op == "mesh") {
            o << ",\"mesh\":\"" << c.mesh << "\",\"m\":[" << c.m.a << ',' << c.m.b << ',' << c.m.c
              << ',' << c.m.d << ',' << c.m.e << ',' << c.m.f << ']';
        } else {
            o << ",\"xy\":[";
            for (size_t k = 0; k < c.xy.size(); ++k) {
                if (k) o << ',';
                o << c.xy[k];
            }
            o << ']';
        }
        o << '}';
    }
    o << "]}";
    std::cout << o.str();
}

} // namespace

int main() {
    const Color BG = hex("#0E1012");
    const Color FG = hex("#FFFFFF");
    const Color PINK = hex("#F394BE");
    const Color ORANGE = hex("#F4802A");
    const Color YELLOW = hex("#FDBD2E");
    const Color BLUE = hex("#77CEE0");

    Input in = parseInput(readAllStdin());
    Emitter em;

    // --- banks: cylinder_bank_object.cpp generateGeometry + render ---
    for (const Bank &bank : in.banks) {
        float lineWidth = in.bore * 0.1f;
        float margin = lineWidth * 0.25f;
        float displayDepth = 1.0f - bank.displayDepth;
        float dx = -bank.dy * (margin + in.bore / 2 + lineWidth / 2);
        float dy = bank.dx * (margin + in.bore / 2 + lineWidth / 2);
        float top_x = bank.x + bank.dx * (in.deck + in.chamberH);
        float top_y = bank.y + bank.dy * (in.deck + in.chamberH);
        float bottom_x = bank.x + bank.dx * (displayDepth * in.deck);
        float bottom_y = bank.y + bank.dy * (displayDepth * in.deck);

        em.setXform(Mat3{});
        em.setColor(PINK);
        em.line2d(top_x + dx, top_y + dy, bottom_x + dx, bottom_y + dy, lineWidth);
        em.circle2d(bottom_x + dx, bottom_y + dy, lineWidth / 2);
        em.line2d(top_x - dx, top_y - dy, bottom_x - dx, bottom_y - dy, lineWidth);
        em.circle2d(bottom_x - dx, bottom_y - dy, lineWidth / 2);
    }

    // --- crank: crankshaft_object.cpp render ---
    Color grey0 = mix(BG, FG, 0.7f);
    Color grey1 = mix(BG, FG, 0.6f);
    Color grey2 = mix(BG, FG, 0.2f);
    // Far journals first (esim priority 0x32 - layer) so near/bright sits on top.
    for (int i = (int)in.journals.size() - 1; i >= 0; --i) {
        Color col = tintByLayer(grey0, BG, i);
        // setTransform(body, throw, 0, 0, journalAngle)
        float bodyTheta = in.crankAngle; // crank body angle
        Mat3 m = setTransform(0, 0, bodyTheta, in.throwMm, 0, 0, in.journals[i]);
        em.setXform(m);
        em.setColor(col);
        em.mesh("Crankshaft");
    }
    {
        Mat3 m = setTransform(0, 0, in.crankAngle, in.throwMm, 0, 0, 0);
        em.setXform(m);
        em.setColor(grey1);
        em.mesh("CrankSnout");
        em.setColor(grey2);
        em.mesh("CrankSnoutThreads");
    }

    // --- rods + pistons ---
    Color rodGrey0 = mix(BG, FG, 0.9333f);
    Color rodGrey1 = mix(BG, FG, 0.8667f);
    float bigEndLocal = -(in.rod / 2.f); // centerOfMass=0 → connecting_rod.cpp
    float littleEndLocal = in.rod / 2.f;
    int nJ = std::max(1, (int)in.journals.size());

    struct CylRef {
        int bi, c, journalIndex, layer;
    };
    std::vector<CylRef> cyls;
    int cylOrd = 0;
    for (size_t bi = 0; bi < in.banks.size(); ++bi) {
        const Bank &bank = in.banks[bi];
        for (int c = 0; c < bank.cylinders; ++c, ++cylOrd) {
            int journalIndex =
                (cylOrd < (int)in.cylinderJournals.size())
                    ? in.cylinderJournals[cylOrd] % nJ
                    : c % nJ;
            cyls.push_back({(int)bi, c, journalIndex, journalIndex});
        }
    }
    // Back→front so layer 0 (bright) is painted last / on top.
    std::sort(cyls.begin(), cyls.end(),
              [](const CylRef &a, const CylRef &b) { return a.layer > b.layer; });

    for (const CylRef &cr : cyls) {
        const Bank &bank = in.banks[cr.bi];
        float ja = in.journals[cr.journalIndex];
        Pose pose = poseCylinder(in, bank, ja);

        // connecting_rod_object::render
        // setTransform(body, throw, 0, bigEndLocal)
        Color rcol = (bank.index % 2 == 0) ? rodGrey0 : rodGrey1;
        rcol = tintByLayer(rcol, BG, cr.layer);
        Mat3 rodM =
            setTransform(pose.rodBodyX, pose.rodBodyY, pose.rodTheta, in.throwMm, 0, bigEndLocal);
        em.setXform(rodM);
        em.setColor(rcol);
        em.mesh("ConnectingRod");

        // generateGeometry rod body line — setTransform(body) identity scale
        em.setXform(setTransform(pose.rodBodyX, pose.rodBodyY, pose.rodTheta, 1.f));
        em.setColor(rcol);
        em.line2d(0, bigEndLocal + in.throwMm * 0.6f, 0, littleEndLocal, in.throwMm * 0.5f);

        // piston_object.cpp: setTransform(body, bore/2, 0, -(compH+wristPin))
        Color pcol = tintByLayer(FG, BG, cr.layer);
        float ps = in.bore / 2.f;
        Mat3 pisM = setTransform(pose.pistonBodyX, pose.pistonBodyY, pose.pistonTheta, ps, 0,
                                -(in.compH + in.wristPin));
        em.setXform(pisM);
        em.setColor(pcol);
        em.mesh("Piston");
        // wrist pin hole at body transform (scale 1)
        em.setXform(setTransform(pose.pistonBodyX, pose.pistonBodyY, pose.pistonTheta, 1.f));
        em.setColor(tintByLayer(BG, BG, cr.layer));
        em.circle2d(0, in.wristPin, (in.bore / 10.f) * 0.75f);
    }

    // --- heads: cylinder_head_object.cpp render (per bank, foremost) ---
    for (size_t bi = 0; bi < in.banks.size(); ++bi) {
        const Bank &bank = in.banks[bi];
        float s = in.bore / 2.f;
        float hx = bank.x + bank.dx * (in.deck + in.chamberH);
        float hy = bank.y + bank.dy * (in.deck + in.chamberH);
        // T_headObject = T(hx,hy) * R(bank.angle); T_head = T_headObject * S(s)
        Mat3 T_headObject = Mat3::T(hx, hy) * Mat3::R(bank.angle);
        Mat3 T_head = T_headObject * Mat3::S(s);

        em.setXform(T_head);
        em.setColor(PINK);
        em.mesh("CylinderHead");

        // valve shadow lines (local head units) — copied constants from cylinder_head_object.cpp
        em.setColor(BG);
        auto shadow = [&](float x0, float y0, float x1, float y1, float lw) {
            em.line2d(x0, y0, x1, y1, lw);
        };
        shadow(-0.689352f, 0.085f, -0.88632f, -0.077975f, 0.2f);
        shadow(-(-( -0.689352f) + 0.5f) - 0.5f, 0.085f, -(-( -0.88632f) + 0.5f) - 0.5f, -0.077975f, 0.2f);
        // simplify: both sides as in source
        {
            float x0 = -0.689352f, x1 = -0.88632f;
            shadow(-(x0 + 0.5f) - 0.5f, 0.085f, -(x1 + 0.5f) - 0.5f, -0.077975f, 0.2f);
            x0 = 0.689352f;
            x1 = 0.88632f;
            shadow(x0, 0.085f, x1, -0.077975f, 0.2f);
            shadow(-(x0 - 0.5f) + 0.5f, 0.085f, -(x1 - 0.5f) + 0.5f, -0.077975f, 0.2f);
            shadow(-0.5f, 0.2f, -0.5f, 1.5f, 0.0917f);
            shadow(0.5f, 0.2f, 0.5f, 1.5f, 0.0917f);
        }

        float intakeValvePosition = in.flip[bi] ? 0.5f : -0.5f;
        // visual lifts
        float intakeLift = in.camLift * 0.35f * (0.5f + 0.5f * std::sin(in.crankAngle * 2 + bank.angle));
        float exhaustLift = in.camLift * 0.35f * (0.5f + 0.5f * std::sin(in.crankAngle * 2 + bank.angle + PI));

        auto drawValve = [&](float localX, Color col, float lift) {
            Mat3 T_v = T_head * Mat3::T(localX, -lift / s);
            em.setXform(T_v);
            em.setColor(col);
            em.mesh("Valve");
            constexpr float rollerRadius = 0.3f * 0.0254f * 1000.f / 1000.f; // 300 thou in mm… use units
            // units::distance(300, thou) in engine-sim = 0.00762 m = 7.62 mm; here we work in mm, s in mm
            float rr = 7.62f; // mm
            float rrLocal = rr / s;
            em.circle2d(0, 1.99f, rrLocal); // roller in head-local (already in T_v which includes S(s)?)
            // T_v includes S(s), so coords are in mesh units — rollerRadius/s as in source
            em.setColor(BG);
            em.circle2d(0, 1.99f, rrLocal * 0.25f);
        };
        // Fix roller: source uses rollerRadius/s in local after T_head scale
        float rollerRadius_mm = 7.62f;
        float rr_local = rollerRadius_mm / s;

        auto drawValve2 = [&](float localX, Color col, float lift) {
            Mat3 T_v = T_head * Mat3::T(localX, -lift / s);
            em.setXform(T_v);
            em.setColor(col);
            em.mesh("Valve");
            em.setColor(BG);
            em.circle2d(0.f, 1.99f, (rollerRadius_mm + 0.5f) / s); // shadow approx
            em.setColor(col);
            em.circle2d(0.f, 1.99f, rr_local);
            em.setColor(BG);
            em.circle2d(0.f, 1.99f, rr_local * 0.25f);
        };
        drawValve2(intakeValvePosition, BLUE, intakeLift);
        drawValve2(-intakeValvePosition, YELLOW, exhaustLift);

        // cams in world mm (T_headObject space, not scaled)
        float camY = rollerRadius_mm + 0.5f + 1.99f * s + in.camBase;
        Mat3 T_inCam =
            T_headObject * Mat3::T(intakeValvePosition * s, camY) * Mat3::R(in.crankAngle * 2 + bank.angle);
        em.setXform(T_inCam);
        em.setColor(BLUE);
        em.cam(0, 0, in.camBase, rollerRadius_mm, in.camLift);
        em.setColor(BG);
        em.circle2d(0, 0, rollerRadius_mm * 0.25f);

        Mat3 T_exCam = T_headObject * Mat3::T(-intakeValvePosition * s, camY) *
                       Mat3::R(in.crankAngle * 2 + bank.angle + 0.3f);
        em.setXform(T_exCam);
        em.setColor(ORANGE);
        em.cam(0, 0, in.camBase, rollerRadius_mm, in.camLift);
        em.setColor(BG);
        em.circle2d(0, 0, rollerRadius_mm * 0.25f);
    }

    emitJson(em, BG);
    return 0;
}
