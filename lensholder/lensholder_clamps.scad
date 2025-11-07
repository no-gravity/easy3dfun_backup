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