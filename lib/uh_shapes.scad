// =====================================================================
//  UniHolder — lib/uh_shapes.scad                                 ST-1
//  Printable primitives. Every downward-facing surface they create
//  respects max_overhang (design plan rules P2–P7, E1–E4).
//  Requires lib/uh_core.scad to be included first.
//
//  Frames
//    2D profiles   local +Y becomes print +Z when a 3D module places them.
//    Cutters       entry face at y = 0; the feature runs into material toward −Y;
//                  +Z up. Screw heads sit on the far (−Y) face.
//    Additions     grow out of a face at y = 0 toward +Y (dir = 1) or −Y (dir = −1).
//    Stacks        built along +Z from 2D outlines in the XY plane.
//
//  Public API
//    2D  uh_circle         clearance circle, flats at nominal size
//        uh_rrect4         rounded rectangle, four corner radii
//        uh_round_convex   round convex corners of 2D children
//        uh_round_concave  fillet concave corners of 2D children
//        uh_teardrop2d     circle with roof at beta (P4)
//        uh_slot2d         vertical slot with teardrop top
//        uh_peaked_rect2d  rectangle with peaked roof (P5)
//        uh_arch2d         pointed-arch window profile
//        uh_cantilever2d   wing / tab outline with support slope, safe tip rounds
//        uh_hex_cell2d     pointy-top hexagon cell (P7)
//    3D  uh_face_extrude       2D (x, z) profile extruded along Y
//        uh_slice_stack        hull of offset slices (chamfers)
//        uh_chamfered_extrude  prism with bottom/top chamfers (P9, E2)
//        uh_chamfered_plate    plate along Y with chamfered faces
//        uh_teardrop_prism     horizontal teardrop hole (P4)
//        uh_peaked_prism       horizontal peaked channel (P5)
//        uh_screw_hole         plain / countersink / counterbore, optional slot
//        uh_keyhole            keyhole with head channel
//        uh_tunnel             flared tie / strap tunnel, horizontal or vertical
//        uh_supported_prism    protrusion with support slope below (P6)
// =====================================================================

_uh_shapes_requires_core =
    assert(!is_undef(UH_CORE_VERSION), "uh_shapes.scad: include lib/uh_core.scad first") 1;

// =====================================================================
//  2D primitives
// =====================================================================

// Clearance circle. With compensate = true the polygon's flats sit on d/2,
// so a screw of diameter d always fits.
module uh_circle(d, compensate = true) {
    n = uh_fragments(d / 2);
    circle(r = compensate ? uh_poly_r(d / 2, n) : d / 2, $fn = n);
}

// Rounded rectangle with individual corner radii.
// r = [r0, r1, r2, r3] for corners (−x,−y), (+x,−y), (+x,+y), (−x,+y);
// for a holder footprint that is front-left, front-right, back-right, back-left.
// A single number applies to all four corners.
// center = false puts the (−x,−y) corner on the origin.
module uh_rrect4(size, r = 0, center = true) {
    sx = size[0];
    sy = size[1];
    rr = is_list(r) ? r : [r, r, r, r];
    sg = [[-1, -1], [1, -1], [1, 1], [-1, 1]];
    translate(center ? [0, 0] : [sx / 2, sy / 2])
        hull()
            for (i = [0:3]) {
                ri = uh_clamp(rr[i], 0, min(sx, sy) / 2);
                if (ri > UH_TINY)
                    translate([sg[i][0] * (sx / 2 - ri), sg[i][1] * (sy / 2 - ri)])
                        circle(r = ri);
                else
                    translate([sg[i][0] * (sx / 2 - UH_TINY), sg[i][1] * (sy / 2 - UH_TINY)])
                        square(2 * UH_TINY, center = true);
            }
}

// Round the convex corners of 2D children with radius r
module uh_round_convex(r) { offset(r = r) offset(delta = -r) children(); }

// Fillet the concave corners of 2D children with radius r
module uh_round_concave(r) { offset(r = -r) offset(delta = r) children(); }

// Teardrop (P4): circle Ø d plus two roof lines rising at beta to an apex on +Y.
module uh_teardrop2d(d, max_overhang = 60, compensate = true) {
    n  = uh_fragments(d / 2);
    rp = compensate ? uh_poly_r(d / 2, n) : d / 2;
    hull() {
        circle(r = rp, $fn = n);
        polygon([[-UH_TINY, 0], [UH_TINY, 0], [0, uh_teardrop_apex(rp, max_overhang)]]);
    }
}

// Vertical slot of width d: round bottom centred on the origin, teardrop top at (0, len).
module uh_slot2d(d, len, max_overhang = 60, compensate = true) {
    hull() {
        uh_circle(d, compensate);
        translate([0, max(0, len)]) uh_teardrop2d(d, max_overhang, compensate);
    }
}

// Rectangle size = [w, h] with a peaked roof (P5) above it.
// center = true centres the rectangle part on the origin; otherwise its bottom sits on y = 0.
// r_bottom rounds the two bottom corners (upward-facing valleys in the part).
module uh_peaked_rect2d(size, max_overhang = 60, r_bottom = 0, center = true) {
    w  = size[0];
    h  = size[1];
    rb = uh_clamp(r_bottom, 0, min(w / 2, h));
    roof = uh_roof_h(w, max_overhang);
    translate([0, center ? -h / 2 : 0])
        hull() {
            if (rb > UH_TINY) {
                translate([-w / 2 + rb, rb]) circle(r = rb);
                translate([ w / 2 - rb, rb]) circle(r = rb);
            }
            polygon([[-w / 2, rb], [w / 2, rb], [w / 2, h], [0, h + roof], [-w / 2, h]]);
        }
}

// Pointed-arch window: sill on y = 0, vertical sides of height h, roof at beta.
module uh_arch2d(w, h, max_overhang = 60, r_bottom = 0) {
    uh_peaked_rect2d([w, h], max_overhang, r_bottom, center = false);
}

// Cantilever plate profile drawn as (x, z): attached along x = 0 for 0 <= z <= h and
// reaching out to x = len — the outline of a wing or tab (P6, E3, E4).
//   on_bed = false  underside rises from (0, 0) at beta; both tip corners rounded by r
//   on_bed = true   flat underside on z = 0; only the top tip corner is rounded
// The root corners are never rounded: a round below the root would turn through
// horizontal and create a small ceiling.
module uh_cantilever2d(len, h, max_overhang = 60, r = 0, on_bed = false) {
    k  = uh_rise(1, max_overhang);
    zt = on_bed ? 0 : len * k;                         // underside height at the tip
    rr = uh_clamp(r, 0, min(len, h - zt) / 2);
    assert(h - zt > 2 * rr + UH_TINY, "uh_cantilever2d: plate is too short for its support slope");
    cz = k * (len - rr) + rr * sqrt(1 + k * k);        // lower tip circle: tangent to slope and tip
    hull() {
        polygon([[0, 0],
                 on_bed ? [len, 0] : (rr > 0 ? [len - rr, cz] : [len, zt]),
                 rr > 0 ? [len - rr, h - rr] : [len, h],
                 [0, h]]);
        if (rr > 0) {
            translate([len - rr, h - rr]) circle(r = rr);
            if (!on_bed) translate([len - rr, cz]) circle(r = rr);
        }
    }
}

// Pointy-top hexagon (P7), across flats w, upper edges at beta.
// grow moves every edge outward, keeping strut widths uniform.
module uh_hex_cell2d(w, max_overhang = 60, grow = 0) {
    c = uh_hex_dims(w, max_overhang, grow);
    x = c[0] / 2;
    s = c[1] / 2;
    p = s + c[2];
    polygon([[0, p], [-x, s], [-x, -s], [0, -p], [x, -s], [x, s]]);
}

// =====================================================================
//  3D helpers
// =====================================================================

// Extrude a 2D profile drawn as (x, z) along Y:
// dir = −1 from y = 0 to y = −depth, dir = 1 from y = 0 to y = +depth,
// center = true from −depth/2 to +depth/2.
module uh_face_extrude(depth, dir = -1, center = false) {
    if (center)
        translate([0, depth / 2, 0]) rotate([90, 0, 0]) linear_extrude(depth, convexity = 10) children();
    else if (dir < 0)
        rotate([90, 0, 0]) linear_extrude(depth, convexity = 10) children();
    else
        mirror([0, 1, 0]) rotate([90, 0, 0]) linear_extrude(depth, convexity = 10) children();
}

// Hull of thin slices of offset(delta = d) children at heights z.
// levels = [[z0, d0], [z1, d1], ...] in ascending z; children = one convex 2D outline.
// pairwise = true hulls consecutive slices only — required whenever a middle slice
// is narrower than an outer one (e.g. a cavity that flares at the rim), because a
// single hull would taper the walls.
module uh_slice_stack(levels, pairwise = false) {
    n = len(levels);
    if (pairwise)
        render(convexity = 4)   // one solid: no internal faces that show as skins in the F5 preview
            for (i = [0:n - 2])
                hull() {
                    _uh_slice(levels[i], false) children();
                    _uh_slice(levels[i + 1], i + 1 == n - 1) children();
                }
    else
        hull()
            for (i = [0:n - 1]) _uh_slice(levels[i], i == n - 1) children();
}

module _uh_slice(level, is_top) {
    translate([0, 0, level[0] - (is_top ? UH_TINY : 0)])
        linear_extrude(UH_TINY) offset(delta = level[1]) children();
}

// Prism of height h from a convex 2D outline with chamfers:
// c_bot insets the bottom edge (P9) — 45°, or steeper when max_overhang < 45;
// c_top insets the top edge (E2) at 45°.
module uh_chamfered_extrude(h, c_bot = 0, c_top = 0, max_overhang = 60) {
    cb  = max(0, c_bot);
    ct  = uh_clamp(c_top, 0, h / 2);
    cbh = min(uh_chamfer_h(cb, max_overhang), h / 2);
    uh_slice_stack(concat(cb > 0 ? [[0, -cb], [cbh, 0]] : [[0, 0]],
                          ct > 0 ? [[h - ct, 0], [h, -ct]] : [[h, 0]]))
        children();
}

// Plate: convex 2D outline drawn as (x, z), extruded along Y by depth from y = 0
// toward dir, with chamfers of inset c_near (face at y = 0) and c_far (face at
// y = dir·depth). Chamfer depth follows max_overhang, so the chamfer under a
// bottom edge never exceeds the limit.
module uh_chamfered_plate(depth, c_far = 0, c_near = 0, dir = -1, max_overhang = 60) {
    cf = max(0, c_far);
    cn = max(0, c_near);
    tf = min(uh_chamfer_depth(cf, max_overhang), depth / 2);
    tn = min(uh_chamfer_depth(cn, max_overhang), depth / 2);
    lv = concat(cn > 0 ? [[0, -cn], [tn, 0]] : [[0, 0]],
                cf > 0 ? [[depth - tf, 0], [depth, -cf]] : [[depth, 0]]);
    if (dir < 0)
        rotate([90, 0, 0]) uh_slice_stack(lv) children();
    else
        mirror([0, 1, 0]) rotate([90, 0, 0]) uh_slice_stack(lv) children();
}

// =====================================================================
//  3D cutters (entry face y = 0, into material toward −Y)
// =====================================================================

// Horizontal teardrop hole (P4); center = true centres it on y = 0.
module uh_teardrop_prism(d, len, max_overhang = 60, center = false, compensate = true) {
    uh_face_extrude(len, -1, center) uh_teardrop2d(d, max_overhang, compensate);
}

// Horizontal channel with rectangular section size = [w, h] and a peaked roof (P5),
// section centred on the origin; center = true centres it on y = 0.
module uh_peaked_prism(size, len, max_overhang = 60, r_bottom = 0, center = false) {
    uh_face_extrude(len, -1, center) uh_peaked_rect2d(size, max_overhang, r_bottom, true);
}

// Screw hole through a wall of thickness t: enters at y = 0, head on the face y = −t.
//   style     "plain" | "countersink" | "counterbore"
//   head_d    head diameter, 0 = 2·d          cb_depth  counterbore depth
//   cs_angle  countersink included angle      head_ext  head clearance beyond y = −t
//   slot      vertical slot length (0 = round) for levelling
// All parts are teardrop-shaped (P4); the countersink is a teardrop cone.
module uh_screw_hole(d, t, style = "plain", head_d = 0, cb_depth = 3, cs_angle = 90,
                     head_ext = 0, slot = 0, max_overhang = 60, compensate = true) {
    mo  = max_overhang;
    hd  = uh_auto(head_d, 2 * d);
    csd = min(uh_countersink_depth(d, hd, cs_angle), t);
    cbd = uh_clamp(cb_depth, 0, t);
    uh_warn(style != "countersink" || csd <= t - 1.2,
            str("uh_screw_hole: countersink depth ", csd, " leaves less than 1.2 mm of wall"));
    uh_warn(style != "counterbore" || cbd <= t - 1.2,
            str("uh_screw_hole: counterbore depth ", cbd, " leaves less than 1.2 mm of wall"));

    render(convexity = 4) {   // one solid for a clean F5 preview
    // bore, from just outside y = 0 to just past the head face
    _uh_zspan(slot)
        translate([0, UH_EPS, 0]) uh_teardrop_prism(d, t + 2 * UH_EPS, mo, false, compensate);

    if (style == "countersink")
        _uh_zspan(slot)
            hull() {
                translate([0, -t + csd, 0])     uh_teardrop_prism(d,  UH_TINY, mo, false, compensate);
                translate([0, -t + UH_TINY, 0]) uh_teardrop_prism(hd, UH_TINY, mo, false, compensate);
            }

    if (style == "counterbore")
        _uh_zspan(slot)
            translate([0, -t + cbd, 0]) uh_teardrop_prism(hd, cbd + UH_EPS, mo, false, compensate);

    if (style == "countersink" || style == "counterbore")
        _uh_zspan(slot)
            translate([0, -t, 0]) uh_teardrop_prism(hd, head_ext + UH_EPS, mo, false, compensate);
    }
}

// Hull of children at z = 0 and z = len (vertical slot sweep); plain children if len = 0.
module _uh_zspan(len) {
    if (len > UH_TINY)
        hull() { children(); translate([0, 0, len]) children(); }
    else
        children();
}

// Keyhole for hanging on a screw head. Entry face y = 0 lies against the wall;
// the entry centre is on the origin and the shank slot rises by slot_len.
//   d        shank slot width               head_d   entry and head channel width
//   skin     outer skin thickness           head_h   head channel depth behind the skin
//   through  extra channel length, e.g. to open the pocket into the cavity (no blind pocket)
module uh_keyhole(d, head_d, slot_len, skin = 1.6, head_h = 3, through = 0,
                  max_overhang = 60, compensate = true) {
    mo = max_overhang;
    render(convexity = 4) {   // one solid for a clean F5 preview
    // outer skin: shank slot plus head entry
    translate([0, UH_EPS, 0])
        uh_face_extrude(skin + 2 * UH_EPS, -1) {
            uh_slot2d(d, slot_len, mo, compensate);
            uh_teardrop2d(head_d, mo, compensate);
        }
    // head channel behind the skin
    translate([0, -skin, 0])
        uh_face_extrude(head_h + through, -1) uh_slot2d(head_d, slot_len, mo, compensate);
    }
}

// Flared tunnel for zip ties, straps or hose clamps, centred on the origin.
//   axis "x"  horizontal along X: section w tall (Z) × t deep (Y), peaked roof (P5)
//   axis "z"  vertical along Z:   section w wide (X) × t deep (Y)
// len is the distance between the two faces; flare widens both ends by `flare` per side.
module uh_tunnel(w, t, len, flare = 0, axis = "x", max_overhang = 60) {
    mo = max_overhang;
    f  = max(0, flare);
    a  = len / 2 - uh_flare_len(f, mo, axis == "z" ? "z" : "x");
    b  = len / 2 + UH_EPS;
    assert(a > 0, "uh_tunnel: flares are longer than the tunnel");
    render(convexity = 4) if (axis == "z") {
        hull() { _uh_zslab(-a) square([w, t], center = true); _uh_zslab(a) square([w, t], center = true); }
        for (s = [-1, 1]) hull() {
            _uh_zslab(s * a) square([w, t], center = true);
            _uh_zslab(s * b) square([w + 2 * f, t + 2 * f], center = true);
        }
    } else {
        hull() { _uh_xslab(-a) uh_peaked_rect2d([t, w], mo); _uh_xslab(a) uh_peaked_rect2d([t, w], mo); }
        for (s = [-1, 1]) hull() {
            _uh_xslab(s * a) uh_peaked_rect2d([t, w], mo);
            _uh_xslab(s * b) uh_peaked_rect2d([t + 2 * f, w + 2 * f], mo);
        }
    }
}

// thin slab of a 2D profile: (a, b) -> (Y = a, Z = b) at X = x
module _uh_xslab(x) {
    translate([x, 0, 0]) rotate([90, 0, 90]) linear_extrude(UH_TINY, center = true) children();
}

// thin slab of a 2D profile in the XY plane at Z = z
module _uh_zslab(z) {
    translate([0, 0, z]) linear_extrude(UH_TINY, center = true) children();
}

// =====================================================================
//  3D additions
// =====================================================================

// Protrusion with a support slope below it (P6, "hull-down").
// Children: one convex 2D profile drawn as (x, z) in absolute heights.
// The profile is extruded out of the face at y = 0 by depth toward dir; its underside
// is supported by a slope rising at beta from the face. clip = true cuts at z = 0.
module uh_supported_prism(depth, max_overhang = 60, dir = 1, clip = true) {
    if (clip)
        render(convexity = 2)   // real bounding box in the F5 preview (View All), not the clip cube
            intersection() {
                _uh_supported_hull(depth, max_overhang, dir) children();
                translate([-UH_BIG / 2, -UH_BIG / 2, 0]) cube(UH_BIG);
            }
    else
        _uh_supported_hull(depth, max_overhang, dir) children();
}

module _uh_supported_hull(depth, max_overhang, dir) {
    hull() {
        uh_face_extrude(depth, dir) children();
        translate([0, 0, -uh_rise(depth, max_overhang)]) uh_face_extrude(UH_TINY, dir) children();
    }
}
