// =====================================================================
//  UniHolder — lib/uh_din.scad                                    ST-5
//  Clip for TS35 × 7.5 DIN rail (EN 60715), printed as a separate part.
//
//  The clip is one 2D profile extruded along the rail and printed lying on
//  that profile: every wall is vertical in print (no supports), and the
//  spring beams bend within the layers.
//    * fixed hook on top; spring latch below with a 45° lead-in ramp
//    * zig-zag spring of thin in-plane beams; release tab below the spring
//    * two nuts (M3 ... M6, din_bolt) in hexagonal pockets; the holder is bolted
//      on with two screws through its DIN hole pattern (din_holes)
//  Mounting: hook the top over the rail and press the bottom until the latch
//  snaps. Removal: lever the release tab down with a flat screwdriver.
//
//  Profile frame (u, v): u = distance from the holder's back face toward the
//  panel, v = height above the rail centreline; the rail lips rest on the
//  plate face u = DIN_P. Include after uh_body.scad, before uh_mount.scad.
// =====================================================================

// TS35 × 7.5 rail
DIN_E       = 17.5;   // half width over the lips
DIN_LIP_W   = 4.0;    // lip width (lip roots at |v| = 13.5)
DIN_DEPTH   = 7.5;    // lip face to panel
DIN_LIP_T   = 1.5;    // lip thickness allowed (standard rails are 1.0 mm)

// bolts joining holder and clip (M3 ... M6)
DIN_BOLT       = uh_metric(din_bolt);
DIN_BOLT_PITCH = din_bolt == "M6" ? 24 : 20;     // bolt spacing along the rail
DIN_BOLT_D     = DIN_BOLT[0];                    // clearance hole
DIN_NUT_AF     = DIN_BOLT[1] + 0.4;              // nut pocket across flats
DIN_NUT_H      = DIN_BOLT[2] + 0.4;              // nut pocket depth

// clip profile
DIN_P       = max(5.0, DIN_NUT_H + MIN_SKIN);    // plate thickness (holds the nut); lips rest on u = DIN_P
DIN_CLR     = 0.3;
DIN_TOOTH_U = 2.0;    // tooth thickness behind the lip
DIN_TOOTH_V = 2.5;    // tooth engagement behind the lip edge
DIN_ARM     = 3.0;    // hook arm thickness
DIN_PRELOAD = 0.5;    // latch overlaps the lip edge at rest (spring preload)
DIN_GAP     = 0.5;    // gap between moving and fixed parts
DIN_SPINE   = 2.5;    // plate spine beside the spring
DIN_BEAM_T  = 0.9;    // spring beam thickness (two perimeters)
DIN_BEAM_G  = 0.8;    // gap between spring beams
DIN_BEAMS   = 9;      // odd: the last beam meets the anchor on the spine side
DIN_CONN    = 1.0;    // spring connector width
DIN_ROD     = 0.8;    // release rod thickness
DIN_SLOT    = 1.5;    // screwdriver slot above the release tab
DIN_TAB     = 2.5;    // release tab height

// derived: u
DIN_UT   = DIN_P + DIN_LIP_T;                     // tooth front face
DIN_UB   = DIN_UT + DIN_TOOTH_U;                  // hook tooth back face
DIN_UMAX = DIN_P + DIN_DEPTH - 0.3;               // clear of the panel
DIN_U0   = DIN_SPINE + DIN_GAP;                   // front of the moving parts
DIN_US   = DIN_UMAX - DIN_ROD - DIN_GAP;          // far end of the spring
// derived: v (rest state)
DIN_V_TOP    = DIN_E + DIN_CLR + DIN_ARM;         // top of the clip
DIN_LB_TOP   = -DIN_E + DIN_PRELOAD;              // latch top face
DIN_T_TOP    = DIN_LB_TOP + DIN_TOOTH_V;          // latch tooth top
DIN_RAMP_V   = -DIN_E - 1;                        // lead-in ramp ends below the lip edge
DIN_RAMP_U   = DIN_UT + 0.4 + (DIN_T_TOP - DIN_RAMP_V);   // 45° ramp
DIN_LB_BOT   = DIN_RAMP_V - 2;
function _din_beam_top(i) = DIN_LB_BOT - DIN_BEAM_G - i * (DIN_BEAM_T + DIN_BEAM_G);
DIN_ANCH_TOP = _din_beam_top(DIN_BEAMS - 1) - DIN_BEAM_T - DIN_BEAM_G;
DIN_ANCH_BOT = DIN_ANCH_TOP - 3;
DIN_TAB_TOP  = DIN_ANCH_BOT - DIN_SLOT;
DIN_V_BOT    = DIN_TAB_TOP - DIN_TAB;             // bottom of the clip
DIN_PLATE_LO = DIN_LB_TOP + DIN_GAP;              // plate underside above the latch
DIN_W_MIN    = DIN_BOLT_PITCH + 2 * (uh_hex_dims(DIN_NUT_AF, MO)[3] / 2 + 1.2);
DIN_W        = din_clip_w > 0 ? din_clip_w : max(36, ceil(DIN_W_MIN));   // clip width along the rail

// screw length: through the holder's back wall and the clip plate into the nut
DIN_SCREW_MIN = (BH_STYLE == "counterbore" ? BACK_T - CB_DEPTH : BACK_T) + DIN_P - 0.4;
DIN_SCREW_L   = let(c = [for (l = [6, 8, 10, 12, 16, 20, 25, 30, 35, 40]) if (l >= DIN_SCREW_MIN) l])
                len(c) > 0 ? c[0] : ceil(DIN_SCREW_MIN);

module _uh_din_r(u0, v0, u1, v1) { translate([u0, v0]) square([u1 - u0, v1 - v0]); }

// fixed part: plate, hook, spine, spring anchor
module _uh_din_fixed2d() {
    _uh_din_r(0, DIN_PLATE_LO, DIN_P, DIN_V_TOP);
    _uh_din_r(DIN_P - 0.01, DIN_E + DIN_CLR, DIN_UB, DIN_V_TOP);
    polygon([[DIN_UT, DIN_E + DIN_CLR + 0.01], [DIN_UT, DIN_E - DIN_TOOTH_V],
             [DIN_UB - 1.2, DIN_E - DIN_TOOTH_V], [DIN_UB, DIN_E - DIN_TOOTH_V + 1.2],
             [DIN_UB, DIN_E + DIN_CLR + 0.01]]);
    _uh_din_r(0, DIN_ANCH_BOT, DIN_SPINE, DIN_PLATE_LO + 0.01);
    _uh_din_r(0, DIN_ANCH_BOT, DIN_US, DIN_ANCH_TOP);
}

// moving part: latch with tooth and ramp, zig-zag spring, release rod and tab
module _uh_din_latch2d() {
    polygon([[DIN_U0, DIN_LB_BOT], [DIN_U0, DIN_LB_TOP], [DIN_UT, DIN_LB_TOP], [DIN_UT, DIN_T_TOP],
             [DIN_UT + 0.4, DIN_T_TOP], [DIN_RAMP_U, DIN_RAMP_V], [DIN_UMAX, DIN_RAMP_V],
             [DIN_UMAX, DIN_LB_BOT]]);
    for (i = [0:DIN_BEAMS - 1])
        _uh_din_r(DIN_U0, _din_beam_top(i) - DIN_BEAM_T, DIN_US, _din_beam_top(i));
    for (k = [0:DIN_BEAMS]) {
        above = k == 0 ? DIN_LB_BOT : _din_beam_top(k - 1) - DIN_BEAM_T;
        below = k == DIN_BEAMS ? DIN_ANCH_TOP : _din_beam_top(k);
        cu = k % 2 == 0 ? DIN_US - DIN_CONN : DIN_U0;
        _uh_din_r(cu, below - 0.01, cu + DIN_CONN, above + 0.01);
    }
    _uh_din_r(DIN_US + DIN_GAP, DIN_TAB_TOP - 0.01, DIN_UMAX, DIN_LB_BOT + 0.01);
    _uh_din_r(DIN_U0, DIN_V_BOT, DIN_UMAX, DIN_TAB_TOP);
}

module uh_din_profile2d() { _uh_din_fixed2d(); _uh_din_latch2d(); }

// The clip in print orientation: profile on the bed, rail axis = +Z
module uh_din_clip() {
    assert(DIN_W >= DIN_W_MIN, str("UniHolder: din_clip_w must be at least ", ceil(DIN_W_MIN), " mm for ", din_bolt, " nuts"));
    difference() {
        linear_extrude(DIN_W, convexity = 10) uh_din_profile2d();
        for (s = [-1, 1])
            translate([0, 0, DIN_W / 2 + s * DIN_BOLT_PITCH / 2]) {
                translate([-1, 0, 0]) rotate([0, 0, 90]) uh_teardrop_prism(DIN_BOLT_D, DIN_P + 2, MO);
                translate([DIN_P - DIN_NUT_H, 0, 0]) rotate([0, 0, 90])
                    uh_face_extrude(DIN_NUT_H + 1) uh_hex_cell2d(DIN_NUT_AF, MO);
            }
    }
}

// Mounted position behind the holder (u -> +Y, v -> Z at DIN_Z, rail axis -> X)
module uh_din_clip_in_use() {
    multmatrix([[0, 0, 1, -DIN_W / 2], [1, 0, 0, 0], [0, 1, 0, DIN_Z], [0, 0, 0, 1]]) uh_din_clip();
}

// TS35 × 7.5 reference rail (1 mm) in the mounted frame; shift_u moves it away from the plate
module uh_din_rail(shift_u = 0, len = 120) {
    multmatrix([[0, 0, 1, -len / 2], [1, 0, 0, 0], [0, 1, 0, DIN_Z], [0, 0, 0, 1]])
        linear_extrude(len) translate([shift_u, 0]) {
            for (s = [-1, 1]) {
                translate([DIN_P, s > 0 ? DIN_E - DIN_LIP_W : -DIN_E]) square([1, DIN_LIP_W]);
                translate([DIN_P, s > 0 ? DIN_E - DIN_LIP_W - 1 : -DIN_E + DIN_LIP_W]) square([DIN_DEPTH, 1]);
            }
            translate([DIN_P + DIN_DEPTH - 1, -(DIN_E - DIN_LIP_W)]) square([1, 2 * (DIN_E - DIN_LIP_W)]);
        }
}

// Clip beside the holder on the same bed
module uh_din_clip_beside() {
    wx = (len(WG_SIDES) > 0 && max(WG_SIDES) > 0) ? wing_len : 0;
    translate([BODY_W / 2 + wx + 10, -BODY_D / 2 - (DIN_V_TOP + DIN_V_BOT) / 2, 0]) uh_din_clip();
}
