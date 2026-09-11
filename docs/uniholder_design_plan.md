# UniHolder — Parametric Universal Holder for OpenSCAD

**Design plan v2.1 (lean) · September 2026** · status: all sub-tasks complete (UniHolder v1.0) — v2.1 adds rule M1 (flush screw heads) after the ST-3 review

v2.0 cuts the v1.1 scope to the core requirements and sizes every remaining sub-task to fit one working session. Nothing is lost: cut features are listed in the backlog (§8).

## 1. Goal

One OpenSCAD file that generates open-top holders for arbitrary items, mountable on walls, vertical or horizontal poles, and DIN rails. Parts print standing, exactly as generated, without supports, and no downward-facing surface exceeds `max_overhang` (60° from vertical by default).

## 2. Scope

| Area | Included |
|---|---|
| Body | Inner or outer size; filleted vertical edges (front and back radius); chamfered top and bed edges; floor cove |
| Walls | Back, left, right, front and floor each solid or hexagon-perforated |
| Front | Solid, hex, **open** (cut down to a retaining lip, side edges kept) or **slot** |
| Wall mounting | Back holes Ø3–10 mm: plain, countersink, counterbore or keyhole, in columns × rows; heads seat flush and the back wall thickens automatically. Wings none / left / right / both: length, height, thickness, holes Ø3–10 mm (count; plain, countersink or slot), gusset |
| Pole mounting | Vertical pole: V-cradle with horizontal zip-tie tunnels. Horizontal pole: V-cradle with vertical zip-tie tunnels |
| DIN rail | Separate TS35 clip with a spring latch, printed on its side, bolted with 2 × M3–M6 bolts through the holder's DIN hole pattern |
| Delivery | Single-file Customizer version; README with print settings and three example configurations |

## 3. Printability rules (unchanged from v1.1)

β = 90° − max_overhang (roof angle above horizontal).

| Rule | Statement |
|---|---|
| P1 | Print as used: Z up, floor on the bed |
| P2 | Downward-facing surfaces ≤ max_overhang from vertical |
| P3 | No floating lowest points: nothing on the holder points downward (hooks and DIN jaws are separate parts) |
| P4 | Horizontal holes are teardrops |
| P5 | Horizontal channels have peaked roofs |
| P6 | Overhanging features get support slopes rising at β |
| P7 | Pointy-top hexagons, whole cells only |
| P8 | Walls and struts ≥ 1.2 mm |
| P9 | Bed edges chamfered 45°, steeper when max_overhang < 45° |
| E1 | Vertical edges filleted |
| E2 | Top edges chamfered |
| E3 | Raised bottom edges sloped at β |
| E4 | Round a corner only where the outline turns upward from a slope |
| M1 | Nothing enters the item space: screw heads seat flush inside the back wall, which thickens as needed (inner mode keeps the item size) |
| — | No text or embossing (cleanability) |

## 4. Conventions

y = 0 is the mounting plane (outer back face); the body extends to −Y and mounts sit at +Y. x = 0 is the centreline; z = 0 is the bed. `0` means auto. `uniholder.scad` holds the parameters and the assembly and includes `lib/uh_core.scad` → `uh_shapes.scad` → `uh_body.scad` → `uh_mount.scad` → `uh_din.scad`. Mount features publish keepout rectangles, so hexagons never cut into mounting zones.

## 5. Customizer parameters (added with their sub-task)

| Tab | Parameters (default) | ST |
|---|---|---|
| Print | max_overhang (60), quality (normal) | 2 |
| Size | size_mode (inner), size_x / size_y / size_z (60 / 40 / 80), item_clr (1) | 2 |
| Walls and edges | wall_t (2.4), back_t (3.2), floor_t (2), corner_r (6), back_corner_r (1.5), chamfer_top (1), chamfer_bottom (0.6), floor_cove (2) | 2 |
| Wall styles | back / left / right / floor_style (solid / hex / hex / solid), front_style (open) | 2 |
| Hex pattern | hex_size (8), hex_strut (2), hex_margin (3), hex_top_band (6), hex_bottom_band (4) | 2 |
| Front opening | front_lip_h (20), front_side_lip_w (8), front_open_r (5), front_slot_w (12), front_slot_z (15) | 2 |
| Back holes | back_holes (true), back_hole_d (4.5), back_hole_style (countersink), back_hole_head_d (0 = 2·d), back_hole_cols (1), back_hole_rows (2), back_hole_pitch_x / z (0 = auto) | 3 |
| Wings | wings (none), wing_len (20), wing_t (4), wing_h (0 = body), wing_align (bottom / top), wing_hole_d (4.5), wing_hole_style (countersink), wing_hole_count (2), wing_gusset (true) | 3 |
| Pole mount | pole_mount (none / vertical / horizontal), pole_d (25), pole_v_angle (90), tie_count (2), tie_w (5), tie_t (2) | 4 |
| DIN clip | part (holder / din_clip / holder_and_clip / din_preview), din_holes (false), din_bolt (M4; M3–M6), din_rail_z (0 = auto), din_clip_w (0 = auto) | 5 |

## 6. Sub-tasks

| ST | Deliverables | Done when |
|---|---|---|
| ST-0 ✓ | Design plan | — |
| ST-1 ✓ | `uh_core.scad`, `uh_shapes.scad`, test sheet, `check_overhang.py` | 8 coupons pass at 60°, 45° and 40° |
| ST-2 ✓ | `uniholder.scad` v0.2, `uh_body.scad`, `render_matrix.py` | Body variants (front modes, hex walls and floor, edge cases) render and pass at 60° and 45° |
| ST-3 ✓ | `uh_mount.scad`: back holes, wings, keepouts | Hole styles and wing variants pass at 60° and 45° |
| ST-4 ✓ | `uh_mount.scad`: vertical and horizontal pole saddles | Pole Ø12–60 mm and tie variants pass at 60° and 45° |
| ST-5 ✓ | `uh_din.scad`, `uniholder_customizer.scad`, README | Clip passes in its print orientation; single file renders the same as the multi-file version |

## 7. Working method per sub-task

1. Write the files.
2. Render a small variant matrix at 60° and 45° in one run (`tools/render_matrix.py`), checking every STL.
3. At most three fix rounds; anything larger moves to the next sub-task.
4. One preview image, then a cumulative zip.

## 8. Backlog (v2)

Slide-in removable front panel, arch window, top hanging tabs, strap slots, magnet pockets, tape recess, dividers, retention lip, clinical-mode switch, slide rail, UMS V1 counterpart (needs reference STEP/STL), HomeRacker pins, French cleat, pegboard / SKÅDIS, edge hook, bolted pole clamp, Customizer JSON presets.
