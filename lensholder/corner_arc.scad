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