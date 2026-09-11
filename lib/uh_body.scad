// =====================================================================
//  UniHolder — lib/uh_body.scad                                   ST-2
//  Holder body: derived dimensions, outer shell, cavity, hexagon
//  perforation of walls and floor, front opening.
//
//  Reads the Customizer parameters of uniholder.scad.
//  Include after uh_core.scad and uh_shapes.scad.
//  Frame: y = 0 is the mounting plane (outer back face) and the body
//  extends to −Y; x = 0 is the centreline; z = 0 is the print bed.
//
//  Public API
//    Values     MO  BACK_T  BODY_W  BODY_D  BODY_H  IN_X0  IN_X1  IN_Y0  IN_Y1  IN_W  IN_D
//               R_OUT  R_IN  C_BOT  C_TOP_OUT  C_TOP_IN  C_CUT  COVE
//    Modules    uh_body_checks  uh_outer_shell  uh_cavity  uh_item_space  uh_perforations
//               uh_front_opening  uh_wall_cut  uh_hex_grid2d
//    Functions  uh_wall_zone  uh_hex_cells  uh_keepouts
// =====================================================================

// ---- derived values ---------------------------------------------------

MO = uh_clamp_warn(max_overhang, UH_OVERHANG_MIN, UH_OVERHANG_MAX, "max_overhang");

// Back wall thickness. Screw heads must sit flush inside the wall: nothing may
// protrude into the item space, so the whole wall thickens instead of adding bosses.
// In inner mode the body grows backwards and the item space keeps its size.
KEY_SKIN  = 2.0;   // keyhole: wall-side skin that carries the screw head
KEY_HEAD  = 3.5;   // keyhole: head channel depth behind the skin
CB_DEPTH  = 3.0;   // counterbore depth
MIN_SKIN  = 1.2;   // material left behind a seated head
BH_ACTIVE = back_holes && pole_mount == "none";   // a pole mount replaces the back holes
BH_HEAD   = uh_auto(back_hole_head_d, 2 * back_hole_d);    // screw head incl. clearance
BH_NEED   = !BH_ACTIVE ? 0
          : back_hole_style == "countersink" ? uh_countersink_depth(back_hole_d, BH_HEAD) + MIN_SKIN
          : back_hole_style == "counterbore" ? CB_DEPTH + MIN_SKIN
          : back_hole_style == "keyhole"     ? KEY_SKIN + KEY_HEAD + MIN_SKIN
          :                                    MIN_SKIN;
BACK_T    = max(back_t, BH_NEED);

BODY_W = size_mode == "inner" ? size_x + 2 * item_clr + 2 * wall_t : size_x;
BODY_D = size_mode == "inner" ? size_y + 2 * item_clr + wall_t + BACK_T : size_y;
BODY_H = size_mode == "inner" ? size_z + floor_t : size_z;

T_MIN    = min(wall_t, BACK_T);
R_IN_MIN = 1.5;                                    // inner corners stay cleanable

// corner radii: front-left, front-right, back-right, back-left
R_OUT = [for (r = [corner_r, corner_r, back_corner_r, back_corner_r])
            uh_clamp(r, 0, min(BODY_W, BODY_D) / 2)];
R_IN  = [for (r = R_OUT) max(r - T_MIN, R_IN_MIN)];

IN_X0 = -BODY_W / 2 + wall_t;    IN_X1 = BODY_W / 2 - wall_t;
IN_Y0 = -BODY_D + wall_t;        IN_Y1 = -BACK_T;
IN_W  = IN_X1 - IN_X0;           IN_D  = IN_Y1 - IN_Y0;

C_BOT     = uh_clamp(chamfer_bottom, 0, min(floor_t, T_MIN / 2));
C_TOP_OUT = uh_clamp(chamfer_top, 0, T_MIN / 2);
C_TOP_IN  = uh_clamp(chamfer_top, 0, max(0, T_MIN - C_TOP_OUT - 0.8));   // keeps a 0.8 mm flat rim
C_CUT     = uh_clamp(chamfer_top, 0, max(0, (wall_t - 0.8) / 2));        // edges of front cut-outs
COVE      = uh_clamp(floor_cove, 0, max(0, min(IN_W, IN_D) / 4));

// distance from a wall end to the straight, perforable part of the wall
CLR_FRONT = max(R_OUT[0], wall_t + R_IN[0]);      // side walls at the front, front wall at the sides
CLR_BACK  = max(R_OUT[2], BACK_T + R_IN[2]);      // side walls at the back
CLR_BACKS = max(R_OUT[2], wall_t + R_IN[2]);      // back wall at the sides

HEX_V0 = floor_t + COVE + hex_bottom_band;        // perforation height range on walls
HEX_V1 = BODY_H - C_TOP_OUT - hex_top_band;

LIP_W  = uh_clamp_warn(front_side_lip_w, wall_t, max(wall_t, BODY_W / 2 - 2), "front_side_lip_w");
LIP_Z  = floor_t + uh_clamp(front_lip_h, 0, max(0, BODY_H - floor_t - 5));
OPEN_W = BODY_W - 2 * LIP_W;
SLOT_W = uh_clamp_warn(front_slot_w, 3, max(3, BODY_W - 2 * CLR_FRONT - 2), "front_slot_w");
SLOT_Z = floor_t + uh_clamp(front_slot_z, 0, max(0, BODY_H - floor_t - 5));

// ---- checks -----------------------------------------------------------

module uh_body_checks() {
    assert(IN_W >= 5 && IN_D >= 5,
        "UniHolder: inner space is below 5 mm - increase the size or reduce the wall thickness");
    assert(BODY_H >= floor_t + 5, "UniHolder: height must exceed the floor by at least 5 mm");
    uh_info(str("outer ", BODY_W, " x ", BODY_D, " x ", BODY_H, " mm, inner ",
                IN_W, " x ", IN_D, " x ", BODY_H - floor_t, " mm"));
}

// ---- shell and cavity -------------------------------------------------

module uh_outer_shell() {
    uh_chamfered_extrude(BODY_H, C_BOT, C_TOP_OUT, MO)
        translate([0, -BODY_D / 2]) uh_rrect4([BODY_W, BODY_D], R_OUT);
}

// Pairwise hull: floor cove (upward-facing), straight walls, flared rim
module uh_cavity() {
    lv = concat(COVE > 0 ? [[floor_t, -COVE], [floor_t + COVE, 0]] : [[floor_t, 0]],
                C_TOP_IN > 0 ? [[BODY_H - C_TOP_IN, 0], [BODY_H + 1, C_TOP_IN + 1]]
                             : [[BODY_H + 1, 0]]);          // cut ends 1 mm above the rim
    uh_slice_stack(lv, pairwise = true)
        translate([(IN_X0 + IN_X1) / 2, (IN_Y0 + IN_Y1) / 2]) uh_rrect4([IN_W, IN_D], R_IN);
}

// The clear item space (straight part of the cavity, inset 0.05 mm). Test hook:
// intersecting it with the holder must give nothing.
module uh_item_space() {
    translate([0, 0, floor_t + COVE + 0.05])
        linear_extrude(BODY_H - floor_t - COVE)
            offset(delta = -0.05)
                translate([(IN_X0 + IN_X1) / 2, (IN_Y0 + IN_Y1) / 2]) uh_rrect4([IN_W, IN_D], R_IN);
}

// ---- hexagon perforation ------------------------------------------------

// Wall zone [u0, v0, u1, v1] in wall-local coordinates:
// back, front: u = x;  left, right: u = y;  floor: u = x, v = y
function uh_wall_zone(wall) =
      wall == "back"  ? [-BODY_W / 2 + CLR_BACKS + hex_margin, HEX_V0, BODY_W / 2 - CLR_BACKS - hex_margin, HEX_V1]
    : wall == "front" ? [-BODY_W / 2 + CLR_FRONT + hex_margin, HEX_V0, BODY_W / 2 - CLR_FRONT - hex_margin, HEX_V1]
    : wall == "floor" ? [IN_X0 + COVE + hex_margin, IN_Y0 + COVE + hex_margin,
                         IN_X1 - COVE - hex_margin, IN_Y1 - COVE - hex_margin]
    :                   [-BODY_D + CLR_FRONT + hex_margin, HEX_V0, -CLR_BACK - hex_margin, HEX_V1];

// Keepout rectangles per wall, published by the mount library (uh_mount.scad)
function uh_keepouts(wall) = uh_mount_keepouts(wall);

// Centres of whole hexagon cells that fit the zone and miss every keepout.
// Rows alternate between n and n − 1 cells, so the pattern stays centred.
function uh_hex_cells(zone, w, strut, mo, keepouts = []) =
    let(cell = uh_hex_dims(w, mo),
        p    = uh_hex_pitch(w, strut, mo),
        zu   = zone[2] - zone[0],
        zv   = zone[3] - zone[1],
        rows = floor((zv - cell[3]) / p[1]) + 1,
        cols = floor((zu - w) / p[0]) + 1,
        uc   = (zone[0] + zone[2]) / 2,
        v0   = zone[1] + (zv - ((rows - 1) * p[1] + cell[3])) / 2 + cell[3] / 2,
        half = [w / 2 + strut, cell[3] / 2 + strut])
    (rows < 1 || cols < 1) ? [] :
    [for (r = [0:rows - 1])
        let(n = r % 2 == 0 ? cols : cols - 1)
        if (n > 0)
            for (c = [0:n - 1])
                let(pt = [uc + (c - (n - 1) / 2) * p[0], v0 + r * p[1]])
                if (!_uh_hits(pt, half, keepouts)) pt];

function _uh_hits(pt, half, ks) =
    len([for (k = ks)
            if (pt[0] - half[0] < k[2] && pt[0] + half[0] > k[0] &&
                pt[1] - half[1] < k[3] && pt[1] + half[1] > k[1]) 1]) > 0;

module uh_hex_grid2d(cells, w, mo) {
    for (p = cells) translate(p) uh_hex_cell2d(w, mo);
}

// Place a 2D wall-local pattern as a cutter through the given wall
module uh_wall_cut(wall) {
    if (wall == "back")
        translate([0, -BACK_T / 2, 0]) uh_face_extrude(BACK_T + 2, center = true) children();
    else if (wall == "front")
        translate([0, -BODY_D + wall_t / 2, 0]) uh_face_extrude(wall_t + 2, center = true) children();
    else if (wall == "left")
        translate([-BODY_W / 2 + wall_t / 2, 0, 0]) rotate([0, 0, 90])
            uh_face_extrude(wall_t + 2, center = true) children();
    else if (wall == "right")
        translate([BODY_W / 2 - wall_t / 2, 0, 0]) rotate([0, 0, 90])
            uh_face_extrude(wall_t + 2, center = true) children();
    else if (wall == "floor")
        translate([0, 0, -1]) linear_extrude(floor_t + 2, convexity = 10) children();
}

module uh_perforations() {
    for (ws = [["back", back_style], ["front", front_style], ["left", left_style],
               ["right", right_style], ["floor", floor_style]])
        if (ws[1] == "hex") {
            cells = uh_hex_cells(uh_wall_zone(ws[0]), hex_size, hex_strut, MO, uh_keepouts(ws[0]));
            uh_warn(len(cells) > 0, str(ws[0], ": no room for a whole hexagon, wall stays solid"));
            if (len(cells) > 0) uh_wall_cut(ws[0]) uh_hex_grid2d(cells, hex_size, MO);
        }
}

// ---- front opening ------------------------------------------------------

module uh_front_opening() {
    if (front_style == "open")
        _uh_front_cut(OPEN_W, LIP_Z, [front_open_r, front_open_r, 0, 0],
                      wall_t + R_IN[0], min(C_CUT, front_lip_h));
    else if (front_style == "slot")
        _uh_front_cut(SLOT_W, SLOT_Z, [SLOT_W / 2, SLOT_W / 2, 0, 0],
                      wall_t + 1, min(C_CUT, front_slot_z));
}

// Cut-out through the front wall: w wide, from height z0 to above the rim,
// lower corners rounded by r. Edges get a chamfer c on the outer and inner face
// (pairwise slice stack along +Y; all chamfer faces look upward or sideways).
module _uh_front_cut(w, z0, r, depth, c) {
    translate([0, -BODY_D - 1, 0]) mirror([0, 1, 0]) rotate([90, 0, 0])
        uh_slice_stack([[0, c + 1], [1 + c, 0], [1 + wall_t - c, 0],
                        [1 + wall_t, c], [1 + depth + UH_EPS, c]], pairwise = true)
            translate([-w / 2, z0]) uh_rrect4([w, BODY_H - z0 + 1], r, center = false);
}
