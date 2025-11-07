/*
    A box to hold a raw lens.
    The lens can be pressed into it and then is held
    down by the little spheres.
*/

//> include_bottom symmetrical_press_fit_box.scad
//> include_bottom lensholder_clamps.scad

production_quality = false;

$fa = production_quality ?    1 :    4; // minimum angle of a fragment
$fs = production_quality ? 0.02 : 0.25; // minimum size of a fragment

/* Parameters in mm */
lens_diameter    = 60;
tolerance        = 0.5;   // Gap on each side so the lens easily fits
wall_thickness   = 1;     // Walls of the box
bottom_thickness = 1;     // Bottom of the box
box_height       = 7;
sphere_diameter  = 1;     // Size of the spheres
sphere_pos_z     = 4;     // Vertical position of the spheres
corner_radius    = 8;     // Radius for the rounded corners of the square box

/* Calculations */
diameter_with_tolerance = lens_diameter + 2*tolerance;
outer_side = diameter_with_tolerance + 2*wall_thickness;
inner_side = diameter_with_tolerance;
inner_corner_radius = corner_radius - wall_thickness;

lens_box();

// --------------------------------------------------
// Modules
// --------------------------------------------------

module lens_box() {
    the_box();
    color([0.3,0.9,0.3]) lensholder_clamps_tori();
}

module the_box() {
    symmetrical_press_fit_box(
        /* Parameters in mm */
        content_diameter = lens_diameter,
        tolerance        = tolerance,         // Gap on each side so the lens easily fits
        wall_thickness   = wall_thickness,    // Walls of the box
        bottom_thickness = bottom_thickness,  // Bottom of the box
        box_height       = box_height,
        corner_radius    = corner_radius,     // Radius for the rounded corners of the square box
    );
}
