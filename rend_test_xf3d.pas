{   Collection of routines that manipulate RENDlib 3D model transform.
}
module rend_test_xf3d;
define rend_test_view_set;
define rend_test_xf3d_premult;
define rend_test_xf3d_rotate;
define rend_test_xf3d_scale;
define rend_test_xf3d_xlate;
%include 'rend_test2.ins.pas';
{
******************************************************************
*
*   Subroutine REND_TEST_VIEW_SET (EYE, LOOKAT, UP, RAD)
*
*   Set the RENDlib 3D model transform so that the view as described by the call
*   arguments will be obeyed.  The old 3D model transform will be lost.
*   Other RENDlib view parameters will also be set, as appropriate.
}
procedure rend_test_view_set (         {set model transform from view geometry}
  in      eye: vect_3d_t;              {eye point}
  in      lookat: vect_3d_t;           {point to appear at image center}
  in      up: vect_3d_t;               {in direction of image up}
  in      rad: real);                  {image plane "radius" at LOOKAT point}
  val_param;

var
  inv: vect_mat3x3_t;                  {inverse of 3x3 view transform}
  fwd: vect_mat3x3_t;                  {forward view transform}
  ofs: vect_3d_t;                      {forward view transform offset vector}
  eye_dist: real;                      {RENDlib perspective factor}
  m: real;                             {scratch mult factor}
  invertable: boolean;                 {TRUE if INV is invertable}

begin
  inv.zb.x := eye.x - lookat.x;        {set ZB direction, LOOKAT to EYE point}
  inv.zb.y := eye.y - lookat.y;
  inv.zb.z := eye.z - lookat.z;
  m :=                                 {distance from EYE to LOOKAT points}
    sqrt(sqr(inv.zb.x) + sqr(inv.zb.y) + sqr(inv.zb.z));
  eye_dist := m / rad;                 {save perspective EYEDIS for later}
  m := 1.0 / m;                        {mult factor for making unit vector}
  inv.zb.x := m * inv.zb.x;            {make unit vector in ZB direction}
  inv.zb.y := m * inv.zb.y;
  inv.zb.z := m * inv.zb.z;

  inv.xb.x := (up.y * inv.zb.z) - (up.z * inv.zb.y); {set XB direction}
  inv.xb.y := (up.z * inv.zb.x) - (up.x * inv.zb.z);
  inv.xb.z := (up.x * inv.zb.y) - (up.y * inv.zb.x);
  m := 1.0 / sqrt(sqr(inv.xb.x) + sqr(inv.xb.y) + sqr(inv.xb.z));
  inv.xb.x := m * inv.xb.x;            {make unit vector in XB direction}
  inv.xb.y := m * inv.xb.y;
  inv.xb.z := m * inv.xb.z;

  inv.yb.x := (inv.zb.y * inv.xb.z) - (inv.zb.z * inv.xb.y);
  inv.yb.y := (inv.zb.z * inv.xb.x) - (inv.zb.x * inv.xb.z);
  inv.yb.z := (inv.zb.x * inv.xb.y) - (inv.zb.y * inv.xb.x);
{
*   The inverse view transform is now only a pure rotation.
*   Apply final scale factor and find inverse.
}
  inv.xb.x := rad * inv.xb.x;          {make final scaled XB}
  inv.xb.y := rad * inv.xb.y;
  inv.xb.z := rad * inv.xb.z;

  inv.yb.x := rad * inv.yb.x;          {make final scaled YB}
  inv.yb.y := rad * inv.yb.y;
  inv.yb.z := rad * inv.yb.z;

  inv.zb.x := rad * inv.zb.x;          {make final scaled ZB}
  inv.zb.y := rad * inv.zb.y;
  inv.zb.z := rad * inv.zb.z;

  vect_3x3_invert (                    {invert to make forward view transform}
    inv,                               {input matrix to invert}
    m,                                 {unused}
    invertable,                        {TRUE if inversion succeeded}
    fwd);                              {resulting forward view transform}
  if not invertable then begin         {couldn't create inverse ?}
    sys_message_bomb ('rend_test', 'no_view', nil, 0);
    end;
{
*   The 3x3 part of the final view transform is sitting in FWD.
*   Now calculate the offset vector in OFS.  The LOOKAT point should end
*   up at (0,0,0) after transformation thru FWD, so OFS is just the negative
*   of LOOKAT transformed thru FWD.
}
  ofs.x := -(
    (lookat.x * fwd.xb.x) + (lookat.y * fwd.yb.x) + (lookat.z * fwd.zb.x));
  ofs.y := -(
    (lookat.x * fwd.xb.y) + (lookat.y * fwd.yb.y) + (lookat.z * fwd.zb.y));
  ofs.z := -(
    (lookat.x * fwd.xb.z) + (lookat.y * fwd.yb.z) + (lookat.z * fwd.zb.z));

  rend_set.xform_3d^ (fwd.xb, fwd.yb, fwd.zb, ofs); {set new 3D model transform}

  rend_set.perspec_on^ (true);         {enable perspective}
  rend_set.eyedis^ (eye_dist);         {set eye_dist perspective value}
  rend_set.new_view^;                  {compute with new view parameters}
  end;
{
******************************************************************
*
*   Local subroutine REND_TEST_XF3D_PREMULT (XB,YB,ZB)
*
*   Pre-multiply the given 3x3 transform to the current RENDlib transform.
}
procedure rend_test_xf3d_premult (     {premultiply to RENDlib 3D transform}
  in      xb, yb, zb: vect_3d_t);      {the relative X, Y, and Z basis vectors}
  val_param;
var

  old_xb, old_yb, old_zb, old_tl: vect_3d_t; {old transform}
  new_xb, new_yb, new_zb: vect_3d_t;   {new transform}

begin
  rend_get.xform_3d^ (old_xb, old_yb, old_zb, old_tl); {get existing transform}

  new_xb.x := xb.x*old_xb.x + xb.y*old_yb.x + xb.z*old_zb.x;
  new_xb.y := xb.x*old_xb.y + xb.y*old_yb.y + xb.z*old_zb.y;
  new_xb.z := xb.x*old_xb.z + xb.y*old_yb.z + xb.z*old_zb.z;

  new_yb.x := yb.x*old_xb.x + yb.y*old_yb.x + yb.z*old_zb.x;
  new_yb.y := yb.x*old_xb.y + yb.y*old_yb.y + yb.z*old_zb.y;
  new_yb.z := yb.x*old_xb.z + yb.y*old_yb.z + yb.z*old_zb.z;

  new_zb.x := zb.x*old_xb.x + zb.y*old_yb.x + zb.z*old_zb.x;
  new_zb.y := zb.x*old_xb.y + zb.y*old_yb.y + zb.z*old_zb.y;
  new_zb.z := zb.x*old_xb.z + zb.y*old_yb.z + zb.z*old_zb.z;

  rend_set.xform_3d^ (new_xb, new_yb, new_zb, old_tl);
  end;
{
******************************************************************
*
*   Local subroutine REND_TEST_XF3D_ROTATE (AXIS,A)
*
*   Rotate the current RENDlib 3D transform about the indicated axis.  A is the
*   rotation angle in radians.
}
procedure rend_test_xf3d_rotate (      {rotate the current RENDlib 3D transform}
  in      axis: rend_test_axis_k_t;    {rotation axis select}
  in      a: real);                    {rotation angle in radians}
  val_param;

var
  c, s: real;                          {sine and cosine of rotation angle}
  v1, v2, v3: vect_3d_t;               {basis vectors of relative rotation matrix}

begin
  c := cos(a);
  s := sin(a);
  case axis of

rend_test_axis_x_k: begin              {rotate about X from Y to Z}
      v1.x := 1.0;  v1.y := 0.0;  v1.z := 0.0;
      v2.x := 0.0;  v2.y := c;    v2.z := s;
      v3.x := 0.0;  v3.y := -s;   v3.z := c;
      end;

rend_test_axis_y_k: begin              {rotate about Y from Z to X}
      v1.x :=   c;  v1.y := 0.0;  v1.z := -s;
      v2.x := 0.0;  v2.y := 1.0;  v2.z := 0.0;
      v3.x :=   s;  v3.y := 0.0;  v3.z := c;
      end;

rend_test_axis_z_k: begin              {rotate about Z from X to Y}
      v1.x :=   c;  v1.y := s;    v1.z := 0.0;
      v2.x :=  -s;  v2.y := c;    v2.z := 0.0;
      v3.x := 0.0;  v3.y := 0.0;  v3.z := 1.0;
      end;
    end;                               {end of rotation axis cases}

  rend_test_xf3d_premult (v1, v2, v3);
  end;
{
******************************************************************
*
*   Local subroutine REND_TEST_XF3D_SCALE (X,Y,Z)
*
*   Scale the current RENDlib 3D transform by the indicated factors for each axis.
}
procedure rend_test_xf3d_scale (       {scale RENDlib 3D transform}
  in      x, y, z: real);              {scale factors for each axis}
  val_param;

var
  xb, yb, zb, tl: vect_3d_t;           {RENDlib transform}

begin
  rend_get.xform_3d^ (xb, yb, zb, tl); {get existing transform}

  xb.x := xb.x * x;
  xb.y := xb.y * x;
  xb.z := xb.z * x;

  yb.x := yb.x * y;
  yb.y := yb.y * y;
  yb.z := yb.z * y;

  zb.x := zb.x * z;
  zb.y := zb.y * z;
  zb.z := zb.z * z;

  rend_set.xform_3d^ (xb, yb, zb, tl);
  end;
{
******************************************************************
*
*   Local subroutine REND_TEST_XF3D_XLATE (X,Y,Z)
*
*   Move the origin of the current RENDlib 3D coordinate space to the XYZ coordinates
*   given.
}
procedure rend_test_xf3d_xlate (       {move RENDlib 3D space to new origin}
  in      x, y, z: real);              {coordinates of new origin in old space}
  val_param;

var
  xb, yb, zb, tl: vect_3d_t;           {old transform}

begin
  rend_get.xform_3d^ (xb, yb, zb, tl); {get existing transform}

  tl.x := x*xb.x + y*yb.x + z*zb.x + tl.x;
  tl.y := x*xb.y + y*yb.y + z*zb.y + tl.y;
  tl.z := x*xb.z + y*yb.z + z*zb.z + tl.z;

  rend_set.xform_3d^ (xb, yb, zb, tl);
  end;
