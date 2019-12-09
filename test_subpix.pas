{   Program to test floating point pixel addressing.
}
program "gui" test_subpix;
%include 'rend_test_all.ins.pas';

const
  dx = 50.0;                           {displacements of vectors}
  dy = -11.0;
  n_bursts = 64;                       {number of vectors in the star burst}

  pi = 3.141593;

var
  p: vect_2d_t;                        {scratch point coordinates}
  x, y: real;                          {pixel coordinate}
  i: sys_int_machine_t;                {loop counter}
  a: real;                             {angle}
  da: real;                            {incremental angle}
  r: real;                             {length of starburst vectors}
  verts: rend_2dverts_t;               {all the verticies of a polygon}
  sw_read: boolean;                    {TRUE if read-mod-write prim reads bitmap}

label
  redraw;

begin
  rend_test_cmline ('TEST_SUBPIX');    {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k
      ]
    );
{
*   Determine whether the ADD mode pie slices to be drawn later require reading
*   from the software backup bitmap.  If so, then force software updates on for all
*   the previous drawing.
}
  p.x := 0.0;                          {linear interpolation anchor point}
  p.y := 0.0;
  rend_set.iterp_linear^ (rend_iterp_red_k, p, 0.0, 0.01, 0.01); {linear interpolation}
  rend_set.iterp_linear^ (rend_iterp_grn_k, p, 0.0, 0.01, 0.01);
  rend_set.iterp_linear^ (rend_iterp_blu_k, p, 0.0, 0.01, 0.01);
  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_add_k); {set pixfun ADD}
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_add_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_add_k);
  rend_get.reading_sw_prim^ (          {find out if pie slices will read SW bitmap}
    rend_prim.poly_2dim,               {primitive we will be using}
    sw_read);                          {TRUE if will read from SW bitmap}
  force_sw := force_sw or sw_read;
  rend_set.force_sw_update^ (force_sw); {force SW writes if must read later}

redraw:                                {back here to redraw whole image}
{
*   Clear the whole image to the background color.
}
  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_insert_k); {pixfun INSERT}
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_insert_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_insert_k);
  rend_set.rgb^ (0.15, 0.15, 0.6);     {background color value}
  rend_prim.clear^;
{
*   Draw a large black rectangle in the center of the image.  This is used in a later
*   test to verify that something is being written over it in ADD mode.
}
  rend_set.rgb^ (0.0, 0.0, 0.0);       {color for rectangle}
  rend_set.cpnt_2dimi^ (image_width div 4, image_height div 4);
  rend_prim.rect_2dimi^ (image_width div 2, image_height div 2);
{
*   Draw a bunch of vectors with 3.1 pixel vertical offset from one to the next.
}
  x := 14.5;                           {init start coor of first vector}
  y := 15.5;
  for i := 1 to 11 do begin            {once for each vector}
    rend_set.rgb^ (0.4, 0.4, 0.4);     {color for integer vector}
    rend_set.cpnt_2dimi^ (             {move to integer vector start pixel}
      trunc(x), trunc(y));
    rend_prim.vect_2dimi^ (            {draw integer vector}
      trunc(x+dx), trunc(y+dy));
    rend_set.rgb^ (1.0, 1.0, 1.0);     {color for subpixel vector}
    rend_set.cpnt_2dim^ (x, y);        {move to vector starting point}
    rend_prim.vect_fp_2dim^ (          {draw the subpixel addressed vector}
      x+dx, y+dy);                     {ending coordinates}
    y := y+3.1;                        {position for next vector}
    end;                               {back and draw next vector}
{
*   Draw a bunch of vectors with 0.1 pixel horizontal offset from one to next.
}
  x := 14.5;                           {init start coor of first vector}
  y := 60.5;
  for i := 1 to 11 do begin            {once for each vector}
    rend_set.rgb^ (0.4, 0.4, 0.4);     {color for integer vector}
    rend_set.cpnt_2dimi^ (             {move to integer vector start pixel}
      trunc(x), trunc(y));
    rend_prim.vect_2dimi^ (            {draw integer vector}
      trunc(x+dx), trunc(y+dy));
    rend_set.rgb^ (1.0, 1.0, 1.0);     {color for subpixel vector}
    rend_set.cpnt_2dim^ (x, y);        {move to vector starting point}
    rend_prim.vect_fp_2dim^ (          {draw the subpixel addressed vector}
      x+dx, y+dy);                     {ending coordinates}
    y := y+3.0;                        {position for next vector}
    x := x+0.1;
    end;                               {back and draw next vector}
{
*   Test linear interpolation.
*
*   Set up a linear interpolated color field for drawing the ADD mode polygon pie
*   slices into.
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
{
*   Draw a bunch of pie slices forming a regular polygon.
*   The pie will be draw in ADD mode to detect both overlaps and underlaps.
}
  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_add_k); {set pixfun ADD}
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_add_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_add_k);
  r := min(image_width, image_height)/2.0-2.0; {radius}
  da := 2.0*pi/n_bursts;               {angle between each vector}
  a := 0.0;                            {starting angle}
  verts[1].x := trunc(image_width*0.5); {center point, always first vertex of triangle}
  verts[1].y := trunc(image_height*0.5);
  verts[3].x := verts[1].x+r;          {init previous third point of triangle}
  verts[3].y := verts[1].y;
  for i := 1 to n_bursts do begin      {once for each pie slice}
    verts[2] := verts[3];              {old slice end becomes new slice start}
    a := a+da;                         {advance angle to end of new slice}
    verts[3].x := verts[1].x + r*cos(a); {make vertex at end of slice}
    verts[3].y := verts[1].y - r*sin(a);
    rend_prim.poly_2dim^ (3, verts);   {draw triangle for this pie slice}
    end;                               {back and draw next pie slice}
{
*   Draw a white cross as a reference to particular pixel addresses.  Then draw
*   a gray rectanlge that should cover all but the four tip pixels of the cross.
*   Draw the rectangle again as two orange triangles.
}
  rend_set.force_sw_update^ (false);   {done with the read-modify-write operations}
  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_insert_k); {pixfun INSERT}
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_insert_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_insert_k);
  rend_set.rgb^ (1.0, 1.0, 1.0);       {white cross}
  rend_set.cpnt_2dimi^ (6, 1);
  rend_prim.vect_2dimi^ (6, 11);
  rend_set.cpnt_2dimi^ (11, 6);
  rend_prim.vect_2dimi^ (1, 6);

  rend_set.rgb^ (0.4, 0.4, 0.4);       {gray for rectangle}
  verts[1].x := 2.0;                   {bottom left triangle}
  verts[1].y := 2.0;
  verts[2].x := 2.0;
  verts[2].y := 11.0;
  verts[3].x := 11.0;
  verts[3].y := 11.0;
  verts[4].x := 11.0;
  verts[4].y := 2.0;
  rend_prim.poly_2dim^ (4, verts);

  rend_set.rgb^ (1.0, 0.5, 0.0);       {orange for the two triangles}
  rend_prim.poly_2dim^ (3, verts);
  verts[2].x := 11.0;                  {top right triangle}
  verts[2].y := 11.0;
  verts[3].x := 11.0;
  verts[3].y := 2.0;
  rend_prim.poly_2dim^ (3, verts);

  if rend_test_refresh then goto redraw; {back and redraw image ?}
  end.
