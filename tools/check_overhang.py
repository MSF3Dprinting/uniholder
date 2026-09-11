#!/usr/bin/env python3
"""UniHolder - tools/check_overhang.py                               (ST-1)

Checks an STL exported from OpenSCAD against the printability contract of the
UniHolder design plan. The part is assumed to print exactly as exported (+Z up).

  P2  no downward-facing facet steeper than --max-overhang
      (degrees from vertical); facets lying on the bed are ignored
  P3  no floating local minimum: every lowest point of material above the
      bed must have material directly below it

Open and non-manifold edges are reported as well.
Exit code: 0 = pass, 1 = fail, 2 = error.

Usage:  python3 check_overhang.py part.stl --max-overhang 60
Requires numpy only.
"""
import argparse
import struct
import sys

import numpy as np


def load_stl(path):
    """Return an (n, 3, 3) array of triangle vertices from a binary or ASCII STL."""
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) >= 84:
        count = struct.unpack("<I", data[80:84])[0]
        if len(data) == 84 + 50 * count:
            rec = np.frombuffer(
                data,
                dtype=np.dtype([("n", "<f4", 3), ("v", "<f4", (3, 3)), ("a", "<u2")]),
                count=count,
                offset=84,
            )
            return rec["v"].astype(np.float64)
    vals = [line.split()[1:4] for line in data.decode("ascii", "replace").splitlines()
            if line.strip().startswith("vertex")]
    tri = np.array(vals, dtype=np.float64)
    if tri.size == 0 or len(tri) % 3:
        raise ValueError("not a valid STL file")
    return tri.reshape(-1, 3, 3)


def point_inside(point, tri):
    """Parity ray test (Moller-Trumbore) along a slightly skewed +X direction."""
    d = np.array([1.0, 0.0123457, 0.0071913])
    d /= np.linalg.norm(d)
    v0 = tri[:, 0]
    e1 = tri[:, 1] - v0
    e2 = tri[:, 2] - v0
    h = np.cross(d, e2)
    a = np.einsum("ij,ij->i", e1, h)
    ok = np.abs(a) > 1e-12
    inv = np.zeros_like(a)
    inv[ok] = 1.0 / a[ok]
    s = point - v0
    u = inv * np.einsum("ij,ij->i", s, h)
    q = np.cross(s, e1)
    v = inv * (q @ d)
    t = inv * np.einsum("ij,ij->i", e2, q)
    hit = ok & (u >= 0) & (u <= 1) & (v >= 0) & (u + v <= 1) & (t > 1e-9)
    return np.count_nonzero(hit) % 2 == 1


def check(tri, max_overhang, angle_tol=1.0, area_tol=0.05, bed_tol=0.01, probe=0.05):
    res = {}
    v0 = tri[:, 0]
    cr = np.cross(tri[:, 1] - v0, tri[:, 2] - v0)
    a2 = np.linalg.norm(cr, axis=1)
    valid = a2 > 2e-4          # facets under 0.0001 mm^2 have unreliable normals: angles only
    nrm = np.zeros_like(cr)
    nrm[valid] = cr[valid] / a2[valid, None]
    area = a2 / 2.0
    z = tri[:, :, 2]
    bed = z.min()
    res["facets"] = len(tri)
    res["bbox"] = (tri.reshape(-1, 3).min(axis=0), tri.reshape(-1, 3).max(axis=0))

    # ---- P2: overhang angle of downward-facing facets ----------------------
    on_bed = z.max(axis=1) <= bed + bed_tol
    overhang = np.degrees(np.arcsin(np.clip(-nrm[:, 2], 0.0, 1.0)))
    bad = valid & ~on_bed & (nrm[:, 2] < 0) & (overhang > max_overhang + angle_tol)
    res["worst_overhang"] = float(overhang[valid & ~on_bed].max()) if np.any(valid & ~on_bed) else 0.0
    res["p2_count"] = int(bad.sum())
    res["p2_area"] = float(area[bad].sum())
    order = np.argsort(-area[bad])[:10]
    res["p2_examples"] = [(tri[bad][i].mean(axis=0), overhang[bad][i], area[bad][i]) for i in order]

    # ---- mesh topology ------------------------------------------------------
    pts = tri.reshape(-1, 3)
    key = np.round(pts / 1e-4).astype(np.int64)
    _, idx, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
    inv = inv.reshape(-1)
    pos = pts[idx]
    faces = inv.reshape(-1, 3)
    good = (faces[:, 0] != faces[:, 1]) & (faces[:, 1] != faces[:, 2]) & (faces[:, 0] != faces[:, 2])  # topology: all
    fg = faces[good]
    edges = np.concatenate([fg[:, [0, 1]], fg[:, [1, 2]], fg[:, [2, 0]]])
    _, counts = np.unique(np.sort(edges, axis=1), axis=0, return_counts=True)
    res["open_edges"] = int(np.sum(counts == 1))
    res["nonmanifold_edges"] = int(np.sum(counts > 2))

    # ---- P3: floating local minima -----------------------------------------
    zmin_nb = np.full(len(pos), np.inf)
    np.minimum.at(zmin_nb, edges[:, 0], pos[edges[:, 1], 2])
    np.minimum.at(zmin_nb, edges[:, 1], pos[edges[:, 0], 2])
    touches_down = np.zeros(len(pos), dtype=bool)
    down = valid[good] & (nrm[good][:, 2] < -0.05)
    for k in range(3):
        touches_down[fg[down, k]] = True
    cand = np.where(touches_down & (pos[:, 2] <= zmin_nb + 1e-4) & (pos[:, 2] > bed + bed_tol))[0]
    tris = tri[valid]
    floating = []
    for vi in cand:
        p = pos[vi]
        supported = False
        for ang in (0.0, 90.0, 180.0, 270.0):
            r = np.radians(ang)
            q = p + np.array([probe * np.cos(r), probe * np.sin(r), -probe])
            if point_inside(q, tris):
                supported = True
                break
        if not supported:
            floating.append(p)
    res["p3_candidates"] = int(len(cand))
    res["p3_floating"] = floating
    res["pass"] = res["p2_area"] <= area_tol and not floating and res["open_edges"] == 0 \
        and res["nonmanifold_edges"] == 0
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stl")
    ap.add_argument("--max-overhang", type=float, default=60.0, help="degrees from vertical (default 60)")
    ap.add_argument("--angle-tol", type=float, default=1.0, help="tolerance in degrees (default 1)")
    ap.add_argument("--area-tol", type=float, default=0.05, help="allowed violating area in mm^2 (default 0.05)")
    ap.add_argument("--bed-tol", type=float, default=0.01, help="height treated as bed contact in mm")
    ap.add_argument("--probe", type=float, default=0.05, help="probe distance for P3 in mm")
    args = ap.parse_args()
    try:
        tri = load_stl(args.stl)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}")
        return 2
    r = check(tri, args.max_overhang, args.angle_tol, args.area_tol, args.bed_tol, args.probe)
    lo, hi = r["bbox"]
    print(f"file              {args.stl}")
    print(f"facets            {r['facets']}")
    print(f"size [mm]         {hi[0]-lo[0]:.1f} x {hi[1]-lo[1]:.1f} x {hi[2]-lo[2]:.1f}")
    print(f"limit             {args.max_overhang:.1f} deg from vertical (+{args.angle_tol} tol)")
    print(f"worst overhang    {r['worst_overhang']:.2f} deg (facets not on the bed)")
    print(f"P2 violations     {r['p2_count']} facets, {r['p2_area']:.4f} mm^2")
    for c, ang, ar in r["p2_examples"]:
        print(f"    at ({c[0]:.2f}, {c[1]:.2f}, {c[2]:.2f})  {ang:.1f} deg  {ar:.4f} mm^2")
    print(f"P3 floating minima {len(r['p3_floating'])} (of {r['p3_candidates']} local minima checked)")
    for p in r["p3_floating"][:10]:
        print(f"    at ({p[0]:.2f}, {p[1]:.2f}, {p[2]:.2f})")
    print(f"open / non-manifold edges  {r['open_edges']} / {r['nonmanifold_edges']}")
    print("RESULT            " + ("PASS" if r["pass"] else "FAIL"))
    return 0 if r["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
