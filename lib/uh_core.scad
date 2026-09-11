// =====================================================================
//  UniHolder — lib/uh_core.scad                                   ST-1
//  Constants, overhang math, hexagon math and console helpers.
//
//  Dependency-free; OpenSCAD 2021.01 language subset.
//  Libraries never include each other. Include them in this order:
//      include <lib/uh_core.scad>
//      include <lib/uh_shapes.scad>
//
//  Conventions (design plan §3–§4)
//    * Overhang angles are measured FROM VERTICAL: 0° = wall, 90° = ceiling.
//    * beta = 90° − max_overhang is the minimum rise of any downward-facing
//      surface above horizontal (the "roof angle").
//    * +Z is up in use and on the print bed. Units: mm and degrees.
//
//  Public API
//    Generic     uh_clamp  uh_auto  uh_approx  uh_quality  uh_fragments  uh_poly_r
//    Overhang    uh_beta  uh_rise  uh_run  uh_teardrop_apex  uh_roof_h
//                uh_overhang_of_nz  uh_flare_len  uh_chamfer_h  uh_chamfer_depth
//                uh_countersink_depth
//    Hexagon     uh_hex_flank  uh_hex_peak  uh_hex_dims  uh_hex_pitch
//    Console     uh_warn  uh_info  uh_warn_f  uh_clamp_warn
//    Transforms  uh_mirror_copy
//    Tests       uh_core_selftest
// =====================================================================

UH_CORE_VERSION = "0.1.0";

UH_EPS  = 0.01;    // overlap on coincident union / difference faces
UH_TINY = 0.001;   // thickness of construction slices
UH_BIG  = 4000;    // size of clipping volumes

UH_OVERHANG_MIN = 40;   // supported range of max_overhang
UH_OVERHANG_MAX = 60;

// ---------------------------------------------------------------------
//  Generic helpers
// ---------------------------------------------------------------------

function uh_clamp(x, lo, hi) = min(max(x, lo), hi);

// "0 means auto" convention for optional dimensions
function uh_auto(value, auto_value) = value == 0 ? auto_value : value;

function uh_approx(a, b, tol = 1e-6) = abs(a - b) <= tol;

// Quality preset -> [$fa, $fs]
function uh_quality(q) =
      q == "draft" ? [12, 1.0]
    : q == "fine"  ? [3, 0.2]
    :                [6, 0.4];

// Fragments OpenSCAD uses for a circle of radius r (same rule as the renderer)
function uh_fragments(r) =
      r < 1e-5 ? 3
    : $fn > 0  ? max($fn, 3)
    :            ceil(max(min(360 / $fa, r * 2 * PI / $fs), 5));

// Vertex radius of an n-gon whose flats sit at radius r.
// Used for clearance holes, so a printed hole is never undersized.
function uh_poly_r(r, n) = r / cos(180 / n);

// ---------------------------------------------------------------------
//  Overhang math (rules P2, P4, P5, P6)
// ---------------------------------------------------------------------

// Roof angle: minimum rise of a downward-facing surface above horizontal
function uh_beta(max_overhang) = 90 - max_overhang;

// Height a support slope gains over a horizontal run
function uh_rise(run, max_overhang) = run * tan(uh_beta(max_overhang));

// Horizontal run a support slope needs to gain a given height
function uh_run(rise, max_overhang) = rise / tan(uh_beta(max_overhang));

// Apex height above the centre of a teardrop with radius r
function uh_teardrop_apex(r, max_overhang) = r / cos(uh_beta(max_overhang));

// Height of a peaked roof over a flat span of width w
function uh_roof_h(w, max_overhang) = (w / 2) * tan(uh_beta(max_overhang));

// Overhang angle (from vertical) of a surface whose unit normal has z-component nz
function uh_overhang_of_nz(nz) = nz >= 0 ? 0 : asin(min(1, -nz));

// Axial length of an end flare that widens a channel by `flare` per side.
//   axis "x" / "y"  horizontal channel: the roof flare rises at >= 45° and >= beta
//   axis "z"        vertical channel:   the bottom flare stays <= 45° and <= max_overhang
function uh_flare_len(flare, max_overhang, axis = "x") =
      flare <= 0  ? 0
    : axis == "z" ? flare / min(1, tan(max_overhang))
    :               flare / max(1, tan(uh_beta(max_overhang)));

// Downward-facing chamfers (P9): a horizontal inset needs this much height,
// i.e. 45° while max_overhang >= 45 and steeper below that.
function uh_chamfer_h(inset, max_overhang) = inset * max(1, tan(uh_beta(max_overhang)));

// Face chamfer on a vertical plate: depth along the plate normal for a given inset,
// so the chamfer under a horizontal bottom edge also stays within max_overhang.
function uh_chamfer_depth(inset, max_overhang) = inset / max(1, tan(uh_beta(max_overhang)));

// Depth of a countersink from bore d to head_d with the given included angle
function uh_countersink_depth(d, head_d, angle = 90) =
    max(0, (head_d - d) / 2) / tan(angle / 2);

// ---------------------------------------------------------------------
//  Hexagon math (rule P7) — pointy-top cell, across flats w (horizontal)
//  flank s = w/√3, peak h = (w/2)·tan(beta); beta = 30° gives the regular hexagon.
//  `grow` moves every edge outward (grid cell = hole grown by strut/2).
// ---------------------------------------------------------------------

function uh_hex_flank(w) = w / sqrt(3);

function uh_hex_peak(w, max_overhang) = (w / 2) * tan(uh_beta(max_overhang));

// [width, flank, peak, total height] of the (grown) cell
function uh_hex_dims(w, max_overhang, grow = 0) =
    let(b = uh_beta(max_overhang),
        s = uh_hex_flank(w) + 2 * grow * (1 - sin(b)) / cos(b),
        h = uh_hex_peak(w, max_overhang) + grow * tan(b))
    [w + 2 * grow, s, h, s + 2 * h];

// Honeycomb pitch [horizontal, vertical] for hole width w and strut width
function uh_hex_pitch(w, strut, max_overhang) =
    let(c = uh_hex_dims(w, max_overhang, strut / 2))
    [c[0], c[1] + c[2]];

// ---------------------------------------------------------------------
//  Console helpers
// ---------------------------------------------------------------------

module uh_warn(ok, msg) { if (!ok) echo(str("UH WARNING: ", msg)); }

module uh_info(msg) { echo(str("UH INFO: ", msg)); }

// Expression form: returns value, warns when ok is false
function uh_warn_f(ok, msg, value) =
    ok ? value : echo(str("UH WARNING: ", msg)) value;

// Clamp with a console warning naming the parameter
function uh_clamp_warn(x, lo, hi, name) =
    let(c = uh_clamp(x, lo, hi))
    c == x ? x : echo(str("UH WARNING: ", name, " = ", x, " clamped to ", c)) c;

// ---------------------------------------------------------------------
//  Transforms
// ---------------------------------------------------------------------

module uh_mirror_copy(v = [1, 0, 0]) { children(); mirror(v) children(); }

// ---------------------------------------------------------------------
//  Self-test (no geometry; asserts stop the render on failure)
// ---------------------------------------------------------------------

module uh_core_selftest() {
    t = 1e-6;
    p = uh_hex_pitch(8, 2, 60);
    q = uh_hex_pitch(8, 2, 45);
    assert(uh_approx(uh_beta(60), 30, t),                        "uh_beta");
    assert(uh_approx(uh_rise(10, 45), 10, t),                    "uh_rise at 45");
    assert(uh_approx(uh_rise(10, 60), 10 * tan(30), t),          "uh_rise at 60");
    assert(uh_approx(uh_run(uh_rise(7, 55), 55), 7, t),          "uh_run inverse");
    assert(uh_approx(uh_teardrop_apex(1, 45), sqrt(2), t),       "uh_teardrop_apex");
    assert(uh_approx(uh_hex_peak(8, 60), 8 / (2 * sqrt(3)), t),  "regular hexagon peak");
    assert(uh_approx(p[0], 10, t),                               "hex pitch u");
    assert(uh_approx(p[1], 10 * sqrt(3) / 2, t),                 "hex pitch v, regular");
    assert(q[1] > p[1],                                          "stretched hexagon is taller");
    assert(uh_approx(uh_countersink_depth(4.5, 9), 2.25, t),     "countersink depth");
    assert(uh_approx(uh_flare_len(1, 60, "x"), 1, t),            "flare length");
    assert(uh_approx(uh_chamfer_h(1, 60), 1, t),                 "chamfer 45° at 60");
    assert(uh_chamfer_h(1, 40) > 1,                              "chamfer steeper at 40");
    uh_info("uh_core self-test passed");
}
