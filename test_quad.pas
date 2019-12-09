{   Program to test quadratic interpolation capability of RENDlib.
}
program "gui" test_quad;
%include 'rend_test_all.ins.pas';

var
  p1, p2, p3, p4, p5, p6:              {points for defining quadratic color surface}
    rend_color3d_t;
  poly: rend_2dverts_t;                {verticies of a polygon}
  xb, yb, ofs: vect_2d_t;              {2D transformation matrix}
  scale: real;                         {scale factor for transformation}
  xpos: real;                          {X coordinate of window center}
  zon: boolean;                        {TRUE if Z interpolant is on}
{
********************************************
*
*   Local subroutine SET_QUAD (V1,V2,V3,V4,V5,V6)
*
*   Set quadratic interpolation from 2D space.  Each parameter contains XYZ,RGB in
*   the 2D space.  Set RGB to quadratic and Z to linear interpolation.  Only
*   V1-V3 will be used to determine the linear Z surface.
}
procedure set_quad (
  in      v1, v2, v3, v4, v5, v6: rend_color3d_t);

var
  t1, t2, t3, t4, t5, t6: vect_2d_t;   {XY of coordinate transformed to 2DIM space}
  v: vect_2d_t;

begin
{
*   Make T1 - T6.  These are the XY coordinates of the anchor points
*   transformed into the 2DIM space.
}
  v.x := v1.x; v.y := v1.y;
  rend_get.xfpnt_2d^ (v, t1);
  v.x := v2.x; v.y := v2.y;
  rend_get.xfpnt_2d^ (v, t2);
  v.x := v3.x; v.y := v3.y;
  rend_get.xfpnt_2d^ (v, t3);
  v.x := v4.x; v.y := v4.y;
  rend_get.xfpnt_2d^ (v, t4);
  v.x := v5.x; v.y := v5.y;
  rend_get.xfpnt_2d^ (v, t5);
  v.x := v6.x; v.y := v6.y;
  rend_get.xfpnt_2d^ (v, t6);

  rend_set.quad_geom_2dim^ (t1, t2, t3, t4, t5, t6); {set quadratic interpolants}
  if zon then begin
    rend_set.lin_vals^ (rend_iterp_z_k, v1.z, v2.z, v3.z);
    end;
  rend_set.quad_vals^ (rend_iterp_red_k,
    v1.red, v2.red, v3.red, v4.red, v5.red, v6.red);
  rend_set.quad_vals^ (rend_iterp_grn_k,
    v1.grn, v2.grn, v3.grn, v4.grn, v5.grn, v6.grn);
  rend_set.quad_vals^ (rend_iterp_blu_k,
    v1.blu, v2.blu, v3.blu, v4.blu, v5.blu, v6.blu);
  end;
{
********************************************
*
*   Local subroutine SET_LINEAR (V1,V2,V3)
*
*   Set quadratic interpolation from 2D space.
}
procedure set_linear (
  in      v1, v2, v3: rend_color3d_t);

var
  t1, t2, t3: rend_color3d_t;          {transformed coordinates}
  v, t: vect_2d_t;

begin
  v.x := v1.x; v.y := v1.y;
  rend_get.xfpnt_2d^ (v, t);           {transform XY coordinate}
  t1.x := t.x;
  t1.y := t.y;
  t1.z := v1.z;
  t1.red := v1.red;
  t1.grn := v1.grn;
  t1.blu := v1.blu;

  v.x := v2.x; v.y := v2.y;
  rend_get.xfpnt_2d^ (v, t);           {transform XY coordinate}
  t2.x := t.x;
  t2.y := t.y;
  t2.z := v2.z;
  t2.red := v2.red;
  t2.grn := v2.grn;
  t2.blu := v2.blu;

  v.x := v3.x; v.y := v3.y;
  rend_get.xfpnt_2d^ (v, t);           {transform XY coordinate}
  t3.x := t.x;
  t3.y := t.y;
  t3.z := v3.z;
  t3.red := v3.red;
  t3.grn := v3.grn;
  t3.blu := v3.blu;

  rend_set.rgbz_linear^ (t1, t2, t3);  {set linear surfaces}
  end;
{
********************************************
*
*   Start of main routine.
}
begin
  rend_test_cmline ('TEST_QUAD');      {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k,
      rend_test_comp_z_k]
    );
{
*   Clear whole image to background color.
}
  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;
  rend_set.rgb^ (0.20, 0.20, 0.20);    {set flat color}
  rend_set.iterp_flat^ (rend_iterp_z_k, 0.0); {set Z to middle of range}
  rend_prim.clear^;
{
**********************
*
*   Left window.
}
  if aspect > 1.0
    then begin                         {image is wider than tall}
      xpos := aspect*0.5;
      scale := xpos;
      if scale > 1.0 then scale := 1.0;
      end
    else begin                         {image is taller than wide}
      xpos := 0.5;
      scale := 0.5;
      end
    ;
  scale := scale*0.95;                 {shrink window slightly}
  xb.x := 0.966*scale;
  xb.y := 0.259*scale;
  yb.x := -0.259*scale;
  yb.y := 0.988*scale;
  ofs.x := -xpos;
  ofs.y := 0.0;
  rend_set.xform_2d^ (xb, yb, ofs);    {set new 2D transform}
  rend_set.zon^ (false);               {turn off Z buffer compares}
  rend_set.iterp_on^ (rend_iterp_z_k, false); {turn off Z interpolant}
  zon := false;                        {indicate Z if OFF}
{
*   The +-1.0 rectangle will be broken into 4 triangular regions formed by the
*   rectangle sides and its diagonals.  Each of these triangles will be quadratically
*   interpolated in a different way.
*
*   Init unused Z coordinate values.
}
  p1.z := 0.1;
  p2.z := 0.1;
  p3.z := 0.1;
  p4.z := 0.1;
  p5.z := 0.1;
  p6.z := 0.1;
{
*   Top triangle
}
  p1.x := 0.0; p1.y := 0.0;            {set counter-clockwise vertex and mid points}
  p2.x := 0.5; p2.y := 0.5;
  p3.x := 1.0; p3.y := 1.0;
  p4.x := 0.0; p4.y := 1.0;
  p5.x := -1.0; p5.y := 1.0;
  p6.x := -0.5; p6.y := 0.5;

  p1.red := 0.0;                       {set red color values at the six points}
  p2.red := 0.0;
  p3.red := 0.5;
  p4.red := 0.5;
  p5.red := 1.0;
  p6.red := 1.0;

  p1.grn := 0.0;                       {set green color values at the six points}
  p2.grn := 0.0;
  p3.grn := 0.5;
  p4.grn := 0.5;
  p5.grn := 1.0;
  p6.grn := 1.0;

  p1.blu := 0.0;                       {set blue color values at the six points}
  p2.blu := 0.0;
  p3.blu := 0.5;
  p4.blu := 0.5;
  p5.blu := 1.0;
  p6.blu := 1.0;

  set_quad (p1, p2, p3, p4, p5, p6);   {set quadratic color definition}

  poly[1].x := p1.x; poly[1].y := p1.y;
  poly[2].x := p3.x; poly[2].y := p3.y;
  poly[3].x := p5.x; poly[3].y := p5.y;
  rend_prim.poly_2d^ (3, poly);
{
*   Left, bottom, and right triangles.
}
  p1.x := 0.0; p1.y := 0.0;            {set counter-clockwise vertex and mid points}
  p2.x := -0.5; p2.y := -0.5;
  p3.x := -1.0; p3.y := -1.0;
  p4.x := 0.0; p4.y := -1.0;
  p5.x := 1.0; p5.y := -1.0;
  p6.x := 0.5; p6.y := -0.5;

  p1.red := 0.0;                       {set red color values at the six points}
  p2.red := 0.0;
  p3.red := 0.5;
  p4.red := 0.5;
  p5.red := 1.0;
  p6.red := 1.0;

  p1.grn := 0.5;                       {set green color values at the six points}
  p2.grn := 0.5;
  p3.grn := 1.0;
  p4.grn := 1.0;
  p5.grn := 0.0;
  p6.grn := 0.0;

  p1.blu := 1.0;                       {set blue color values at the six points}
  p2.blu := 1.0;
  p3.blu := 0.0;
  p4.blu := 0.0;
  p5.blu := 0.5;
  p6.blu := 0.5;

  set_quad (p1, p3, p5, p2, p4, p6);   {set quadratic color definition}

  poly[1].x := p1.x; poly[1].y := p1.y;
  poly[2].x := p3.x; poly[2].y := p3.y;
  poly[3].x := p5.x; poly[3].y := p5.y;
  rend_prim.poly_2d^ (3, poly);
  poly[1].x := -1.0; poly[1].y := 1.0;
  poly[2].x := -1.0; poly[2].y := -1.0;
  poly[3].x := 0.0; poly[3].y := 0.0;
  rend_prim.poly_2d^ (3, poly);
  poly[1].x := 1.0; poly[1].y := 1.0;
  poly[2].x := 0.0; poly[2].y := 0.0;
  poly[3].x := 1.0; poly[3].y := -1.0;
  rend_prim.poly_2d^ (3, poly);
{
**********************
*
*   Right window.
}
  ofs.x := xpos;
  rend_set.xform_2d^ (xb, yb, ofs);    {set new 2D transform}
  rend_set.zon^ (true);                {turn on Z buffer compares}
  rend_set.iterp_on^ (rend_iterp_z_k, true); {turn on Z interpolant}
  zon := true;                         {indicate Z in on}
{
*   Init the values that are the same for each triangle.  These values are the
*   color and Z.
}
  p1.z := 0.4;
  p2.z := -0.1;
  p3.z := 0.9;

  p1.red := 1.0;
  p1.grn := 0.0;
  p1.blu := 0.0;

  p2.red := 0.0;
  p2.grn := 1.0;
  p2.blu := 0.0;

  p3.red := 0.0;
  p3.grn := 0.0;
  p3.blu := 1.0;
{
*   Now draw each triangle by filling in the X,Y coordinate for each vertex,
*   setting the linear color/z, and drawing the triangle as a polygon.
}
  p1.x := 0.5;
  p1.y := 0.9;
  p2.x := 0.2;
  p2.y := -0.9;
  p3.x := 0.8;
  p3.y := -0.9;
  set_linear (p1, p2, p3);
  poly[1].x := p1.x; poly[1].y := p1.y;
  poly[2].x := p2.x; poly[2].y := p2.y;
  poly[3].x := p3.x; poly[3].y := p3.y;
  rend_prim.poly_2d^ (3, poly);

  p1.x := -0.9;
  p1.y := 0.5;
  p2.x := 0.9;
  p2.y := 0.2;
  p3.x := 0.9;
  p3.y := 0.8;
  set_linear (p1, p2, p3);
  poly[1].x := p1.x; poly[1].y := p1.y;
  poly[2].x := p2.x; poly[2].y := p2.y;
  poly[3].x := p3.x; poly[3].y := p3.y;
  rend_prim.poly_2d^ (3, poly);

  p1.x := -0.5;
  p1.y := -0.9;
  p2.x := -0.2;
  p2.y := 0.9;
  p3.x := -0.8;
  p3.y := 0.9;
  set_linear (p1, p2, p3);
  poly[1].x := p1.x; poly[1].y := p1.y;
  poly[2].x := p2.x; poly[2].y := p2.y;
  poly[3].x := p3.x; poly[3].y := p3.y;
  rend_prim.poly_2d^ (3, poly);

  p1.x := 0.9;
  p1.y := -0.5;
  p2.x := -0.9;
  p2.y := -0.2;
  p3.x := -0.9;
  p3.y := -0.8;
  set_linear (p1, p2, p3);
  poly[1].x := p1.x; poly[1].y := p1.y;
  poly[2].x := p2.x; poly[2].y := p2.y;
  poly[3].x := p3.x; poly[3].y := p3.y;
  rend_prim.poly_2d^ (3, poly);

  rend_test_end;                       {clean up and exit graphics}
  end.
