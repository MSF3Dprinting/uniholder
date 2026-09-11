// =====================================================================
//  UniHolder — lib/uh_mount.scad                             ST-3, ST-4
//  Wall mounting: back holes (plain, countersink, counterbore, keyhole) seated
//  flush in the back wall, wings with holes and gussets (ST-3); vertical and
//  horizontal pole saddles with zip-tie tunnels (ST-4). Nothing enters the item space.
//  Publishes keepout rectangles so the hexagon pattern avoids mounts.
//
//  Reads the Customizer parameters of uniholder.scad and the values of
//  uh_body.scad. Include after uh_body.scad.
//
//  Public API
//    Modules    uh_mount_checks  uh_mount_external  uh_mount_cutters
//    Values     BH_* (back holes)  WG_* (wings)  POLE_*, PV_*, PH_* (pole mount)
//    Functions  uh_mount_keepouts(wall)
// =====================================================================

RIM = 2.4;   // material kept around a screw head (hexagon keepouts)

// n positions from lo to hi: spread evenly (pitch = 0) or at a pitch, centred
function _uh_spread(n, lo, hi, pitch, single) =
      n <= 1 ? [single]
    : let(pmax = (hi - lo) / (n - 1),
          p    = pitch > 0 ? min(pitch, pmax) : pmax)
      [for (i = [0:n - 1]) (lo + hi) / 2 + (i - (n - 1) / 2) * p];

// ---- back holes ---------------------------------------------------------

BH_KEY  = back_hole_style == "keyhole";
BH_SLOT = BH_KEY ? BH_HEAD + 2 : 0;                         // keyhole travel
BH_R    = BH_HEAD / 2 + RIM;                                // hexagons keep clear around a hole
BH_TOP  = uh_teardrop_apex(BH_HEAD / 2, MO) + RIM;          // ... and above it

// hole centres: heads stay on the flat inner back face, clear of corner radii, cove and rim
BH_X_LIM = IN_W / 2 - R_IN[2] - BH_HEAD / 2 - 1;
BH_Z_MIN = floor_t + COVE + BH_HEAD / 2 + 1;
BH_Z_MAX = BODY_H - max(C_TOP_OUT, C_TOP_IN) - uh_teardrop_apex(BH_HEAD / 2, MO) - BH_SLOT - 2;
BH_COLS  = max(1, min(back_hole_cols, floor(2 * BH_X_LIM / (BH_HEAD + 2)) + 1));
BH_ROWS  = max(1, min(back_hole_rows, floor((BH_Z_MAX - BH_Z_MIN) / (BH_HEAD + 2)) + 1));
BH_POS   = !BH_ACTIVE ? [] :
    [for (x = _uh_spread(BH_COLS, -BH_X_LIM, BH_X_LIM, back_hole_pitch_x, 0))
        for (z = _uh_spread(BH_ROWS, BH_Z_MIN, BH_Z_MAX, back_hole_pitch_z,
                            BH_Z_MIN + (BH_Z_MAX - BH_Z_MIN) * 2 / 3))
            [x, z]];

// ---- wings ----------------------------------------------------------------

WG_SIDES  = wings == "left" ? [-1] : wings == "right" ? [1] : wings == "both" ? [-1, 1] : [];
WG_HEAD   = 2 * wing_hole_d;
WG_SLOT   = wing_hole_style == "slot" ? 6 : 0;
WG_R      = 3;                                              // tip corner radius (E4-safe)
WG_CH     = min(0.8, wing_t / 4);                           // front-face chamfer
WG_TIP_H  = (wing_h <= 0 || wing_h >= BODY_H) ? BODY_H
          : uh_clamp_warn(wing_h, WG_HEAD + 8, BODY_H, "wing_h");
WG_RAISED = wing_align == "top" && WG_TIP_H < BODY_H;
WG_Z_TOP  = WG_RAISED ? BODY_H : WG_TIP_H;
WG_ROOT_X = BODY_W / 2 - max(wall_t, R_OUT[2]);             // plate starts inside the body
WG_LEN_T  = BODY_W / 2 + wing_len - WG_ROOT_X;              // outline length, root to tip
WG_Z_ROOT = WG_RAISED ? WG_Z_TOP - WG_TIP_H - uh_rise(WG_LEN_T, MO) : 0;   // < 0 is clipped
WG_G_RAW  = wing_gusset ? min(0.4 * wing_len, 10, wing_len - WG_HEAD - 3) : 0;
WG_G      = WG_G_RAW >= 3 ? WG_G_RAW : 0;                   // gusset length along the wing
WG_HOLE_X = BODY_W / 2 + (WG_G + wing_len) / 2;             // centred in the free wing length
WG_UNDER  = WG_RAISED ? max(0, WG_Z_ROOT + uh_rise(WG_HOLE_X - WG_ROOT_X, MO)) : 0;
WG_HZ_MIN = WG_UNDER + max(C_BOT, WG_CH) + WG_HEAD / 2 + 2;
WG_HZ_MAX = WG_Z_TOP - uh_teardrop_apex(WG_HEAD / 2, MO) - WG_SLOT - 2;
WG_N      = max(1, min(wing_hole_count, floor((WG_HZ_MAX - WG_HZ_MIN) / (WG_HEAD + 2)) + 1));
WG_HZ     = _uh_spread(WG_N, WG_HZ_MIN, WG_HZ_MAX, 0, (WG_HZ_MIN + WG_HZ_MAX) / 2);

// ---- pole mount (ST-4) -------------------------------------------------------
// A block behind the back wall carries a V-cradle for the pole; zip ties run through
// tunnels between the back face and the cradle apex and wrap around the pole.

POLE_ON    = pole_mount != "none";
POLE_VERT  = pole_mount == "vertical";
TIE_FLARE  = 1.0;                                            // flare at each tunnel exit
POLE_RIM   = 3.0;                                            // material beside the groove
POLE_TH    = (POLE_ON && !POLE_VERT)                         // horizontal: upper flank >= beta (P2)
           ? uh_clamp_warn(pole_v_angle, 2 * uh_beta(MO), 150, "pole_v_angle") : pole_v_angle;
POLE_C     = (pole_d / 2) * pow(cos(POLE_TH / 2), 2) / sin(POLE_TH / 2);   // contact depth below apex
POLE_G     = POLE_C + 2;                                     // groove depth
POLE_YA    = tie_t + 2 * TIE_FLARE + 2 * MIN_SKIN;           // apex distance from the back face
POLE_DEPTH = POLE_YA + POLE_G;                               // block depth behind the back face
POLE_SIZE  = 2 * POLE_G * tan(POLE_TH / 2) + 2 * POLE_RIM;   // block width (vertical) or height (horizontal)
POLE_YT    = POLE_YA / 2;                                    // tunnel centre
POLE_FIX   = BACK_T / 2;                                     // block reaches into the back wall
TIE_PITCH  = tie_w + 2 * TIE_FLARE + 4;                      // minimum tunnel spacing

// vertical pole: full-height block, horizontal tunnels spread over the height
PV_Z_LO = tie_w / 2 + TIE_FLARE + uh_roof_h(tie_t + 2 * TIE_FLARE, MO) + 4;
PV_Z_HI = BODY_H - C_TOP_OUT - PV_Z_LO;
PV_N    = max(1, min(tie_count, floor((PV_Z_HI - PV_Z_LO) / TIE_PITCH) + 1));
PV_ZS   = _uh_spread(PV_N, PV_Z_LO, PV_Z_HI, 0, BODY_H / 2);

// horizontal pole: block along the rim with a support slope below, vertical tunnels
PH_L    = BODY_W - 2 * max(R_OUT[2], 1);
PH_ZB   = BODY_H - POLE_SIZE;                                // underside at the rear face
PH_ZC   = BODY_H - POLE_SIZE / 2;                            // cradle axis height
PH_X_LO = -PH_L / 2 + tie_w / 2 + TIE_FLARE + 3;
PH_N    = max(1, min(tie_count, floor((-2 * PH_X_LO) / TIE_PITCH) + 1));
PH_XS   = _uh_spread(PH_N, PH_X_LO, -PH_X_LO, 0, 0);
function _uh_ph_slope_z(y) = PH_ZB - uh_rise(POLE_DEPTH - y, MO);

POLE_N    = POLE_VERT ? PV_N : PH_N;
POLE_KEEP = POLE_VERT ? [-POLE_SIZE / 2 - 1, -1, POLE_SIZE / 2 + 1, BODY_H + 1]
                      : [-PH_L / 2 - 1, _uh_ph_slope_z(0) - 1, PH_L / 2 + 1, BODY_H + 1];

// ---- checks -----------------------------------------------------------------

module uh_mount_checks() {
    if (BH_ACTIVE) {
        assert(BH_X_LIM >= 0 && BH_Z_MAX >= BH_Z_MIN,
            "UniHolder: the back wall is too small for these back holes - reduce back_hole_d or the head size");
        uh_warn(BH_COLS == back_hole_cols && BH_ROWS == back_hole_rows,
            str("back holes reduced to ", BH_COLS, " x ", BH_ROWS, " so the heads do not overlap"));
        uh_warn(back_hole_pitch_x == 0 || BH_COLS < 2 || back_hole_pitch_x <= 2 * BH_X_LIM / (BH_COLS - 1),
            "back_hole_pitch_x reduced to fit the back wall");
        uh_warn(back_hole_pitch_z == 0 || BH_ROWS < 2 || back_hole_pitch_z <= (BH_Z_MAX - BH_Z_MIN) / (BH_ROWS - 1),
            "back_hole_pitch_z reduced to fit the back wall");
        uh_info(str("back holes: ", len(BH_POS), " x ", back_hole_style, " d ", back_hole_d,
                    BACK_T > back_t ? str(", back wall thickened to ", BACK_T, " mm") : ""));
        uh_warn(size_mode == "inner" || BACK_T <= back_t,
            str("back wall thickened to ", BACK_T, " mm to seat the screw heads - inner depth is reduced"));
    }
    if (len(WG_SIDES) > 0) {
        assert(wing_len - WG_G >= WG_HEAD + 2, "UniHolder: wing_len is too short for wing_hole_d");
        assert(WG_HZ_MAX >= WG_HZ_MIN, "UniHolder: the wing is too low for its holes - increase wing_h");
        uh_warn(WG_N == wing_hole_count, str("wing_hole_count reduced to ", WG_N, " to fit the wing"));
        uh_warn(!wing_gusset || WG_G > 0, "wing is too short for a gusset - gusset omitted");
        uh_info(str("wings: ", wings, ", ", WG_N, " holes each, tip height ", WG_TIP_H, " mm"));
    }
    if (POLE_ON) {
        assert(POLE_VERT || POLE_SIZE <= BODY_H,
            "UniHolder: the holder is too low for a horizontal pole mount of this diameter");
        uh_warn(!POLE_VERT || POLE_SIZE <= BODY_W, "the pole block is wider than the holder");
        uh_warn(POLE_N == tie_count, str("tie_count reduced to ", POLE_N, " to fit the pole block"));
        if (back_holes) uh_info("back holes are not used with a pole mount");
        uh_info(str("pole mount: ", pole_mount, ", pole d ", pole_d, " mm, V ", POLE_TH, " deg, block ",
                    POLE_SIZE, " x ", POLE_DEPTH, " mm, ", POLE_N, " zip-tie tunnels ", tie_w, " x ", tie_t, " mm"));
    }
}

// ---- keepouts for the hexagon pattern ---------------------------------------

function uh_mount_keepouts(wall) =
      wall == "back" ? concat([for (p = BH_POS) [p[0] - BH_R, p[1] - BH_R, p[0] + BH_R, p[1] + BH_TOP + BH_SLOT]],
                              POLE_ON ? [POLE_KEEP] : [])
    : ((wall == "left"  && len([for (s = WG_SIDES) if (s < 0) s]) > 0) ||
       (wall == "right" && len([for (s = WG_SIDES) if (s > 0) s]) > 0))
          ? [[-wing_t - WG_G - wall_t - 1, max(0, WG_Z_ROOT) - 1, 1, WG_Z_TOP + 1]]
    : [];

// ---- geometry -----------------------------------------------------------------

module uh_mount_external() {
    for (s = WG_SIDES)
        if (s > 0) _uh_wing_right();
        else mirror([1, 0, 0]) _uh_wing_right();
    if (POLE_ON) _uh_pole_block();
}

module uh_mount_cutters() {
    for (p = BH_POS)
        translate([p[0], 0, p[1]])
            if (BH_KEY) uh_keyhole(back_hole_d, BH_HEAD, BH_SLOT, KEY_SKIN, KEY_HEAD, 0, MO);
            else        uh_screw_hole(back_hole_d, BACK_T, back_hole_style, BH_HEAD, CB_DEPTH, 90, 2, 0, MO);
    for (s = WG_SIDES, z = WG_HZ)
        translate([s * WG_HOLE_X, 0, z])
            uh_screw_hole(wing_hole_d, wing_t, wing_hole_style == "countersink" ? "countersink" : "plain",
                          WG_HEAD, 3, 90, 1, WG_SLOT, MO);
    if (POLE_ON) {
        _uh_pole_groove();
        _uh_pole_tunnels();
    }
}

// Wing outline in (x, z): cantilever from the root, clipped at the bed
module _uh_wing_outline() {
    intersection() {
        translate([WG_ROOT_X, WG_Z_ROOT])
            uh_cantilever2d(WG_LEN_T, WG_Z_TOP - WG_Z_ROOT, MO, WG_R, on_bed = !WG_RAISED);
        translate([WG_ROOT_X - 1, 0]) square([WG_LEN_T + 2, BODY_H + 1]);
    }
}

// Right wing (+X); the left wing is its mirror image
module _uh_wing_right() {
    rf = max(0.2, min(1.5, wing_t / 2 - 0.2));
    tb = wing_t >= BACK_T ? BACK_T - 0.2 : wing_t;          // stay 0.2 mm off the cavity's back face
    intersection() {
        // plate: flush back face, chamfered front face and bed edges
        uh_chamfered_plate(wing_t, c_far = WG_CH, c_near = C_BOT, dir = -1, max_overhang = MO)
            _uh_wing_outline();
        // plan view: filleted tip edges (E1); inside the body only within wall material,
    // 0.2 mm clear of the cavity faces so no faces coincide
        translate([0, 0, -1]) linear_extrude(BODY_H + 2, convexity = 4)
            intersection() {
                translate([WG_ROOT_X - 1, -wing_t])
                    uh_rrect4([WG_LEN_T + 1, wing_t], [0, rf, rf, 0], center = false);
                union() {
                    translate([WG_ROOT_X - 1, -tb]) square([WG_LEN_T + 2, tb]);
                    translate([BODY_W / 2 - wall_t + 0.2, -wing_t]) square([wing_len + wall_t + 0.8, wing_t]);
                }
            }
    }
    // gusset: vertical 45° fin between wing front face and side wall, following the wing outline
    if (WG_G > 0)
        intersection() {
            translate([0, 0, -1]) linear_extrude(BODY_H + 2)
                polygon([[BODY_W / 2 - wall_t + 0.2, -wing_t + UH_EPS],
                         [BODY_W / 2 + WG_G,   -wing_t + UH_EPS],
                         [BODY_W / 2 - wall_t + 0.2, -wing_t - WG_G - wall_t]]);
            translate([0, 1, 0]) uh_face_extrude(wing_t + WG_G + wall_t + 2) _uh_wing_outline();
        }
}

// ---- pole mount geometry (ST-4) ---------------------------------------------------

module _uh_pole_block() {
    if (POLE_VERT)   // stands on the bed: no overhang; rear vertical edges rounded for the ties
        uh_chamfered_extrude(BODY_H, C_BOT, C_TOP_OUT, MO)
            translate([-POLE_SIZE / 2, -POLE_FIX])
                uh_rrect4([POLE_SIZE, POLE_DEPTH + POLE_FIX], [0, 0, 2, 2], center = false);
    else             // hangs at the rim: support slope below (P6), clipped at the bed
        translate([0, -POLE_FIX, 0])
            uh_supported_prism(POLE_DEPTH + POLE_FIX, MO, dir = 1)
                translate([-PH_L / 2, PH_ZB]) uh_rrect4([PH_L, POLE_SIZE], [2, 2, 0, 0], center = false);
}

// V-cradle; the horizontal one has its upper flank at >= beta above horizontal
module _uh_pole_groove() {
    ext = POLE_G + 1;
    hw  = ext * tan(POLE_TH / 2);
    if (POLE_VERT)
        translate([0, 0, -1]) linear_extrude(BODY_H + 2, convexity = 2)
            polygon([[0, POLE_YA], [hw, POLE_YA + ext], [-hw, POLE_YA + ext]]);
    else
        translate([0, 0, PH_ZC]) rotate([90, 0, 90])
            linear_extrude(PH_L + 2, center = true, convexity = 2)
                polygon([[POLE_YA, 0], [POLE_YA + ext, hw], [POLE_YA + ext, -hw]]);
}

// Zip-tie tunnels between the back face and the cradle apex
module _uh_pole_tunnels() {
    if (POLE_VERT)
        for (z = PV_ZS)
            translate([0, POLE_YT, z]) uh_tunnel(tie_w, tie_t, POLE_SIZE, TIE_FLARE, "x", MO);
    else
        for (x = PH_XS) {
            z0 = max(0, _uh_ph_slope_z(POLE_YT - tie_t / 2 - TIE_FLARE)) - 0.5;
            z1 = BODY_H + 0.5;
            translate([x, POLE_YT, (z0 + z1) / 2]) uh_tunnel(tie_w, tie_t, z1 - z0, TIE_FLARE, "z", MO);
        }
}
