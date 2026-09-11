// =====================================================================
//  UniHolder — tests/test_checker_fail.scad                       ST-1
//  Deliberately UNPRINTABLE coupon. tools/check_overhang.py must FAIL on it:
//    A  rectangular hole with a flat ceiling          -> P2 (90° overhang)
//    B  arm with a 45° underside (fine) carrying a
//       downward-pointing cone (sides fine, apex floats) -> P3 only
// =====================================================================
$fa = 6; $fs = 0.4;

difference() {
    translate([-20, -3, 0]) cube([40, 6, 30]);
    translate([-10, 0, 12]) cube([10, 8, 6], center = true);        // A
}

// B: printable arm growing out of the +Y face with a 45° support slope
hull() {
    translate([6, 2.99, 20]) cube([8, 10, 4]);
    translate([6, 2.99, 10]) cube([8, 0.01, 14]);
}
// cone hanging below the arm tip: faces are ~11° from vertical, but the apex floats
translate([10, 11, 8]) cylinder(h = 12.5, r1 = 0, r2 = 2.5);
