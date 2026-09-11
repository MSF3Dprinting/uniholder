# UniHolder v1.0 — test report

Generated 2026-09-11 with OpenSCAD version 2021.01 by `tools/run_all_tests.py`. Every STL is checked by `tools/check_overhang.py` (downward facets steeper than the limit, floating lowest points, open or non-manifold edges).

| Stage | Result | Details |
|---|---|---|
| Primitives | PASS | calibration sheet at 60°, 45°, 40°; negative test rejected |
| Variants from `uniholder.scad` | PASS | 72 of 72 pass |
| Variants from `uniholder_customizer.scad` | PASS | 72 of 72 pass |
| Customizer file identical to multi-file | PASS | 72 of 72 STLs identical (facets, volume, bounding box) |
| Probes | PASS | 21 of 21 pass |

## Primitives

| Test | Expected | Result | Worst overhang | Note |
|---|---|---|---|---|
| tests/test_shapes.scad at 60 deg | PASS | PASS | 60.0° | core self-test passed |
| tests/test_shapes.scad at 45 deg | PASS | PASS | 45.02° | core self-test passed |
| tests/test_shapes.scad at 40 deg | PASS | PASS | 40.02° | core self-test passed |
| tests/test_checker_fail.scad (must be rejected) | FAIL | FAIL | 90.0° | 2 steep facets, 1 floating points |

## Variants

Worst overhang equal to the limit means surfaces sit exactly at the limit, never beyond it.

| Variant | Limit | Multi-file | Customizer file | Identical | Worst | Floating | Open / non-manifold | Size [mm] |
|---|---|---|---|---|---|---|---|---|
| st2.default | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| st2.default | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| st2.allhex | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| st2.allhex | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| st2.slot | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| st2.slot | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| st2.outer_sharp | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 50.0 x 30.0 x 40.0 |
| st2.outer_sharp | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 50.0 x 30.0 x 40.0 |
| st2.bigr_lip0 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 65.2 x 47.0 x 82.0 |
| st2.bigr_lip0 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 65.2 x 47.0 x 82.0 |
| st2.tiny | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 26.8 x 22.9 x 27.0 |
| st2.tiny | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 26.8 x 22.9 x 27.0 |
| st2.wide_low | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 186.8 x 67.8 x 37.0 |
| st2.wide_low | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 186.8 x 67.8 x 37.0 |
| st3.holes_default | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| st3.holes_default | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| st3.holes_plain_hex | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 47.6 x 82.0 |
| st3.holes_plain_hex | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 47.6 x 82.0 |
| st3.holes_cb_pitch | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 48.6 x 82.0 |
| st3.holes_cb_pitch | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 48.6 x 82.0 |
| st3.keyhole_hex | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 51.1 x 82.0 |
| st3.keyhole_hex | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 51.1 x 82.0 |
| st3.wings_both | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 106.8 x 47.6 x 82.0 |
| st3.wings_both | 45° | PASS | PASS | yes | 45.08° | 0 | 0/0 | 106.8 x 47.6 x 82.0 |
| st3.wing_raised_slot | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 96.8 x 47.9 x 82.0 |
| st3.wing_raised_slot | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 96.8 x 47.9 x 82.0 |
| st3.wing_d10_thick | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 106.8 x 47.9 x 82.0 |
| st3.wing_d10_thick | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 106.8 x 47.9 x 82.0 |
| st3.wing_short_many | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 90.8 x 47.9 x 82.0 |
| st3.wing_short_many | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 90.8 x 47.9 x 82.0 |
| st4.vpole_default | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 65.3 x 82.0 |
| st4.vpole_default | 45° | PASS | PASS | yes | 45.01° | 0 | 0/0 | 66.8 x 65.3 x 82.0 |
| st4.vpole_d60_v120 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 65.7 x 82.0 |
| st4.vpole_d60_v120 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 65.7 x 82.0 |
| st4.vpole_d12_wings | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 106.8 x 59.9 x 82.0 |
| st4.vpole_d12_wings | 45° | PASS | PASS | yes | 46.36° | 0 | 0/0 | 106.8 x 59.9 x 82.0 |
| st4.hpole_d32 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 67.8 x 82.0 |
| st4.hpole_d32 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 67.8 x 82.0 |
| st4.hpole_v60_hex | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 75.2 x 82.0 |
| st4.hpole_v60_hex | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 65.3 x 82.0 |
| st4.hpole_d60_low | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 78.2 x 62.0 |
| st4.hpole_d60_low | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 78.2 x 62.0 |
| st5.din_clip_m3 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 12.2 x 64.4 x 36.0 |
| st5.din_clip_m3 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 12.2 x 64.4 x 36.0 |
| st5.din_clip_m4 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 12.2 x 64.4 x 36.0 |
| st5.din_clip_m4 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 12.2 x 64.4 x 36.0 |
| st5.din_clip_m5 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 13.5 x 64.4 x 36.0 |
| st5.din_clip_m5 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 13.5 x 64.4 x 36.0 |
| st5.din_clip_m6 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 14.0 x 64.4 x 39.0 |
| st5.din_clip_m6 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 14.0 x 64.4 x 43.0 |
| st5.din_clip_w50 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 12.2 x 64.4 x 50.0 |
| st5.din_clip_w50 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 12.2 x 64.4 x 50.0 |
| st5.din_holes_m3 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 47.6 x 82.0 |
| st5.din_holes_m3 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 47.6 x 82.0 |
| st5.din_holes_m4 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 48.1 x 82.0 |
| st5.din_holes_m4 | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 48.1 x 82.0 |
| st5.din_holes_m6_cb_hex | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 52.0 x 82.0 |
| st5.din_holes_m6_cb_hex | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 52.0 x 82.0 |
| st5.din_holes_m5_keyhole | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 48.7 x 82.0 |
| st5.din_holes_m5_keyhole | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 48.7 x 82.0 |
| st5.holder_and_clip_m5 | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 110.3 x 64.4 x 82.0 |
| st5.holder_and_clip_m5 | 45° | PASS | PASS | yes | 45.07° | 0 | 0/0 | 110.3 x 64.4 x 82.0 |
| st5.vpole_tie_clr | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 65.3 x 82.0 |
| st5.vpole_tie_clr | 45° | PASS | PASS | yes | 45.01° | 0 | 0/0 | 66.8 x 65.3 x 82.0 |
| examples.ex1_wall_cup | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| examples.ex1_wall_cup | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 66.8 x 47.9 x 82.0 |
| examples.ex2_iv_pole_bottle | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 81.8 x 100.3 x 112.0 |
| examples.ex2_iv_pole_bottle | 45° | PASS | PASS | yes | 45.01° | 0 | 0/0 | 81.8 x 100.3 x 112.0 |
| examples.ex3_din_parts_bin | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 86.8 x 58.1 x 72.0 |
| examples.ex3_din_parts_bin | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 86.8 x 58.1 x 72.0 |
| examples.ex3_din_clip | 60° | PASS | PASS | yes | 60.00° | 0 | 0/0 | 12.2 x 64.4 x 36.0 |
| examples.ex3_din_clip | 45° | PASS | PASS | yes | 45.00° | 0 | 0/0 | 12.2 x 64.4 x 36.0 |

## Console warnings (intended adjustments)

- back holes reduced to 1 x 1 so the heads do not overlap — st2.tiny
- back wall thickened to 3.45 mm to seat the screw heads - inner depth is reduced — st2.outer_sharp
- back: no room for a whole hexagon, wall stays solid — st5.din_holes_m6_cb_hex
- keyholes cannot hold the DIN clip - countersunk holes are used — st5.din_holes_m5_keyhole
- left: no room for a whole hexagon, wall stays solid — st2.tiny
- pole_v_angle = 60 clamped to 90 — st4.hpole_v60_hex
- right: no room for a whole hexagon, wall stays solid — st2.tiny
- uh_screw_hole: countersink depth 5 leaves less than 1.2 mm of wall — st3.wing_d10_thick
- wing_hole_count reduced to 3 to fit the wing — st3.wing_short_many

## Probes

| Probe | Expected | Measured | Result |
|---|---|---|---|
| item space empty: countersink back holes | empty | empty | PASS |
| item space empty: counterbore back holes | empty | empty | PASS |
| item space empty: keyholes | empty | empty | PASS |
| item space empty: plain holes, hex back | empty | empty | PASS |
| item space empty: wings with 10 mm holes | empty | empty | PASS |
| item space empty: vertical pole | empty | empty | PASS |
| item space empty: horizontal pole | empty | empty | PASS |
| item space empty: DIN M6 counterbore | empty | empty | PASS |
| item space empty: DIN M3 countersink | empty | empty | PASS |
| item space empty: DIN M4 countersink | empty | empty | PASS |
| item space empty: DIN M5 countersink | empty | empty | PASS |
| item space empty: DIN M6 countersink | empty | empty | PASS |
| DIN M3 clip at rest on TS35 | preload | 18.0 mm3 (preload 18.0 mm3) | PASS |
| DIN M4 clip at rest on TS35 | preload | 18.0 mm3 (preload 18.0 mm3) | PASS |
| DIN M5 clip at rest on TS35 | preload | 18.0 mm3 (preload 18.0 mm3) | PASS |
| DIN M6 clip at rest on TS35 | preload | 19.5 mm3 (preload 19.5 mm3) | PASS |
| DIN M3 rail pulled 1 mm off the plate | holds | 107.82 mm3 (at least 3 x preload 18.0 mm3) | PASS |
| DIN M4 rail pulled 1 mm off the plate | holds | 107.82 mm3 (at least 3 x preload 18.0 mm3) | PASS |
| DIN M5 rail pulled 1 mm off the plate | holds | 107.82 mm3 (at least 3 x preload 18.0 mm3) | PASS |
| DIN M6 rail pulled 1 mm off the plate | holds | 116.805 mm3 (at least 3 x preload 19.5 mm3) | PASS |
| part = din_preview renders with warning | renders | 57118.589 mm3 | PASS |
