# UniHolder — work in progress

Parametric OpenSCAD holder for items, mountable on walls, poles and DIN rail. Prints standing, as generated, with no supports and no overhang beyond `max_overhang`. Plan: `docs/uniholder_design_plan.md`.

## Status

| Sub-task | Files | Verification (OpenSCAD 2021.01) |
|---|---|---|
| ST-4 ✓ pole mounts, flush screw heads | `uniholder.scad` v0.4, `lib/uh_mount.scad`, `lib/uh_body.scad`, `tests/st4_variants.json` | 6 pole variants pass at 60° and 45°; ST-3 re-verified with flush heads; item-space probe empty for every hole style, wings and pole mounts |
| ST-3 ✓ wall mounting | `uniholder.scad` v0.3, `lib/uh_mount.scad`, `tests/st3_variants.json`; preview fixes in `uh_shapes.scad` and `uh_body.scad`; checker fix | 8 mount variants (4 back-hole styles, keyholes with hex keepouts, wings bottom/top, Ø10 holes, short wings) pass at 60° and 45°; ST-1 and ST-2 regressions pass |
| ST-2 ✓ body | `uniholder.scad` v0.2, `lib/uh_body.scad`, `tools/render_matrix.py`, `tests/st2_variants.json` | 7 body variants (front modes, all-hex walls and floor, sharp and large radii, tiny, wide) pass at 60° and 45° |
| ST-1 ✓ core and primitives | `lib/uh_core.scad`, `lib/uh_shapes.scad`, `tests/test_shapes.scad`, `tests/test_checker_fail.scad`, `tools/check_overhang.py` | 8 test coupons pass at 60°, 45° and 40°; the negative test fails as intended |

## Using the holder

Open `uniholder.scad` in OpenSCAD and use the Customizer (Window → Customizer). Keep the folder structure: the main file includes `lib/`. Export the STL and print it as generated, standing, without supports.

Current tabs: Print, Size, Walls and edges, Wall styles, Hex pattern, Front opening, Back holes, Wings, Pole mount. The DIN rail clip and a single-file version follow in ST-5.

Nothing enters the item space: countersunk, counterbored and keyhole screw heads seat flush inside the back wall, which thickens automatically (in inner mode the holder grows backwards instead). Plain holes leave the screw head on the inner face.

The console lists `UH WARNING` lines when a setting was adjusted to fit (for example fewer holes, or a countersink that leaves less than 1.2 mm of wall) and `UH INFO` lines with the finished size.

## Checking a model

```
openscad -o sheet.stl -D max_overhang=60 tests/test_shapes.scad
python3 tools/check_overhang.py sheet.stl --max-overhang 60
```

Render and check a whole set of variants in one run:

```
python3 tools/render_matrix.py uniholder.scad tests/st4_variants.json --limits 60 45
```

Check that nothing protrudes into the item space (OpenSCAD must report an empty object):

```
openscad -o intrusion.stl -D 'debug_view="cavity_probe"' uniholder.scad
```

The checker (numpy only) reports downward facets steeper than the limit, floating lowest points and mesh defects; exit code 0 means pass. `tests/test_shapes.scad` is also a printable calibration sheet (232 × 101 × 44 mm).
