{   Program to test RENDlib anti-aliasing capability.
}
program "gui" test_aa;
%include 'rend_test_all.ins.pas';

var
  poly_parms: rend_poly_parms_t;       {current polygon modes and parameters}
  clip_l, clip_r, clip_t, clip_b:      {clip region left, right, top, bottom}
    sys_int_machine_t;
  clip_mx: sys_int_machine_t;          {middle X of clip region}
  aa_bord_x, aa_bord_y: sys_int_machine_t; {number of AA border pixels needed}
  sz_x, sz_y: sys_int_machine_t;       {size of AA destination area}

  clip_handle: rend_clip_2dim_handle_t; {handle to a 2D image space clip window}
  xb, yb, ofs: vect_2d_t;              {2D transform}
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
  rend_set.clip_2dim_on^ (clip_handle, false); {turn clip rectangle off}
  rend_test_draw_2d (0.7);
  rend_set.clip_2dim_on^ (clip_handle, true); {turn clip rectangle on}
  rend_test_draw_2d (1.0);
  end;
{
**********************************************
*
*   Start of main routine.
}
begin
  rend_test_cmline ('TEST_AA');        {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k
      ]
    );
{
*   Connect the drawing bitmap as the RGB source bitmap.
}
  rend_set.iterp_src_bitmap^ (         {connect soruce bitmap to red interpolator}
    rend_iterp_red_k,
    bitmap_rgb,
    0);
  rend_set.iterp_src_bitmap^ (         {connect soruce bitmap to green interpolator}
    rend_iterp_grn_k,
    bitmap_rgb,
    1);
  rend_set.iterp_src_bitmap^ (         {connect soruce bitmap to blue interpolator}
    rend_iterp_blu_k,
    bitmap_rgb,
    2);
{
*   Do other RENDlib initialization.
}
  rend_get.clip_2dim_handle^ (clip_handle); {get handle to a clip window}
  rend_get.poly_parms^ (poly_parms);
  poly_parms.subpixel := true;         {subpixel addressing ON}
  rend_set.poly_parms^ (poly_parms);
  rend_set.force_sw_update^ (true);
  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;
{
*   Clear the whole image to the background color.
}
  rend_set.rgb^ (0.15, 0.15, 0.6);     {background color value}
  rend_prim.clear^;                    {clear whole image to background color}
{
*   Draw a large black rectangle in the center of the image.  This rectangle shows
*   the clip region.
}
  rend_set.rgb^ (0.0, 0.0, 0.0);       {color for rectangle}
  clip_l := image_width div 4;         {find coor of clip region}
  clip_r := clip_l + (image_width div 2);
  clip_t := image_height div 4;
  clip_b := clip_t + (image_height div 2);

  rend_set.cpnt_2dim^ (clip_l, clip_t);
  rend_prim.rect_2dim^ (clip_r-clip_l, clip_b-clip_t);
  rend_set.clip_2dim^ (                {set clip rectangle to black rectangle}
    clip_handle,                       {handle to this clip rectangle}
    clip_l + 0.01,                     {left edge}
    clip_r - 0.01,                     {right edge}
    clip_t + 0.01,                     {top edge}
    clip_b - 0.01,                     {bottom edge}
    true);                             {draw inside this window, clip outside}
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
*   Test anti-aliasing.
}
  rend_set.iterp_aa^ (rend_iterp_red_k, true); {enable RGB for anti-aliasing}
  rend_set.iterp_aa^ (rend_iterp_grn_k, true);
  rend_set.iterp_aa^ (rend_iterp_blu_k, true);
  rend_set.rgb^ (0.0, 0.0, 0.0);       {set to easy interpolation mode}
  clip_mx := (clip_r - clip_l) div 4;  {make src coor for mid X of clip region}
  clip_mx := clip_mx*2 + clip_l;

  rend_set.cpnt_2dimi^ (               {top left of where to put AA rectangle}
    0, image_height div 2);
  rend_prim.anti_alias^ (              {anti-alias left half of clip region}
    (clip_r - clip_l) div 4,           {destination rectangle width}
    (clip_b - clip_t) div 2,           {destination rectangle height}
    clip_l,                            {X of top left source rectangle}
    clip_t);                           {Y of top left source rectangle}

  rend_set.aa_radius^ (2.499);         {set to extra fuzzy}
  rend_set.cpnt_2dimi^ (
    (clip_r - clip_l) div 4,
    image_height div 2);
  rend_prim.anti_alias^ (              {anti-alias right half of clip region}
    (clip_r - clip_l) div 4,           {destination rectangle width}
    (clip_b - clip_t) div 2,           {destination rectangle height}
    clip_mx,                           {X of top left source rectangle}
    clip_t);                           {Y of top left source rectangle}

  rend_set.aa_scale^ (1.0/4.0, 1.0/3.0); {set new shrink factors}
  rend_set.aa_radius^ (1.25);          {set back to "normal" value}
  rend_get.aa_border^ (aa_bord_x, aa_bord_y); {find how much border area required}
  sz_x := (image_width - aa_bord_x*2) div 4;
  sz_y := (image_height - aa_bord_y*2) div 3;
  rend_set.cpnt_2dimi^ (0, 0);
  rend_prim.anti_alias^ (sz_x, sz_y, aa_bord_x, aa_bord_y);

  rend_test_end;                       {clean up and exit graphics}
  end.
