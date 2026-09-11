// =====================================================================
//  UniHolder — tests/test_shapes.scad                             ST-1
//  Test sheet for lib/uh_shapes.scad. Every primitive is used inside a
//  small standing coupon exactly as the holder will use it, so the sheet
//  doubles as a printable calibration coupon: print as generated, no supports.
//
//  Verify from the project folder:
//    openscad -o sheet60.stl -D max_overhang=60 tests/test_shapes.scad
//    python3 tools/check_overhang.py sheet60.stl --max-overhang 60
// =====================================================================

/* [Test sheet] */
// Overhang limit in degrees from vertical (60 = design default, 45 = conservative)
max_overhang = 60; // [40:5:60]
// Coupon to show
show = "all"; // [all, holes, screws, hex, keyhole, tunnels, supports, arch, cup]
// Render quality
quality = "normal"; // [draft, normal, fine]

/* [Hidden] */
include <../lib/uh_core.scad>
include <../lib/uh_shapes.scad>

$fa = uh_quality(quality)[0];
$fs = uh_quality(quality)[1];

MO      = uh_clamp_warn(max_overhang, UH_OVERHANG_MIN, UH_OVERHANG_MAX, "max_overhang");
PLATE_R = 1.0;   // vertical edge fillet of every coupon (E1)
C_BOT   = 0.4;   // first-layer chamfer (P9)
C_TOP   = 0.6;   // top chamfer (E2)

uh_core_selftest();
uh_info(str("max_overhang = ", MO, "°, beta = ", uh_beta(MO), "°, rise per mm = ", uh_rise(1, MO),
            ", teardrop apex / r = ", uh_teardrop_apex(1, MO), ", hex pitch (8, 2) = ", uh_hex_pitch(8, 2, MO)));

sheet();

// ---------------------------------------------------------------------
module sheet() {
    if (show == "all") {
        translate([ 38,  0, 0]) coupon_holes();
        translate([124,  0, 0]) coupon_screws();
        translate([202,  0, 0]) coupon_hex();
        translate([ 20, 34, 0]) coupon_keyhole();
        translate([ 70, 34, 0]) coupon_tunnels();
        translate([128, 34, 0]) coupon_supports();
        translate([207, 34, 0]) coupon_arch();
        translate([ 30, 82, 0]) coupon_cup();
    }
    else if (show == "holes")    coupon_holes();
    else if (show == "screws")   coupon_screws();
    else if (show == "hex")      coupon_hex();
    else if (show == "keyhole")  coupon_keyhole();
    else if (show == "tunnels")  coupon_tunnels();
    else if (show == "supports") coupon_supports();
    else if (show == "arch")     coupon_arch();
    else if (show == "cup")      coupon_cup();
}

// Standing block with filleted vertical edges and chamfered horizontal edges
module coupon_body(size) {
    uh_chamfered_extrude(size[2], C_BOT, C_TOP, MO) uh_rrect4([size[0], size[1]], PLATE_R);
}

// 1 — teardrop holes Ø3, 4.5, 6, 8, 10 (P4)
module coupon_holes() {
    t  = 6;
    ds = [3, 4.5, 6, 8, 10];
    xs = [-30, -19, -6.5, 8.5, 26];
    difference() {
        coupon_body([76, t, 20]);
        for (i = [0:len(ds) - 1])
            translate([xs[i], 0, 9]) uh_teardrop_prism(ds[i], t + 2, MO, center = true);
    }
}

// 2 — screw holes: plain, countersink, counterbore, slotted countersink.
//     Screws enter from the +Y face; heads sit on the −Y face.
module coupon_screws() {
    t = 6;
    difference() {
        coupon_body([76, t, 26]);
        translate([-27, t / 2, 10]) uh_screw_hole(4.5, t, "plain", max_overhang = MO);
        translate([ -9, t / 2, 10]) uh_screw_hole(4.5, t, "countersink", 9, max_overhang = MO);
        translate([  9, t / 2, 10]) uh_screw_hole(4.5, t, "counterbore", 8.5, cb_depth = 3, max_overhang = MO);
        translate([ 27, t / 2, 10]) uh_screw_hole(4.5, t, "countersink", 9, slot = 6, max_overhang = MO);
    }
}

// 3 — hexagon perforation in a 2.4 mm wall, whole cells only (P7)
module coupon_hex() {
    size  = [60, 2.4, 44];
    w     = 8;
    strut = 2;
    cell  = uh_hex_dims(w, MO);
    pitch = uh_hex_pitch(w, strut, MO);
    zone  = [48, 32];          // usable width and height
    z0    = 6;                 // bottom of the zone
    rows  = floor((zone[1] - cell[3]) / pitch[1]) + 1;
    cols  = floor((zone[0] - w) / pitch[0]) + 1;
    v0    = z0 + (zone[1] - ((rows - 1) * pitch[1] + cell[3])) / 2 + cell[3] / 2;
    difference() {
        coupon_body(size);
        for (r = [0:rows - 1]) {
            n = r % 2 == 0 ? cols : cols - 1;          // shifted rows drop one cell
            for (c = [0:n - 1])
                translate([(c - (n - 1) / 2) * pitch[0], 0, v0 + r * pitch[1]])
                    uh_face_extrude(size[1] + 2, center = true) uh_hex_cell2d(w, MO);
        }
    }
}

// 4 — keyhole, 4 mm square pin hole, blind magnet pocket (P4, P5)
module coupon_keyhole() {
    t = 9;
    difference() {
        coupon_body([40, t, 34]);
        translate([-8, t / 2, 11]) uh_keyhole(4.5, 9.5, 9, skin = 1.6, head_h = 3.4, max_overhang = MO);
        translate([11, 0, 10])     uh_peaked_prism([4.2, 4.2], t + 2, MO, center = true);
        translate([11, t / 2 + UH_EPS, 24]) uh_teardrop_prism(10.2, 3.2 + UH_EPS, MO);
    }
}

// 5 — zip-tie tunnels: two horizontal (peaked roof), one vertical, flared ends
module coupon_tunnels() {
    s = [36, 16, 34];
    difference() {
        coupon_body(s);
        for (z = [10, 24]) translate([0, -2, z]) uh_tunnel(5, 2, s[0], 1, "x", MO);
        translate([0, 5, s[2] / 2]) uh_tunnel(5, 2, s[2], 1, "z", MO);
    }
}

// 6 — supported protrusions (P6); raised wing and bed wing (E3, E4)
module coupon_supports() {
    size = [50, 4, 44];
    k    = uh_rise(1, MO);
    union() {
        coupon_body(size);
        // high block: the slope ends on the wall
        translate([-12, size[1] / 2 - UH_EPS, 0])
            uh_supported_prism(12 + UH_EPS, MO) translate([-8, 26]) uh_rrect4([16, 10], 2, center = false);
        // low block: the slope reaches the bed and is clipped
        translate([12, size[1] / 2 - UH_EPS, 0])
            uh_supported_prism(14 + UH_EPS, MO) translate([-8, 4]) uh_rrect4([16, 8], 2, center = false);
        // block on the other face (dir = −1)
        translate([0, -size[1] / 2 + UH_EPS, 0])
            uh_supported_prism(8 + UH_EPS, MO, dir = -1) translate([-5, 30]) uh_rrect4([10, 6], 1.5, center = false);
        // raised wing flush with the +Y face: sloped underside, rounded tip, chamfered −Y face
        translate([0, size[1] / 2, 0])
            uh_chamfered_plate(3, c_far = 0.6, dir = -1, max_overhang = MO)
                translate([23, 6]) uh_cantilever2d(20, 36, MO, r = 3);
        // wing resting on the bed on the other side: flat underside, square bottom tip
        translate([0, size[1] / 2, 0])
            uh_chamfered_plate(3, c_far = 0.6, dir = -1, max_overhang = MO)
                mirror([1, 0]) translate([23, 0]) uh_cantilever2d(14, 20, MO, r = 3, on_bed = true);
    }
}

// 7 — pointed-arch window and vertical slot
module coupon_arch() {
    size = [50, 3, 44];
    difference() {
        coupon_body(size);
        translate([-6, 0, 8])  uh_face_extrude(size[1] + 2, center = true) uh_arch2d(22, 16, MO, r_bottom = 3);
        translate([17, 0, 10]) uh_face_extrude(size[1] + 2, center = true) uh_slot2d(4, 14, MO);
    }
}

// 8 — miniature holder shell: four corner radii, single-hull outer solid,
//     pairwise-hull cavity with floor cove and rim flare
module coupon_cup() {
    W = 44;  D = 32;  H = 36;
    wall = 2.4;  back = 3.2;  floor_t = 2;  cove = 2;  c_top = 1.0;  c_bot = 0.6;
    ro    = [7, 7, 0, 3];                     // front-left, front-right, back-right, back-left
    ri    = [for (i = [0:3]) max(ro[i] - (i < 2 ? wall : back), 2)];
    inner = [W - 2 * wall, D - wall - back];
    difference() {
        uh_chamfered_extrude(H, c_bot, c_top, MO) uh_rrect4([W, D], ro);
        uh_slice_stack([[floor_t, -cove], [floor_t + cove, 0], [H - c_top, 0], [H + UH_EPS, c_top]],
                       pairwise = true)
            translate([0, (wall - back) / 2]) uh_rrect4(inner, ri);
    }
}
