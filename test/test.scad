include <ink2scad_tools.scad>
include <generated.scad>

myshape = holed1;

/*
difference() {
    linear_extrude( height=3, convexity=10 ) ink2scad( myshape );
    translate( [0,0,3] ) extrude_along_edges( myshape ) {
        rotate(45) square( sqrt(2), center=true );
    }
}
*/

linear_extrude( height=3, convexity=10 ) ink2scad( myshape );
extrude_along_edges( myshape, convexity=10, rough=false ) {
   polygon( [ [-2,0],[0,3],[0,0] ]);
}


