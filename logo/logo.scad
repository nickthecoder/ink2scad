include <ink2scad_tools.scad>
include <gen_logo.scad>

include <generated.scad>

color( [0.8,0,0] ) {
    extrude_along_edges( two, convexity=6, rough=false ) { scale( 1/5 ) molding( edge ); }
    linear_extrude( 2.5, convexity=6 ) ink2scad( scad, relativeTo=two );
    linear_extrude(0.01) ink2scad( ink, relativeTo=two );
}

linear_extrude( 2, convexity=10) ink2scad( two );


