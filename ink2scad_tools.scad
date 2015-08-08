// When set to true, extrude_along_edges will use a quick, and dirty approximation, which renders much quicker
// in openSCAD's preview mode. External mouldings, and internal chamfers will be rendered incorrectly, so
// don't forget to turn rough back off for the final render.
INK2SCAD_ROUGH = false;

// If set to false, then the nothing will be rendered by 'extrude_along_edges'.
// This is useful when designing a product, as 'extrude_along_edges' heavily uses 'intersection',
// and openSCAD's preview mode cannot render this quickly, especially when combined with 'difference'
// to make a chamfer.
INK2SCAD_EXTRUDE_ALONG_EDGES = true;

// An arbitrary largish number (must be larger than the lengths of the line segments).
INK2SCAD_LARGE = 10;
// An arbitrary small number. If the mitre lines are (nearly) parallel, then don't find the intersection point
INK2SCAD_SMALL = 0.05;
// A thin slice, just enough to make edges non-coincident, so that the preview mode renders nicely.
INK2SCAD_THIN = 0.01;

/*
  Returns an item from an array, but treating the array as a "barrel" array.
  e.g. if the array is size 4, then the following indicies all refer to the same element :
  1, 5, 9, 13... and also -3, -7, -11...
*/
function ink2scad_barrel( array, index ) = array[ index < 0 ? len(array) - (-index % len(array)) : index % len( array ) ];

function ink2scad_normalise( v ) = v / norm( v );

/*
  Extrude a 2D shape around the edges of shape, mitering each piece.
  The 'data' parameter is the data generated from the ink2scad inkscape extension.
  data[0] is a set of 'points', and data[1] is a set of 'paths'. See openSCAD's polygon module
  for details.

  This module's 'child' must be a 2D shape, which is extruded to form the moulding / chamfer.
  Anything left of x=0 will be on OUTSIDE the shape (useful for adding moldings), and
  anything right of x=0 will be INSIDE the shape (useful with 'difference' to cut away chamfers etc).

  Note. The winding of the points in data[0] is important.
  External edges should be ordered clockwise, and internal edges (holes) anti-clockwise.
*/
module extrude_along_edges( data, convexity = 4, render, rough )
{
    module extrude_along_edge( path, i )
    {
        // 'path' is the list of point indicies, and i is the start index into the path array.
        // When i = 0, then a is index 0, b is 1, c is 2 and d is 3.
        // This module extrudes a shape along the line segment bc, and it uses the points a and d
        // to calculate the angle of the mitre joint at each end of line segment bc.
        // Therefore when i = 0, we are rendering along line whose indicies are 1 and 2.
        // Use "barrel", so that indicies loop back round to the front of the array.
        a = data[0][ink2scad_barrel( path, i )];
        b = data[0][ink2scad_barrel( path, i+1 )];
        c = data[0][ink2scad_barrel( path, i+2 )];
        d = data[0][ink2scad_barrel( path, i+3 )];

        // Unit vector of cb
        unit_cb = ink2scad_normalise(b-c);

        // Create a trapezoid or triangle, which will act as a clipping region for the final extruded edge.
        module mitre()
        {
            // Unit vector of ab and cd.
            unit_ba = ink2scad_normalise(a-b);
            unit_dc = ink2scad_normalise(c-d);

            // The direction of the mitre from b
            mitre1 = INK2SCAD_LARGE * [ -unit_ba[1] - unit_cb[1], unit_ba[0] + unit_cb[0] ];
            // The direction of the mitre from c
            mitre2 = INK2SCAD_LARGE * [ -unit_dc[1] - unit_cb[1], unit_dc[0] + unit_cb[0] ];

            denom = (mitre1[0] * mitre2[1]) - (mitre1[1] * mitre2[0]);

            mitredb = b + mitre1;
            mitredc = c + mitre2;

            // Are the lines very nearly parallel (is the denominator roughly zero?)
            if ( ( denom < INK2SCAD_SMALL) && ( denom > -INK2SCAD_SMALL) ) {
                // Then don't find the intersection
                polygon( [ b + mitre1, c + mitre2, c - mitre2, b - mitre1 ] );

            } else {
                
                // Find the intersection of the lines if they are converging
                // Using the equation from wikipedia, where the lines are are bd and ce.
                // https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection            
                //demon = mitre1[0] * mitre2[1] - mitre1[1]*mitre2[1];
                //t1 = (x1*y2 - y1*x2)
                //t2 = (x3*y4 - y3*x4)
                //x = ( t1 * (x3-x4) - (x1-x2) * t2 ) / demon
                //y = t1 * (y3-y4) - (y1-y2) * t2 / demon
                t1 = b[0]*mitredb[1] - b[1]*mitredb[0];
                t2 = c[0]*mitredc[1] - c[1]*mitredc[0];
                
                // This is where the lines intersect
                x = ( t1 * (c[0]-mitredc[0]) - (b[0]-mitredb[0]) * t2 ) / denom;
                y = ( t1 * (c[1]-mitredc[1]) - (b[1]-mitredb[1]) * t2 ) / denom;

                // Are we an internal or external angle?
                if ( denom < 0 ) {
                    polygon( [ b - mitre1 + unit_cb * INK2SCAD_THIN, [x,y], c - mitre2 - unit_cb * INK2SCAD_THIN] );
                } else {
                    polygon( [ b + mitre1 + unit_cb * INK2SCAD_THIN, [x,y], c + mitre2 - unit_cb * INK2SCAD_THIN] );
                }
                // The "unit_cb * INK2SCAD_THIN" is a bodge, which splays the mitre joints out slightly.
                // Without this, there can be tiny slivers of material left at the corner of each chamfer.
    
            }

        }
        
        // Extra beyond each end of the line segment (will be cut off by the intersection with mitre())
        // If we are doing it rough, then don't have any extra (as we won't be cutting anything off!)
        extra = rough ? 0 : INK2SCAD_LARGE;

        // The length and angle of the line we are edging.
        l = norm( c-b );
        angle = atan2( -unit_cb[1], -unit_cb[0] );
        
        if (rough || ((rough == undef) && INK2SCAD_ROUGH) ) {
            translate( b )
            rotate( [0,0,angle] )
            rotate([90,0,0])
            rotate([0,90,0])
            linear_extrude( height = l, convexity=convexity ) children();
        } else {
            intersection() {
                // Extrude the 2D child shape along the line, extending further in both directions
                translate( b )            // Move the moulding to point b
                rotate( [0,0,angle] )     // Rotate the moulding to its final orientation
                rotate( [90,0,0] )        // Rotated the moulding, so that it is
                rotate( [0,90,0] )        //    pointing along the x axis
                translate( [0,0,-extra] ) // Place extra at both ends
                linear_extrude( height = l + 2 * extra, convexity=convexity ) children();

                // Crop the extrusion, so that it is mitered at both ends
                // The height of the extrusion is arbitrarily high above and below z=0 plane.
                translate( [0,0,-INK2SCAD_LARGE] ) linear_extrude( height = INK2SCAD_LARGE * 2  )
                    mitre();
            }
        }

    }

    if ( (render == true) || ((render==undef) && (INK2SCAD_EXTRUDE_ALONG_EDGES == true)) ) {

        for ( path = data[1] ) {
            for ( i = [0:len(path)-1] ) {
                extrude_along_edge( path, i ) children();
            }         
        }

    }
}

module ink2scad_at_points( data )
{
    for ( point = data[0] ) {
        translate( point ) children();
    }
}

module ink2scad_label_points( data, index, color=[0,1,0], size = 2 )
{
    from = index ? index : 0;
    to = index ? index : len(data[0])-1;

    color( color )
    for ( i = [from:to] ) {
        translate( data[0][i] )
        union() {
            circle( size / 8 );
            text( size=size, str( i ) );
        }
    }
}

/*
  Creates a 2D shape suitable as a molding (i.e. used as a child of extrude_along_edges.
  Generates the polygon as usual, and then translates it to the left of x=0, with just a tiny bit
  past x=0, so that there is no sliver of a gap between the molding and the object it goes around.

  Parameters
    data : Generated by ink2scad - the right edge should be vertical, and the left edge is the profile
           of your desired molding.
*/
module molding( data )
{
    translate( [0.01-data[2][0], 0] ) ink2scad( data );
}


