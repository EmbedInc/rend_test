{   Subroutine REND_TEST_CAP_RAD (CAP_TYPE,VPERP,RADIUS)
*
*   Draw an end cap.  CAP_TYPE indicates the type of end cap to draw.  VPERP
*   must be the vector coming out of the object to be capped.  The center of the
*   capped end is at the current point.  RADIUS is what radius to make the cap.
}
module rend_test_CAP_RAD;
define rend_test_cap_rad;
%include 'rend_test2.ins.pas';

procedure rend_test_cap_rad (          {draw circular end cap}
  in      cap_type: rend_test_cap_k_t; {what kind of end cap to draw}
  in      vperp: vect_3d_t;            {vector along object to be capped, any magn}
  in      radius: real);               {cap radius, plane perpendicular to VPERP}
  val_param;

var
  vx, vy, vz: vect_3d_t;               {basis vectors for drawing raw cap}
  m: real;                             {for adjusting vector magnitude}

begin
  rend_test_perp_right (vperp, radius, vx, vy); {make cap basis vectors}
  m := radius / sqrt(sqr(vperp.x) + sqr(vperp.y) + sqr(vperp.z));
  vz.x := vperp.x * m;                 {make perpendicular basis vector}
  vz.y := vperp.y * m;
  vz.z := vperp.z * m;
  rend_test_cap (cap_type, vx, vy, vz); {draw the cap}
  end;
