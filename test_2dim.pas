{   Program to test 2D integer layer of RENDlib.
}
program "gui" test_2dim;
%include 'rend_test_all.ins.pas';

const
  n_bursts = 50;                       {number of vectors in star burst}

  pi = 3.141593;

var
  p: vect_2d_t;                        {scratch point coordinates}
  r: real;                             {scratch real number}
  a: real;                             {angle value}
  da: real;                            {incremental angle value}
  i: sys_int_machine_t;                {loop counter}
  ix, iy: sys_int_machine_t;           {scratch integer coordinates}
  idx, idy: sys_int_machine_t;         {scratch integer sizes}

begin
  rend_test_cmline ('TEST_2DIM');      {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k,
      rend_test_comp_z_k]
    );
{
*   Do other RENDlib initialization.
}
  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;
{
*   Clear the whole image to the background color.
}
  rend_set.rgb^ (0.15, 0.15, 0.6);     {background color value}
  rend_set.iterp_flat^ (rend_iterp_z_k, -1.0); {initial Z value}
  rend_prim.clear^;
  rend_set.zon^ (true);                {turn on Z compares}
{
*   Draw two vectors forming a white cross, then draw four rectangles, one each
*   into the corners formed by the cross.  The four rectangles will be drawn with
*   all possible combinations of + and - DX and DY size.  Counterclockwise from
*   top left, the rectangle colors are red, green, yellow, and orange.
}
  rend_set.rgb^ (0.5, 0.5, 1.0);       {blue vector over cross, under rectangles}
  rend_set.iterp_flat^ (rend_iterp_z_k, 0.25); {Z value for vector}
  rend_set.cpnt_2dimi^ (1, 16);
  rend_prim.vect_2dimi^ (14, 1);

  rend_set.rgb^ (1.0, 1.0, 1.0);       {white cross}
  rend_set.iterp_flat^ (rend_iterp_z_k, 0.0);
  rend_set.cpnt_2dimi^ (6, 1);
  rend_prim.vect_2dimi^ (6, 11);
  rend_set.cpnt_2dimi^ (11, 6);
  rend_prim.vect_2dimi^ (1, 6);

  rend_set.iterp_flat^ (rend_iterp_z_k, 0.5);
  rend_set.rgb^ (1.0, 0.3, 0.3);
  rend_set.cpnt_2dimi^ (5, 5);
  rend_prim.rect_2dimi^ (-5, -5);

  rend_set.rgb^ (0.5, 1.0, 0.5);
  rend_set.cpnt_2dimi^ (5, 7);
  rend_prim.rect_2dimi^ (-5, 5);

  rend_set.rgb^ (1.0, 1.0, 0.0);
  rend_set.cpnt_2dimi^ (7, 7);
  rend_prim.rect_2dimi^ (5, 5);

  rend_set.rgb^ (1.0, 0.5, 0.0);
  rend_set.cpnt_2dimi^ (7, 5);
  rend_prim.rect_2dimi^ (5, -5);
{
*   Test linear interpolation.
*
*   First set up the whole image for a linear color gradient, and then draw
*   a starburst of vectors from the center.  Each vector is drawn at a fixed Z value.
*   The first vector is all the way back, and the last vector is all the way to the
*   front.  The other vectors are linearly spaced in between.
}
  p.x := 0.0;                          {red anchor point}
  p.y := 0.0;
  rend_set.iterp_linear^ (             {set red color}
    rend_iterp_red_k,                  {which interpolant}
    p,                                 {color value anchor point}
    0.0,                               {interpolant value at anchor point}
    1.0/image_width,                   {X partial color derivative}
    0.0);                              {Y partial color derivative}

  p.x := image_width/2.0;              {green}
  p.y := image_height/2.0;
  rend_set.iterp_linear^ (
    rend_iterp_grn_k,
    p,
    0.5,
    0.0,
    2.0/image_height);

  p.x := image_width;                  {blue}
  p.y := 0.0;
  r := 1.0/(sqr(image_width) + sqr(image_height));
  rend_set.iterp_linear^ (
    rend_iterp_blu_k,
    p,
    1.0,
    image_width*r,
    -image_height*r);

  a := 0.0;                            {init starting angle}
  r := min(image_width, image_height)/2.0-1.0; {length of the vectors}
  da := 2.0*pi/n_bursts;               {angle between each vector}
  ix := image_width div 2;             {burst center point}
  iy := image_height div 2;
  for i := 1 to n_bursts do begin      {once for each vector}
    rend_set.iterp_flat^ (rend_iterp_z_k, (a/pi-1.0)*0.999);
    rend_set.cpnt_2dimi^ (ix, iy);     {go to burst center point}
    rend_prim.vect_2dimi^ (            {draw vector}
      trunc(ix+0.5 + r*cos(a)),
      trunc(iy+0.5 - r*sin(a)));
    a := a+da;                         {advance to next angle}
    end;                               {back and draw next vector in burst}

  idx := round(2.0*r)-4;               {size of rectangle over burst}
  idy := idx;
  rend_set.rgb^ (0.3, 0.3, 0.3);
  ix := ix-(idx div 2);                {top left corner of rectangle}
  iy := iy-(idy div 2);
  p.x := ix;                           {make floating point anchor point}
  p.y := iy;
  rend_set.iterp_linear^ (             {set full Z range from right to left rect edge}
    rend_iterp_z_k,                    {select Z}
    p,                                 {anchor point at top left rectangle corner}
    1.0,                               {value at anchor point}
    -2.0/idx,                          {X slope}
    0.0);                              {Y slope}
  rend_set.cpnt_2dimi^ (ix, iy);       {go to top left rectangle corner}
  rend_prim.rect_2dimi^ (idx, idy);    {draw the Z buffered rectangle}

  rend_set.rgb^ (0.5, 0.3, 0.3);
  rend_set.iterp_flat^ (rend_iterp_z_k, -0.99);
  rend_set.cpnt_2dimi^ (image_width-1, 0); {draw rectangle at right 20% of image}
  rend_prim.rect_2dimi^ (-image_width div 5, image_height);
{
*   Test pixel functions and clamping.
}
  rend_set.zon^ (false);               {turn off Z compares}
  rend_set.iterp_on^ (rend_iterp_z_k, false); {turn off Z interpolant}
  rend_set.rgb^ (0.6, 0.6, 0.6);

  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_add_k);
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_add_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_add_k);
  rend_set.cpnt_2dimi^ (10, 10);
  rend_prim.rect_2dimi^ (40, 30);
  rend_set.cpnt_2dimi^ (12, 12);
  rend_prim.rect_2dimi^ (40, 30);
  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_sub_k);
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_sub_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_sub_k);
  rend_set.cpnt_2dimi^ (14, 14);
  rend_prim.rect_2dimi^ (40, 30);
  rend_set.cpnt_2dimi^ (16, 16);
  rend_prim.rect_2dimi^ (40, 30);

  rend_set.iterp_pclamp^ (rend_iterp_red_k, false);
  rend_set.iterp_pclamp^ (rend_iterp_grn_k, false);
  rend_set.iterp_pclamp^ (rend_iterp_blu_k, false);
  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_add_k);
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_add_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_add_k);
  rend_set.cpnt_2dimi^ (64, 10);
  rend_prim.rect_2dimi^ (40, 30);
  rend_set.cpnt_2dimi^ (66, 12);
  rend_prim.rect_2dimi^ (40, 30);
  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_sub_k);
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_sub_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_sub_k);
  rend_set.cpnt_2dimi^ (68, 14);
  rend_prim.rect_2dimi^ (40, 30);
  rend_set.cpnt_2dimi^ (70, 16);
  rend_prim.rect_2dimi^ (40, 30);
  rend_set.exit_rend^;

  rend_test_end;                       {clean up and exit graphics}
  end.
