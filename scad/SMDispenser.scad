// SMDispenser.scad
// SMD component dispenser
// CC-BY-SA
// Brian K. White - b.kenyon.w@gmail.com 2025

//PRINT = "base";
PRINT = "caddy";
//PRINT = "cap"; // end cap, only needed if spool_retainer_walls=false
preview_fully_populated = true;

// MAIN USER OPTIONS

// CADDY SIZE
// Fitment clearances are already added to the given strip dimensions
// so you can just use the actual strip dimensions like 8mm x 1mm
// for most common paper 0805 etc.

// some sample strip dimensions
// 33x3   48TSOP 28TSOP-II
// 32x4   32SOP
// 25x4   28SOIC
// 25x3   44VQFP 28TSOP-I
// 16x3   14SO 14SOIC 16SO 16SOIC
// 16x2   24TSSOP
// 13x3   8SOIC
// 12x2   14TSSOP 16TSSOP
// 8x2    SC70, large capacity 0805 caps
// 8x1    1206 0805 0604 paper

//strip_width = 8;
//strip_thickness = 1;
//spool_diameter = 60;

//strip_width = 12;
//strip_thickness = 2;
//spool_diameter = 60;

strip_width = 16;
strip_thickness = 3;
spool_diameter = 120;

//strip_width = 25;
//strip_thickness = 4;
//spool_diameter = 120;

//strip_width = 33;
//strip_thickness = 4;
//spool_diameter = 120;

// Do you want little walls to contain the spool?
// Set false if you can't print the bridges well enough.
// With the walls, each caddy holds it's spool in by itself.
// Without the walls, the spools are only trapped by the next caddy in line,
// and you can print the end cap to cover the left-most caddy.
// Set preview_fully_populated=true to see it.
spool_retainer_walls = true;


///////////////////////////////////////////////////////////////////////////////////
// CUSTOMIZATION

// height of partial walls to trap the spool
spool_traps_depth = strip_thickness*6;

slot_fc = 0.5; // fitment clearance just for the dispenser slot
fc = 0.2; // fitment clearance for everything else

// Base
base_length = 120;
//base_tilt_angle = 0;
base_tilt_angle = 15;
base_tilt_center = true;  // preserve center of gravity

// End Cap
// thin solid blank caddy shape used as end cap when trap=0
cap_thickness = 4;

///////////////////////////////////////////////////////////////////////////////////

wall_thickness = 1;
corner_radius = 2;

rail_width = spool_diameter/15;

top_hook_thickness = rail_width;

clip_thickness =
  spool_diameter<50 ? 1 :
  spool_diameter>100 ? 3 :
  2;

detent_height = clip_thickness/2 + fc*2;

// TODO smarter 2-part base design with seperate plinth and rail parts
// so that high angles don't have to mean high elevations.
// TODO right-triangle math instead of this jank-ass
base_extra_thickness = 
  (base_tilt_center ? spool_diameter/60 *
    (base_tilt_angle<6  ? rail_width-2 :
    base_tilt_angle<11 ? 6 :
    base_tilt_angle<16 ? 10 :
    base_tilt_angle<22 ? 15 :
    base_tilt_angle<28 ? 20 :
    base_tilt_angle<37 ? 30 :
    body_depth):
  base_tilt_angle<6 ? rail_width-2 :
  0);

///////////////////////////////////////////////////////////////////////////////////


e = 0.01;
//$fn=72;
$fa = 6;
$fs = 0.5;

body_width = spool_diameter + wall_thickness*2;
body_depth = body_width;
body_height = wall_thickness + slot_fc + strip_width + slot_fc + (spool_retainer_walls?wall_thickness:0);
spool_radius = spool_diameter/2;

module mirror_copy(v = [1, 0, 0]) {
  children();
  mirror(v) children();
}

module sqylinder (w=10,d=10,h=10,r=1) {
  hull() {
    mirror_copy([0,1,0]) translate([0,d/2-r,0])
      mirror_copy([1,0,0]) translate([w/2-r,0,0])
        cylinder(h=h,r=r,center=true);
  }
}

// r = outside radius
// l = loops
// h = height
// w = width
// s = space between loops
module spiral(r=10, l=1, h=1, w=1, s=1) {

  // this math for s is not quite right but close
  x = 360/w;
  o = x - s/w*x;
  W = w + s;
  R = r - l*W;

  linear_extrude(h=h)
    polygon(points= concat(
        [ for (t = [0:360*l])    [ (R-W+t/o)*sin(t), (R-W+t/o)*cos(t) ] ],
        [ for (t = [360*l:-1:0]) [ (R-s+t/o)*sin(t), (R-s+t/o)*cos(t) ] ]
      )
    );
}

module spool() {
  loops=4;
  translate([0,0,wall_thickness+slot_fc]) {
    spiral(r=spool_radius-slot_fc/2,l=loops,h=strip_width,w=strip_thickness,s=fc);
    translate([-e,spool_radius-strip_thickness-slot_fc/2,0]) cube([body_width*0.75,strip_thickness,strip_width]);
  }
}

// top rail shape & position
// used by both the male & female parts
module top_rail (h,f=false) {
  x = f ? fc : 0; // expand if female
  translate([-body_width/2+rail_width*1.5+top_hook_thickness,-body_depth/2,0])
    hull() mirror_copy([1,-1,0]) translate([rail_width,-rail_width,0]) cylinder(d=x+rail_width+x,h=h);
}

// bottom rail shape & position
// used by both the male & female parts
module bottom_rail (h,f=false) {
  x = f ? fc : 0; // fitment clearance added to some things for female

  r = rail_width/2 + detent_height/2;        // clip inside radius
  a = body_width/2 - r - clip_thickness -fc; // horizontal at y=0

  // main bar
  translate([a,-body_depth/2+r+wall_thickness,0]) cylinder(r=r+x,h=h);

  // connector
  d = r + wall_thickness + rail_width;
  translate([a-r-x,-body_depth/2-rail_width,0]) cube([x+rail_width+x,d,h]);

  // chamfer
  if (f) translate([a-r+rail_width/2,-body_depth/2-e,0]) rotate([0,0,45]) translate([-rail_width/2,-rail_width/2,0]) cube([rail_width,rail_width,h]);

  // compliance slot
  // only used on female part
  if (f) {
    w = 2;     // slot width

    sr = w/2;  // slot radius
    sa = body_width/2 - sr - clip_thickness; // slot horizontal position
    b = -body_depth/2+wall_thickness+r; // bottom of slot centered on main bar

    // cheeseball auto depth of cut
    // depth of cut proportional to compliant part thickness, width, deflection
    p = b + (h+clip_thickness+detent_height)/2; // pending top

    // max allowable depth of cut leaving wall_thickness to spool
    c = spool_radius + wall_thickness + sr; // diagonal distance center-center
    m = -sqrt(c^2-sa^2); // max top

    t = p>m?m:p; // top of slot

    hull() {
      translate([sa,t,0]) cylinder(r=sr,h=h);
      translate([sa,b,0]) cylinder(r=sr,h=h);
    }

  }

}

// 
module caddy(solid=0) {

  cap = (solid>0); // if solid>0 then we are making a cap
  bh = cap ? solid : body_height; // body height
  slot_depth = strip_thickness + slot_fc;
  slot_height = spool_retainer_walls ? slot_fc + strip_width + slot_fc : body_height ;

  difference() {

    // add
    // main rounded square body
    translate([0,0,bh/2]) sqylinder(w=body_width,d=body_depth,h=bh,r=corner_radius);

    // cut
    group() {
      
      H = bh+2;

      // skip for cap
      if (!cap) translate([0,0,wall_thickness]) {
        // spool cavity
        cylinder(d=spool_diameter,h=bh);
        // dispenser slot
        translate([0,spool_radius-slot_depth,0]) cube([spool_diameter,slot_depth,slot_height]);
      }

      // rail sockets
      translate([0,0,-1]) {
        top_rail(h=H,f=true);
        bottom_rail(h=H,f=true);
      }

    }

  }

  // add
  // partial walls to trap the spool
  // skip for cap
  if (spool_retainer_walls && !cap) {
    translate([0,0,body_height-wall_thickness]) difference() {
      cylinder(d=spool_diameter+wall_thickness,h=wall_thickness);
      cube([spool_diameter-spool_traps_depth*2,body_depth,body_height],center=true);
    }
  }

  // imaginary spool
  // skip for cap
  if (!cap) %spool();
}

module base (l=120) {
  difference() {
    group() {

      // plinth
      hull() {
        // left half of top plate
        xl = body_width/2 - top_hook_thickness - rail_width - wall_thickness - fc;
        // right half of top plate
        xr = body_width/2 - clip_thickness - detent_height - fc;

        // top plate
        translate([-xl,-body_depth/2-1-fc,0])
          cube([xl+xr,1,l]);

        // bottom plate
        if (base_tilt_center) {
          rotate([0,0,base_tilt_angle])
            translate([-body_width/2,-1-body_depth/2-fc-base_extra_thickness,0])
              cube([body_width,1,l]);
        } else {
          translate([body_width/2,-body_depth/2-fc-2-base_extra_thickness,0])
            rotate([0,0,base_tilt_angle])
              translate([-body_width,0,0])
                cube([body_width,1,l]);
        }
      }
    
      top_rail(h=l);

      bottom_rail(h=l);
    }

    // shave junk off the bottom
        if (base_tilt_center) {
          rotate([0,0,base_tilt_angle])
            translate([-body_width/2-1,-body_depth*1.5-fc-3-base_extra_thickness+e,-1])
              cube([body_width+2,body_depth+2,l+2]);
        } else {
          translate([body_width/2,-body_depth/2-fc-3-base_extra_thickness+e,0])
            rotate([0,0,base_tilt_angle])
              translate([-body_width-1,-body_depth-1,-1])
                cube([body_width+2,body_depth+2,l+2]);
        }    


  }
}

///////////////////////////////////////////////////////////////////////////////////
// render

if ($preview || is_undef(PRINT)) {
  if (preview_fully_populated) translate([0,base_length/2,body_depth/2+fc+1+base_extra_thickness]) rotate([90,base_tilt_angle,0]) {
    // full length base
    base(l=base_length);
    // as many caddies as fits
    s = body_height+fc;
    l = base_length - s - (spool_retainer_walls?0:cap_thickness+fc);
    for(i = [0 : s : l]) {
      translate([0,0,i]) caddy();
      if (!spool_retainer_walls && i+s>l) translate([0,0,i+s]) caddy(solid=cap_thickness);
    }
  } else {
    // single caddy base
    base(l=body_height*1.5);
    // single caddy
    caddy();
  }
} // $preview
else if (PRINT=="caddy") caddy();
else if (PRINT=="cap") caddy(solid=cap_thickness);
else if (PRINT=="base") translate([0,body_depth/2,0]) base(l=base_length);