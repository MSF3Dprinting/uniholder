// =====================================================================
//  UniHolder — parametric universal holder                        v1.0
//  MSF 3D Printing for All · OpenSCAD 2021.01 or newer · no libraries
//
//  Print exactly as generated: standing on its floor, without supports.
//  No downward-facing surface exceeds max_overhang.
//
//  v1.0 (ST-5): DIN rail clip, single-file Customizer version, zip-tie clearance.
//  v0.4 (ST-4): vertical and horizontal pole mounts with zip-tie tunnels.
//               Screw heads seat flush: the back wall thickens, nothing enters the item space.
//  v0.3 (ST-3): back holes; wings with holes and gussets; cleaner F5 preview.
//  v0.2 (ST-2): body, wall styles, hexagon pattern, front opening.
// =====================================================================

/* [Print] */
// What to generate: holder, DIN rail clip, both on one bed, or din_preview (clip shown mounted, for viewing only)
part = "holder"; // [holder, din_clip, holder_and_clip, din_preview]
// Largest overhang in degrees from vertical (60 default, 45 for weak part cooling)
max_overhang = 60; // [40:5:60]
// Render quality
quality = "normal"; // [draft, normal, fine]

/* [Size] */
// inner = size of the item, outer = size of the finished holder
size_mode = "inner"; // [inner, outer]
// Width (X)
size_x = 60; // [10:0.5:400]
// Depth (Y), front to back
size_y = 40; // [10:0.5:400]
// Height (Z)
size_z = 80; // [10:0.5:400]
// Clearance around the item on each side (inner mode)
item_clr = 1; // [0:0.1:10]

/* [Walls and edges] */
// Side and front wall thickness
wall_t = 2.4; // [1.2:0.1:8]
// Back wall thickness (mounting side)
back_t = 3.2; // [1.6:0.1:10]
// Floor thickness
floor_t = 2; // [0.8:0.1:8]
// Radius of the front vertical edges
corner_r = 6; // [0:0.5:40]
// Radius of the back vertical edges
back_corner_r = 1.5; // [0:0.5:40]
// Chamfer of the top edges
chamfer_top = 1; // [0:0.1:5]
// Chamfer of the edges on the print bed
chamfer_bottom = 0.6; // [0:0.1:3]
// Inner chamfer between floor and walls
floor_cove = 2; // [0:0.5:10]

/* [Wall styles] */
back_style = "solid"; // [solid, hex]
left_style = "hex"; // [solid, hex]
right_style = "hex"; // [solid, hex]
// open = cut down to a retaining lip, slot = narrow vertical slot
front_style = "open"; // [solid, hex, open, slot]
floor_style = "solid"; // [solid, hex]

/* [Hex pattern] */
// Hexagon hole width across flats
hex_size = 8; // [3:0.5:40]
// Material between hexagons
hex_strut = 2; // [1.2:0.1:10]
// Solid border at the wall ends
hex_margin = 3; // [1:0.5:30]
// Solid band below the rim
hex_top_band = 6; // [0:0.5:50]
// Solid band above the floor
hex_bottom_band = 4; // [0:0.5:50]

/* [Front opening] */
// Height of the retaining lip above the inner floor (open)
front_lip_h = 20; // [0:0.5:400]
// Width of the retaining edges left and right (open)
front_side_lip_w = 8; // [1.2:0.5:100]
// Radius of the lower corners of the opening (open)
front_open_r = 5; // [0:0.5:50]
// Slot width (slot)
front_slot_w = 12; // [3:0.5:200]
// Height of the slot bottom above the inner floor (slot)
front_slot_z = 15; // [0:0.5:400]

/* [Back holes] */
// Screw holes in the back wall; screws go in from inside the holder
back_holes = true;
// Hole diameter (screw shank clearance)
back_hole_d = 4.5; // [3:0.5:10]
// countersink, counterbore and keyhole seat the head flush inside the back wall (it thickens as needed); plain leaves the head on the inner face
back_hole_style = "countersink"; // [plain, countersink, counterbore, keyhole]
// Screw head diameter including clearance (0 = 2 × hole diameter)
back_hole_head_d = 0; // [0:0.5:22]
// Number of hole columns
back_hole_cols = 1; // [1:1:6]
// Number of hole rows
back_hole_rows = 2; // [1:1:6]
// Horizontal hole spacing (0 = spread across the back wall)
back_hole_pitch_x = 0; // [0:0.5:300]
// Vertical hole spacing (0 = spread over the height)
back_hole_pitch_z = 0; // [0:0.5:300]

/* [Wings] */
// Mounting wings, flush with the back face
wings = "none"; // [none, left, right, both]
// Wing length beyond the side wall
wing_len = 20; // [8:1:100]
// Wing thickness
wing_t = 4; // [2:0.5:10]
// Wing height at the tip (0 = holder height)
wing_h = 0; // [0:1:400]
// bottom = wing stands on the bed; top = wing hangs from the rim with a support slope below
wing_align = "bottom"; // [bottom, top]
// Hole diameter
wing_hole_d = 4.5; // [3:0.5:10]
// slot = vertical slot for levelling
wing_hole_style = "countersink"; // [plain, countersink, slot]
// Holes per wing
wing_hole_count = 2; // [1:1:4]
// Triangular gusset between wing and side wall
wing_gusset = true;

/* [Pole mount] */
// Mount on a round pole with zip ties (replaces the back holes)
pole_mount = "none"; // [none, vertical, horizontal]
// Pole diameter
pole_d = 25; // [8:0.5:80]
// Included angle of the V-cradle; horizontal poles need at least 2 × (90 − max_overhang)
pole_v_angle = 90; // [60:5:150]
// Number of zip ties
tie_count = 2; // [1:1:6]
// Zip tie width (standard ties: 5 mm)
tie_w = 5; // [2:0.5:14]
// Zip tie thickness (standard ties: 2 mm)
tie_t = 2; // [1:0.1:4]
// Clearance added to the tunnels on width and thickness
tie_clr = 0.5; // [0:0.1:2]

/* [DIN rail clip] */
// Bolt holes for the DIN rail clip in the back wall; the clip is a separate part (Print tab: part)
din_holes = false;
// Bolts joining holder and clip (hole, head and nut sizes follow)
din_bolt = "M4"; // [M3, M4, M5, M6]
// Height of the rail centreline on the holder (0 = automatic)
din_rail_z = 0; // [0:0.5:400]
// Clip width along the rail (0 = automatic)
din_clip_w = 0; // [0:1:100]

/* [Hidden] */
include <lib/uh_core.scad>
include <lib/uh_shapes.scad>
include <lib/uh_body.scad>
include <lib/uh_din.scad>
include <lib/uh_mount.scad>

$fa = uh_quality(quality)[0];
$fs = uh_quality(quality)[1];

// Test hooks (not shown in the Customizer):
//   cavity_probe      what intrudes into the item space - must be empty
//   din_fit           holder, clip and a TS35 rail in their mounted positions
//   din_interference  clip and rail overlap at rest - only the spring preload
//   din_pullout       overlap with the rail moved 1 mm off the plate - the teeth hold
debug_view = "none";

uh_body_checks();
uh_mount_checks();

if      (debug_view == "cavity_probe")     intersection() { uh_holder(); uh_item_space(); }
else if (debug_view == "din_fit")          { color("teal") uh_holder(); color("orange") uh_din_clip_in_use(); color("silver") uh_din_rail(); }
else if (debug_view == "din_interference") intersection() { uh_din_clip_in_use(); uh_din_rail(); }
else if (debug_view == "din_pullout")      intersection() { uh_din_clip_in_use(); uh_din_rail(1); }
else if (part == "din_clip")               uh_din_clip();
else if (part == "holder_and_clip")        { uh_holder(); uh_din_clip_beside(); }
else if (part == "din_preview")            { uh_holder(); color("orange") uh_din_clip_in_use(); %uh_din_rail(); }
else                                       uh_holder();

// Assembly order: shell − cavity, add mount features, then cut
// perforations, the front opening and the mount holes last.
module uh_holder() {
    difference() {
        union() {
            difference() {
                uh_outer_shell();
                uh_cavity();
            }
            uh_mount_external();   // wings and gussets
        }
        uh_perforations();         // hexagons, clear of mount keepouts
        uh_front_opening();
        uh_mount_cutters();        // back holes and wing holes
    }
}
