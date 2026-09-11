#!/usr/bin/env python3
"""UniHolder - tools/run_all_tests.py                                   (v1.0)

Complete test suite; writes docs/test_report.md. Requires openscad and numpy.

Stages (results are cached in build/tests/, so they can also run one by one):
  primitives  calibration sheet at 60, 45 and 40 deg must pass; the deliberately
              unprintable negative test must be rejected
  multi       every tests/st*_variants.json and tests/examples.json variant at
              60 and 45 deg, rendered from uniholder.scad
  single      the same variants rendered from uniholder_customizer.scad
  compare     single-file and multi-file STLs must be identical
  probes      the item space stays empty; the DIN clip fits a TS35 rail for
              M3 to M6; part = din_preview renders
  report      writes docs/test_report.md from the cached results

Usage: python3 tools/run_all_tests.py [all | stage ...] [--jobs N]
Exit code 0 when every stage that ran passed.
"""
import argparse
import datetime
import glob
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from check_overhang import check, load_stl  # noqa: E402
from render_matrix import run as render_job  # noqa: E402

BUILD = os.path.join(ROOT, "build", "tests")
MAIN, SINGLE = "uniholder.scad", "uniholder_customizer.scad"
BOLTS = ["M3", "M4", "M5", "M6"]
PRELOAD_MM = 0.5 * 1.0           # latch preload 0.5 mm x 1 mm rail lip, per mm of clip width


def save(name, data):
    os.makedirs(BUILD, exist_ok=True)
    with open(os.path.join(BUILD, name + ".json"), "w") as fh:
        json.dump(data, fh, indent=1)


def load(name):
    path = os.path.join(BUILD, name + ".json")
    return json.load(open(path)) if os.path.exists(path) else None


def variants():
    files = sorted(glob.glob(os.path.join(ROOT, "tests", "st*_variants.json")))
    files.append(os.path.join(ROOT, "tests", "examples.json"))
    out = []
    for f in files:
        group = os.path.basename(f).replace("_variants.json", "").replace(".json", "")
        for name, params in json.load(open(f)).items():
            for lim in ([params["max_overhang"]] if "max_overhang" in params else [60, 45]):
                out.append((f"{group}.{name}_{lim:g}", dict(params, max_overhang=lim)))
    return out


def openscad(args, stl):
    if os.path.exists(stl):
        os.remove(stl)
    os.makedirs(os.path.dirname(stl), exist_ok=True)
    p = subprocess.run(["openscad", "-o", stl] + args, capture_output=True, text=True, cwd=ROOT)
    return p.stdout + p.stderr


def mesh_stats(path):
    t = load_stl(path)
    vol = abs(float(np.einsum("ij,ij->i", t[:, 0], np.cross(t[:, 1], t[:, 2])).sum()) / 6)
    pts = t.reshape(-1, 3)
    return {"facets": int(len(t)), "volume": round(vol, 3),
            "bbox": [round(float(x), 3) for x in list(pts.min(0)) + list(pts.max(0))]}


def scad_args(params):
    out = []
    for k, v in params.items():
        val = ("true" if v else "false") if isinstance(v, bool) else json.dumps(v) if isinstance(v, str) else repr(v)
        out += ["-D", f"{k}={val}"]
    return out


# ---- stages ---------------------------------------------------------------------

def stage_primitives(jobs):
    res = []
    for lim in (60, 45, 40):
        stl = os.path.join(BUILD, "primitives", f"test_shapes_{lim}.stl")
        log = openscad(["-D", f"max_overhang={lim}", "tests/test_shapes.scad"], stl)
        r = check(load_stl(stl), lim) if os.path.exists(stl) else None
        res.append({"name": f"tests/test_shapes.scad at {lim} deg", "expect": "PASS",
                    "got": "PASS" if r and r["pass"] else "FAIL", "worst": r and round(r["worst_overhang"], 2),
                    "note": "core self-test passed" if "self-test passed" in log else "self-test missing"})
    stl = os.path.join(BUILD, "primitives", "test_checker_fail.stl")
    openscad(["tests/test_checker_fail.scad"], stl)
    r = check(load_stl(stl), 60)
    res.append({"name": "tests/test_checker_fail.scad (must be rejected)", "expect": "FAIL",
                "got": "PASS" if r["pass"] else "FAIL", "worst": round(r["worst_overhang"], 2),
                "note": f"{r['p2_count']} steep facets, {len(r['p3_floating'])} floating points"})
    for x in res:
        x["ok"] = x["got"] == x["expect"] and "missing" not in x["note"]
    save("primitives", res)
    return all(x["ok"] for x in res)


def stage_matrix(tag, scad, jobs):
    outdir = os.path.join(BUILD, tag)
    os.makedirs(outdir, exist_ok=True)
    with ThreadPoolExecutor(jobs) as ex:
        results = list(ex.map(render_job, [(n, p, scad, outdir) for n, p in variants()]))
    for r in results:
        if r["ok"]:
            r.update(mesh_stats(os.path.join(outdir, r["name"] + ".stl")))
        r["pass"] = bool(r["ok"] and r.get("result") == "PASS")
    save(tag, results)
    return all(r["pass"] for r in results)


def stage_compare(jobs):
    multi, single = load("multi"), load("single")
    if not multi or not single:
        print("compare: run the multi and single stages first")
        return False
    by_name = {r["name"]: r for r in single}
    res = []
    for r in multi:
        o = by_name.get(r["name"])
        same = bool(o and r["ok"] and o["ok"] and all(r[k] == o[k] for k in ("facets", "volume", "bbox")))
        res.append({"name": r["name"], "identical": same})
    save("compare", res)
    return len(res) == len(single) and all(x["identical"] for x in res)


def probe_list():
    cav = [("countersink back holes", {}), ("counterbore back holes", {"back_hole_style": "counterbore"}),
           ("keyholes", {"back_hole_style": "keyhole"}), ("plain holes, hex back", {"back_hole_style": "plain", "back_style": "hex"}),
           ("wings with 10 mm holes", {"wings": "both", "wing_hole_d": 10, "wing_len": 40, "wing_t": 6}),
           ("vertical pole", {"pole_mount": "vertical"}), ("horizontal pole", {"pole_mount": "horizontal"}),
           ("DIN M6 counterbore", {"din_holes": True, "din_bolt": "M6", "back_hole_style": "counterbore"})]
    cav += [(f"DIN {b} countersink", {"din_holes": True, "din_bolt": b}) for b in BOLTS]
    out = [(f"item space empty: {n}", dict(p, debug_view="cavity_probe"), "empty") for n, p in cav]
    out += [(f"DIN {b} clip at rest on TS35", {"debug_view": "din_interference", "din_holes": True, "din_bolt": b}, "preload") for b in BOLTS]
    out += [(f"DIN {b} rail pulled 1 mm off the plate", {"debug_view": "din_pullout", "din_holes": True, "din_bolt": b}, "holds") for b in BOLTS]
    out += [("part = din_preview renders with warning", {"part": "din_preview", "din_holes": True}, "renders")]
    return out


def run_probe(item):
    label, params, expect = item
    stl = os.path.join(BUILD, "probes", label.replace(" ", "_").replace(":", "").replace("=", "") + ".stl")
    log = openscad(scad_args(params) + [MAIN], stl)
    exists = os.path.exists(stl)
    vol = mesh_stats(stl)["volume"] if exists else 0.0
    evaluated = "UH INFO: outer" in log and "Assertion" not in log
    m = re.search(r"clip width ([0-9.]+) mm", log)
    preload = PRELOAD_MM * float(m.group(1)) if m else float("nan")   # the clip width is read from the console
    if expect == "empty":
        ok, measured = evaluated and not exists, "empty" if not exists else f"{vol} mm3"
    elif expect == "preload":
        ok, measured = exists and abs(vol - preload) <= 0.5, f"{vol} mm3 (preload {preload} mm3)"
    elif expect == "holds":
        ok, measured = exists and vol >= 3 * preload, f"{vol} mm3 (at least 3 x preload {preload} mm3)"
    else:
        ok, measured = exists and vol > 0 and "din_preview" in log, f"{vol} mm3"
    return {"name": label, "expect": expect, "measured": measured, "ok": bool(ok)}


def stage_probes(jobs):
    with ThreadPoolExecutor(jobs) as ex:
        res = list(ex.map(run_probe, probe_list()))
    save("probes", res)
    return all(r["ok"] for r in res)


def stage_report(jobs):
    prim, multi, single, comp, probes = (load(n) for n in ("primitives", "multi", "single", "compare", "probes"))
    if not all([prim, multi, single, comp, probes]):
        print("report: run all other stages first")
        return False
    version = subprocess.run(["openscad", "--version"], capture_output=True, text=True).stderr.strip()
    comp_by = {c["name"]: c["identical"] for c in comp}
    single_by = {r["name"]: r for r in single}
    ok = {"primitives": all(x["ok"] for x in prim), "multi": all(r["pass"] for r in multi),
          "single": all(r["pass"] for r in single), "compare": all(comp_by.values()), "probes": all(p["ok"] for p in probes)}
    L = ["# UniHolder v1.0 — test report", "",
         f"Generated {datetime.date.today().isoformat()} with {version} by `tools/run_all_tests.py`. "
         "Every STL is checked by `tools/check_overhang.py` (downward facets steeper than the limit, "
         "floating lowest points, open or non-manifold edges).", "",
         "| Stage | Result | Details |", "|---|---|---|",
         f"| Primitives | {'PASS' if ok['primitives'] else 'FAIL'} | calibration sheet at 60°, 45°, 40°; negative test rejected |",
         f"| Variants from `uniholder.scad` | {'PASS' if ok['multi'] else 'FAIL'} | {sum(r['pass'] for r in multi)} of {len(multi)} pass |",
         f"| Variants from `uniholder_customizer.scad` | {'PASS' if ok['single'] else 'FAIL'} | {sum(r['pass'] for r in single)} of {len(single)} pass |",
         f"| Customizer file identical to multi-file | {'PASS' if ok['compare'] else 'FAIL'} | {sum(comp_by.values())} of {len(comp_by)} STLs identical (facets, volume, bounding box) |",
         f"| Probes | {'PASS' if ok['probes'] else 'FAIL'} | {sum(p['ok'] for p in probes)} of {len(probes)} pass |", "",
         "## Primitives", "", "| Test | Expected | Result | Worst overhang | Note |", "|---|---|---|---|---|"]
    L += [f"| {x['name']} | {x['expect']} | {x['got']} | {x['worst']}° | {x['note']} |" for x in prim]
    L += ["", "## Variants", "", "Worst overhang equal to the limit means surfaces sit exactly at the limit, never beyond it.", "",
          "| Variant | Limit | Multi-file | Customizer file | Identical | Worst | Floating | Open / non-manifold | Size [mm] |",
          "|---|---|---|---|---|---|---|---|---|"]
    for r in multi:
        s = single_by.get(r["name"], {})
        L.append(f"| {r['name'].rsplit('_', 1)[0]} | {r['name'].rsplit('_', 1)[1]}° | {r.get('result', 'RENDER FAILED')} | "
                 f"{s.get('result', 'RENDER FAILED')} | {'yes' if comp_by.get(r['name']) else 'NO'} | {r.get('worst', 0):.2f}° | "
                 f"{r.get('floating', '-')} | {r.get('edges', '-')} | {r.get('size', '-')} |")
    warns = {}
    for r in multi:
        for w in r.get("warnings", []):
            warns.setdefault(w, []).append(r["name"])
    L += ["", "## Console warnings (intended adjustments)", ""]
    L += [f"- {w} — {', '.join(sorted(set(n.rsplit('_', 1)[0] for n in names)))}" for w, names in sorted(warns.items())] or ["- none"]
    L += ["", "## Probes", "", "| Probe | Expected | Measured | Result |", "|---|---|---|---|"]
    L += [f"| {p['name']} | {p['expect']} | {p['measured']} | {'PASS' if p['ok'] else 'FAIL'} |" for p in probes]
    with open(os.path.join(ROOT, "docs", "test_report.md"), "w") as fh:
        fh.write("\n".join(L) + "\n")
    return all(ok.values())


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stages", nargs="*", default=["all"])
    ap.add_argument("--jobs", type=int, default=6)
    a = ap.parse_args()
    os.chdir(ROOT)
    order = ["primitives", "multi", "single", "compare", "probes", "report"]
    stages = order if "all" in a.stages else a.stages
    funcs = {"primitives": stage_primitives, "multi": lambda j: stage_matrix("multi", MAIN, j),
             "single": lambda j: stage_matrix("single", SINGLE, j), "compare": stage_compare,
             "probes": stage_probes, "report": stage_report}
    all_ok = True
    for st in stages:
        t0 = time.time()
        result = funcs[st](a.jobs)
        all_ok &= bool(result)
        print(f"{st:<11} {'PASS' if result else 'FAIL'}  ({time.time() - t0:.0f} s)", flush=True)
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
