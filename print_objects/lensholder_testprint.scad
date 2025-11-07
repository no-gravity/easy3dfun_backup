/*
    A box to hold a raw lens.
    The lens can be pressed into it and then is held
    down by the little spheres.
*/

//> include_bottom symmetrical_press_fit_box.scad
//> include_bottom lensholder_clamps.scad

production_quality = true;

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

intersection() {
  lens_box();
  cube([90,20,90], center=true);
}

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


//> // ----------
//> // symmetrical_press_fit_box.scad
//> // ----------

/*
    Two of these objects make a closable box.
*/

//> include_bottom corner_arc.scad

module symmetrical_press_fit_box(
  /* Parameters in mm */
  content_diameter = 60,
  tolerance        = 0.5,   // Gap on each side so the content easily fits
  wall_thickness   = 1,     // Walls of the box
  bottom_thickness = 1,     // Bottom of the box
  box_height       = 7,
  corner_radius    = 8,     // Radius for the rounded corners of the square box
) {

  /* Calculations */
  diameter_with_tolerance = content_diameter + 2*tolerance;
  outer_side = diameter_with_tolerance + 2*wall_thickness;
  inner_side = diameter_with_tolerance;
  inner_corner_radius = corner_radius - wall_thickness;

  color([0.6,0.6,0.6]) the_box();
  color([0.2,0.4,0.9]) the_corners();

  // --------------------------------------------------
  // Modules
  // --------------------------------------------------

  module the_box() {
      difference() {
          outer_box();
          storage_space();
      }
  }

 module the_corners() {
    corner_length = 30;
    x_offset = inner_corner_radius * (1 - PI/4);
    for(i=[0:1]) {
      rotate([0, 0, i*180])
      translate([inner_side/2-corner_length/2-x_offset, -inner_side/2, 0])
      corner_arc(
        length       = corner_length,
        height       = 11,
        thickness    = 1,
        rad          = corner_radius - wall_thickness,
        shape_factor = 0,
        arc_width    = 10,
      );
    }
  }
  
  module outer_box() {
          // Outer box (square with rounded corners)
          linear_extrude(height=box_height) {
              minkowski() {
                  square(outer_side - 2*corner_radius, center=true);
                  circle(r=corner_radius);
              }
          }
  }

  module storage_space() {
          // Inner cavity for the content
          translate([0,0,bottom_thickness])
          linear_extrude(height=box_height) {
              minkowski() {
                  square(inner_side - 2*inner_corner_radius, center=true);
                  circle(r=inner_corner_radius);
              }
          }
  }

}

//> // ----------
//> // corner_arc.scad
//> // ----------

module corner_arc(
    length=100,
    height=20,
    thickness=2,
    steps_x=80,
    steps_y=3,
    shape_factor=0.5,
    arc_width=1,
    rad=1,
) {
    nr_points = steps_x * steps_y * 2; // front and back faces

    function generate_point(i) =
        (i < steps_x * steps_y) ?
            // Front face point
            [
                (i % steps_x) * length / (steps_x - 1),
                0,
                floor(i / steps_x) * height / (steps_y - 1)
            ]
        :
            // Back face point
            [
                ((i - steps_x * steps_y) % steps_x) * length / (steps_x - 1),
                thickness,
                floor((i - steps_x * steps_y) / steps_x) * height / (steps_y - 1)
            ];

    // Lower the height of the left and right ends of the wall
    function transform_1(p, shape_factor=shape_factor, arc_width=arc_width) =
        let(
            L = length,
            h = height,
            u = p.x / L, // normalized length [0..1]
            profile_parab = abs(pow(4, arc_width) * pow(u - 0.5, arc_width*2)),
            sigma = L / 4,
            profile_gauss = 1 - exp(-pow((p.x - L/2) / sigma, 2)),
            blended_profile = (1 - shape_factor) * profile_parab + shape_factor * profile_gauss,
            amp = 1 * h,
            dz = amp * blended_profile * (p.z / h),
        )
        [p.x, p.y, p.z - dz];

    // Bend the wall to become an edge
    function transform_2(p, rad=2) =
        let(
            L = length,
            t = thickness,
            s = p.x,
            o = p.y,
            // Scale the radius with roundness
            r = rad,
            arc = 1.5707963267948966 * rad,
            pre = (L - arc) / 2,
        )
        s < pre
        ? [ s, o, p.z ]
        : s < (pre + arc)
        ? let(
            s2 = s - pre,
            a = 90 * (s2 / arc)
          )
          [ pre + (r - o) * sin(a), r - (r - o) * cos(a), p.z ]
        : let(
            s3 = s - (pre + arc)
          )
          [ pre + r - o, r + s3, p.z ];

    function generate_points() = [
        for (i = [0 : nr_points - 1])
            transform_2(transform_1(generate_point(i)), rad)
    ];

    function generate_faces() = [
        // Front face triangles
        for (i = [0 : steps_y - 2]) for (j = [0 : steps_x - 2]) each [[i * steps_x + j, i * steps_x + j + 1, (i + 1) * steps_x + j], [i * steps_x + j + 1, (i + 1) * steps_x + j + 1, (i + 1) * steps_x + j]],
        // Back face triangles (reversed winding)
        for (i = [0 : steps_y - 2]) for (j = [0 : steps_x - 2]) each [[steps_x * steps_y + i * steps_x + j, steps_x * steps_y + (i + 1) * steps_x + j, steps_x * steps_y + i * steps_x + j + 1], [steps_x * steps_y + i * steps_x + j + 1, steps_x * steps_y + (i + 1) * steps_x + j, steps_x * steps_y + (i + 1) * steps_x + j + 1]],
        // Side faces - left edge
        for (i = [0 : steps_y - 2]) each [[i * steps_x, (i + 1) * steps_x, steps_x * steps_y + (i + 1) * steps_x], [i * steps_x, steps_x * steps_y + (i + 1) * steps_x, steps_x * steps_y + i * steps_x]],
        // Side faces - right edge
        for (i = [0 : steps_y - 2]) each [[i * steps_x + steps_x - 1, steps_x * steps_y + i * steps_x + steps_x - 1, (i + 1) * steps_x + steps_x - 1], [steps_x * steps_y + i * steps_x + steps_x - 1, steps_x * steps_y + (i + 1) * steps_x + steps_x - 1, (i + 1) * steps_x + steps_x - 1]],
        // Top edge
        for (j = [0 : steps_x - 2]) each [[(steps_y - 1) * steps_x + j, (steps_y - 1) * steps_x + j + 1, steps_x * steps_y + (steps_y - 1) * steps_x + j + 1], [(steps_y - 1) * steps_x + j, steps_x * steps_y + (steps_y - 1) * steps_x + j + 1, steps_x * steps_y + (steps_y - 1) * steps_x + j]],
        // Bottom edge
        for (j = [0 : steps_x - 2]) each [[j, steps_x * steps_y + j, j + 1], [steps_x * steps_y + j, steps_x * steps_y + j + 1, j + 1]]
    ];

    polyhedron(
        points = generate_points(),
        faces = generate_faces()
    );
}



//> // ----------
//> // lensholder_clamps.scad
//> // ----------

module lensholder_clamps_spheres() {
    for (i = [0:3]) {
        angle = i*90;
        x = (diameter_with_tolerance/2) * cos(angle);
        y = (diameter_with_tolerance/2) * sin(angle);
        translate([x, y, sphere_pos_z])
                sphere(r=sphere_diameter);
    }
}

module lensholder_clamps_tori() {
  torus_thickness = 0.33;
  torus_radius = 0.75;
  bound = diameter_with_tolerance+wall_thickness;
  module tori() {
    for (i = [-1,0,1,44,45,46,89,90,91,134,135,136]) {
        angle = i*10;
        x = (diameter_with_tolerance/2+0.2) * cos(angle);
        y = (diameter_with_tolerance/2+0.2) * sin(angle);
        translate([x, y, sphere_pos_z])
            rotate([90,0,i*10])
            rotate_extrude(convexity = 10)
                translate([torus_radius, 0, 0])
                circle(r = torus_thickness);
    }
  }
  intersection() {
    tori();
    translate([-bound/2,-bound/2,0]) cube([bound,bound,10]);
  }
}
