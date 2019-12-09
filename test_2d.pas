{   Program to test the 2D transform and image space clip.
}
program "gui" test_2d;
%include 'rend_test_all.ins.pas';

var
  polyp_save: rend_poly_parms_t;       {reset values for polygon parameters}
  poly_parms: rend_poly_parms_t;       {scratch polygon parameters}
  verts: rend_2dverts_t;               {verticies for polygon}
  xb, yb, ofs: vect_2d_t;              {2D transform}
  clip_x, clip_y, clip_dx, clip_dy:    {our clip rectangle in middle of image}
    sys_int_machine_t;

label
  redraw;
{
**********************************************
*
*   Internal subroutine DRAW_TWICE
*
*   Call the DRAW_STUFF subroutine twice.  The first time will be with low intensity
*   and the clip rectangle off, the second time will be at full intensity with the
*   clip rectangle on.
}
procedure draw_twice;

begin
  rend_test_clip (0, 0, image_width, image_height);
  rend_test_draw_2d (0.7);
  rend_test_clip (clip_x, clip_y, clip_dx, clip_dy);
  rend_test_draw_2d (1.0);
  end;
{
**********************************************
*
*   Internal subroutine TEST_RECT (IX,IY,DX,DY)
*
*   Draw a 3x2 rectangle, first in yellow using the rectangle primitive, then
*   in gray using the polygon primitive.  IX,IY is pixel coordinate of one corner,
*   and DX and DY is the rectangle width and and height.
}
procedure test_rect (
  in      ix, iy: sys_int_machine_t;   {rectangle corner}
  in      dx, dy: sys_int_machine_t);  {rectangle size}

var
  x_ofs, y_ofs: real;                  {corner offset within pixel}
  x, y: real;                          {rectangle coordinate}

begin
  if dx >= 0.0
    then x_ofs := 0.4
    else x_ofs := -0.4;
  if dy >= 0.0
    then y_ofs := 0.4
    else y_ofs := -0.4;

  rend_set.rgb^ (1.0, 1.0, 0.2);
  x := ix + 0.5 - x_ofs;
  y := iy + 0.5 - y_ofs;
  rend_set.cpnt_2dim^ (x, y);
  rend_prim.rect_2dim^ (dx, dy);

  rend_set.rgb^ (0.35, 0.35, 0.35);
  verts[1].x := ix + 0.5 + x_ofs;
  verts[1].y := iy + 0.5 + y_ofs;
  verts[3].x := verts[1].x + dx;
  verts[3].y := verts[1].y + dy;
  if  ((dx >= 0.0) and (dy >= 0.0)) or
      ((dx < 0.0) and (dy < 0.0))
    then begin
      verts[2].x := verts[1].x;
      verts[2].y := verts[1].y + dy;
      verts[4].x := verts[1].x + dx;
      verts[4].y := verts[1].y;
      end
    else begin
      verts[2].x := verts[1].x + dx;
      verts[2].y := verts[1].y;
      verts[4].x := verts[1].x;
      verts[4].y := verts[1].y + dy;
      end
    ;
  rend_prim.poly_2dim^ (4, verts);
  end;
{
**********************************************
*
*   Start of main routine.
}
begin
  rend_test_cmline ('TEST_2D');        {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k
      ]
    );
{
*   Do other RENDlib initialization.
}
  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;

  rend_get.poly_parms^ (polyp_save);   {save polygon drawing parameters}
{
*   Back here to redraw the image.
}
redraw:
  rend_set.poly_parms^ (polyp_save);   {restore original polygon drawing parameters}
{
*   Clear the whole image to the background color.
}
  rend_set.rgb^ (0.15, 0.15, 0.6);     {background color value}
  rend_prim.clear_cwind^;              {clear whole image to background color}
{
*   Draw a large black rectangle in the center of the image.  This rectangle shows
*   the clip region.
}
  clip_x := image_width div 4;
  clip_y := image_height div 4;
  clip_dx := image_width div 2;
  clip_dy := image_height div 2;
  rend_test_clip (clip_x, clip_y, clip_dx, clip_dy);
  rend_set.rgb^ (0.0, 0.0, 0.0);       {color for rectangle}
  rend_prim.clear_cwind^;              {clear clip region to black}
{
*   Set various 2D transforms and call DRAW_TWICE.  This causes objects outside
*   the clip rectangle to be drawn in low intensity.
}
  xb.x := 0.985;
  xb.y := 0.174;
  yb.x := -0.174;
  yb.y := 0.985;
  ofs.x := 0.0;
  ofs.y := 0.0;
  rend_set.xform_2d^ (xb, yb, ofs);
  draw_twice;

  xb.x := 0.173;
  xb.y := 0.100;
  yb.x := -0.100;
  yb.y := 0.173;
  ofs.x := -1.0;
  ofs.y := -0.8;
  rend_set.xform_2d^ (xb, yb, ofs);
  draw_twice;

  xb.x := 0.0;
  xb.y := 0.2;
  yb.x := -0.2;
  yb.y := 0.1;
  ofs.x := 0.9;
  ofs.y := 0.7;
  rend_set.xform_2d^ (xb, yb, ofs);
  draw_twice;
{
*   Draw non-subpixel rectangles and polygons.  The gray polygons should exactly
*   cover the yellow rectangles.  The lighter blue vectors outline where the
*   polygons and rectangle are to be drawn.
}
  rend_get.poly_parms^ (poly_parms);
  poly_parms.subpixel := false;
  rend_set.poly_parms^ (poly_parms);

  rend_set.rgb^ (0.2, 0.2, 0.7);
  rend_set.cpnt_2dimi^ (0, 0);
  rend_prim.vect_2dimi^ (0, 8);
  rend_prim.vect_2dimi^ (10, 8);
  rend_prim.vect_2dimi^ (10, 0);
  rend_prim.vect_2dimi^ (0, 0);
  rend_set.cpnt_2dimi^ (1, 4);
  rend_prim.vect_2dimi^ (9, 4);
  rend_set.cpnt_2dimi^ (5, 1);
  rend_prim.vect_2dimi^ (5, 7);

  test_rect (6, 5, 3, 2);
  test_rect (6, 3, 3, -2);
  test_rect (4, 3, -3, -2);
  test_rect (4, 5, -3, 2);

  if rend_test_refresh then goto redraw;
  end.
