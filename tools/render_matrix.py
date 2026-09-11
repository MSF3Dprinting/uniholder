#!/usr/bin/env python3
"""UniHolder - tools/render_matrix.py                                  (ST-2)

Renders parameter variants of a .scad file with OpenSCAD in parallel and runs
check_overhang on every STL, printing one summary table.

variants.json:  {"name": {"parameter": value, ...}, ...}
Each variant is rendered once per --limits value unless it sets max_overhang.

Usage: python3 tools/render_matrix.py uniholder.scad variants.json --limits 60 45
Exit code 0 when every variant renders and passes.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_overhang import check, load_stl  # noqa: E402


def scad_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        return json.dumps(v)
    return repr(v)


def run(job):
    name, params, scad, out = job
    stl = os.path.join(out, name + ".stl")
    if os.path.exists(stl):
        os.remove(stl)
    cmd = ["openscad", "-o", stl] + [a for k, v in params.items() for a in ("-D", f"{k}={scad_value(v)}")] + [scad]
    t0 = time.time()
    p = subprocess.run(cmd, capture_output=True, text=True)
    log = p.stdout + p.stderr
    with open(os.path.join(out, name + ".log"), "w") as fh:
        fh.write(log)
    res = {"name": name, "time": time.time() - t0, "ok": p.returncode == 0 and os.path.exists(stl),
           "warnings": sorted(set(re.findall(r'UH WARNING: ([^"]*)', log))),
           "errors": re.findall(r"(ERROR: .*)", log)[:2]}
    if res["ok"]:
        r = check(load_stl(stl), params.get("max_overhang", 60))
        lo, hi = r["bbox"]
        res.update(result="PASS" if r["pass"] else "FAIL", worst=r["worst_overhang"],
                   p2=r["p2_area"], floating=len(r["p3_floating"]),
                   edges=f'{r["open_edges"]}/{r["nonmanifold_edges"]}',
                   size=" x ".join(f"{hi[i] - lo[i]:.1f}" for i in range(3)))
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scad")
    ap.add_argument("variants")
    ap.add_argument("--limits", type=float, nargs="+", default=[60.0])
    ap.add_argument("--out", default="build")
    ap.add_argument("--jobs", type=int, default=6)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    jobs = []
    for name, params in json.load(open(a.variants)).items():
        if "max_overhang" in params:
            jobs.append((name, params, a.scad, a.out))
        else:
            for lim in a.limits:
                jobs.append((f"{name}_{lim:g}", dict(params, max_overhang=lim), a.scad, a.out))
    with ThreadPoolExecutor(a.jobs) as ex:
        results = list(ex.map(run, jobs))
    print(f"{'variant':<22}{'result':<8}{'worst':>7}{'P2 mm2':>8}{'float':>6}{'open/nm':>9}  {'size [mm]':<22}{'time':>6}")
    ok = True
    for r in results:
        if not r["ok"]:
            ok = False
            print(f"{r['name']:<22}RENDER FAILED  {r['errors']}")
            continue
        ok &= r["result"] == "PASS"
        print(f"{r['name']:<22}{r['result']:<8}{r['worst']:>7.2f}{r['p2']:>8.3f}{r['floating']:>6}{r['edges']:>9}  "
              f"{r['size']:<22}{r['time']:>5.0f}s")
    warned = {w: [r["name"] for r in results if w in r["warnings"]] for r in results for w in r["warnings"]}
    for w, names in warned.items():
        print(f"  warning: {w}  [{', '.join(names)}]")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
