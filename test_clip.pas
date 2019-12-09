{   Test RENDlib 2D clipping.
*
*   Anything on the command line causes program to wait for CR before exiting.
}
program "gui" test_clip;
%include 'rend_test_all.ins.pas';

var
  p1, p2, p3, p4: vect_2d_t;           {scratch points to test transforms}

label
  redraw;

begin
  rend_test_cmline ('TEST_CLIP');      {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k
      ]
    );

redraw:                                {back here to redraw image}
  rend_set.rgb^ (0.15, 0.15, 0.6);     {clear background}
  rend_prim.clear_cwind^;
{
*   Set a clip region and indicate it with a black rectangle.
}
  p1.x := -0.5;                        {upper left corner of clip region}
  p1.y := 0.5;
  p2.x := 0.5;                         {lower right corner of clip region}
  p2.y := -0.5;
  rend_get.xfpnt_2d^ (p1, p3);         {transform rectangle to 2D space}
  rend_get.xfpnt_2d^ (p2, p4);
  rend_test_clip (p3.x, p3.y, p4.x - p3.x, p4.y - p3.y);
  rend_set.rgb^ (0.0, 0.0, 0.0);       {color for rectangle}
  rend_set.cpnt_2dim^ (0.0, 0.0);
  rend_prim.rect_2dimcl^ (image_width, image_height); {set clipping region to black}
{
*   Draw some vectors that get clipped.
}
  rend_set.rgb^ (1.0, 1.0, 1.0);
  rend_set.cpnt_2d^ (-0.45, 0.45);
  rend_prim.rvect_2d^ (-0.3, 1.0);

  if rend_test_refresh then goto redraw;
  end.
