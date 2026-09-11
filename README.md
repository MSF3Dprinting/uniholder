# UniHolder v1.0

Parametric OpenSCAD holder for items of any size, mountable on walls, vertical or horizontal poles and TS35 DIN rails. Every part prints exactly as generated, standing, with no supports and no overhang beyond `max_overhang`; nothing protrudes into the item space. Made for MSF 3D Printing for All. Design plan: `docs/uniholder_design_plan.md` · test report: `docs/test_report.md`.

## Files

| Path | Content |
|---|---|
| `uniholder.scad` | Main file with all Customizer parameters (needs the `lib/` folder next to it) |
| `uniholder_customizer.scad` | The same model as one self-contained file, for online Customizers running OpenSCAD 2021.01 or newer; tested to give identical geometry |
| `lib/` | `uh_core` maths and screw table · `uh_shapes` printable primitives · `uh_body` shell, walls, hexagons, front opening · `uh_din` DIN rail clip · `uh_mount` back holes, wings, pole mounts |
| `tests/` | `test_shapes.scad` calibration sheet · `test_checker_fail.scad` deliberately unprintable part · variant lists `st2`–`st5` · `examples.json` |
| `tools/` | `run_all_tests.py` complete test suite · `check_overhang.py` STL printability check · `render_matrix.py` batch render · `build_single_file.py` rebuilds the Customizer file |
| `docs/` | Design plan, test report, preview images |

## Quick start

Open `uniholder.scad` or `uniholder_customizer.scad`, show the Customizer (Window → Customizer), set the parameters, render with F6 and export the STL. The console lists `UH INFO` lines (finished size, screws to use) and `UH WARNING` lines when a setting had to be adjusted to fit.

| Tab | Sets |
|---|---|
| Print | `part`: holder · din_clip · holder_and_clip (both on one bed) · din_preview (clip shown mounted, viewing only); overhang limit; quality |
| Size | Item size (inner) or holder size (outer), clearance |
| Walls and edges | Wall, back and floor thickness, corner radii, chamfers, floor cove |
| Wall styles · Hex pattern | Each wall and the floor solid or hexagon-perforated; hexagon size, strut, margins |
| Front opening | Open front with retaining lip and side edges, or a vertical slot |
| Back holes | Ø3–10 mm, plain / countersink / counterbore / keyhole, columns × rows, spacing |
| Wings | Left / right / both, length, thickness, height, on the bed or raised, holes, gusset |
| Pole mount | Vertical or horizontal pole, diameter, V angle, zip ties (count, size, clearance) |
| DIN rail clip | Clip bolt holes in the back wall, bolt size M3–M6, rail height, clip width |

## Printing

- Print exactly as generated and do not rotate the part: the orientation is part of the design. No supports.
- PETG (a light colour for clinical areas), 0.2 mm layers, 4 perimeters, 20–40 % infill (upper end for wings, pole blocks and the clip).
- `max_overhang` = 60 by default; use 45 on printers with weak part cooling — all geometry adapts.
- DIN clip: prints standing on its profile. Enable elephant-foot compensation (about 0.2 mm) so the spring gaps stay open at the first layer.

## Mounting

- **Back holes and wings:** screws matching the hole diameter (default 4.5 mm: M4 or 4 mm wood screws). Countersunk, counterbored and keyhole heads sit flush inside the back wall, which thickens automatically; plain holes leave the head on the inner face.
- **Poles:** standard 5 × 2 mm zip ties (tunnels are 5.5 × 2.5 mm with the default 0.5 mm clearance).
- **DIN rail:** the clip is a separate part. Set `din_holes = true` and choose `din_bolt` (M3–M6); export the holder with `part = holder` and the clip with `part = din_clip`, or both with `part = holder_and_clip`. `part = din_preview` shows the clip mounted on a rail for checking only. The console names the screws, e.g. *2 × M4 × 10 countersunk screws and 2 × M4 nuts*. Put the nuts into the clip's pockets and screw the holder to the clip from inside. Hook the clip over the top of the rail and press the bottom until the latch snaps. To remove, lever the release tab below the spring down with a flat screwdriver and tilt the holder off.

| din_bolt | Hole | Nut | Clip width (auto) | Clip plate | Countersunk screw with default walls |
|---|---|---|---|---|---|
| M3 | 3.4 mm | 5.5 mm AF | 36 mm | 5.0 mm | M3 × 8 |
| M4 | 4.5 mm | 7 mm AF | 36 mm | 5.0 mm | M4 × 10 |
| M5 | 5.5 mm | 8 mm AF | 36 mm | 6.3 mm | M5 × 12 |
| M6 | 6.6 mm | 10 mm AF | 39 mm | 6.8 mm | M6 × 12 |

## Examples

| Example | Parameters (everything else default) |
|---|---|
| Wall cup | defaults: inner 60 × 40 × 80 mm, open front with 20 mm lip, hexagon sides, 2 countersunk back holes |
| Hand-rub bottle on an IV pole | `size_x = 75`, `size_y = 75`, `size_z = 110`, `front_lip_h = 30`, `pole_mount = "vertical"`, `pole_d = 25` |
| DIN rail parts bin | `size_x = 80`, `size_y = 50`, `size_z = 70`, `front_lip_h = 20`, `din_holes = true`; then `part = "din_clip"` |

## Testing

```
python3 tools/run_all_tests.py            # all stages, about 7 minutes; writes docs/test_report.md
python3 tools/run_all_tests.py multi      # one stage: primitives | multi | single | compare | probes | report
```

The suite renders every variant from both `uniholder.scad` and the Customizer file at 60° and 45°, checks each STL for printability, compares the two versions STL by STL, confirms that nothing enters the item space, and fits the DIN clip on a TS35 rail model for every bolt size. Latest result (OpenSCAD 2021.01): primitives pass, 72 of 72 variants pass in each version, 72 of 72 STLs identical, 21 of 21 probes pass — details in `docs/test_report.md`.

For a single model: `python3 tools/check_overhang.py part.stl --max-overhang 60`. After editing `lib/`, rebuild the Customizer file with `python3 tools/build_single_file.py` and rerun the tests.

## Limits

- The DIN clip spring is sized for PETG and standard 1.0 mm TS35 rails (lips up to 1.5 mm); test the snap and release on your own rails before series printing.
- Hexagon hole edges are sharp; cut-out edges are chamfered rather than filleted.
- Features deferred to a later version are listed in the design plan backlog (§8).
