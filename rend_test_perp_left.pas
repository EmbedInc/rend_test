{   Subroutine REND_TEST_PERP_LEFT (VPERP,MAG,V1,V2)
*
*   Make two vectors that are perpendicular to VPERP and to each other.  MAG
*   will be the magnitude of the two vectors.  V2xV1 will be in the direction
*   of VPERP.
}
module rend_test_PERP_LEFT;
define rend_test_perp_left;
%include 'rend_test2.ins.pas';

procedure rend_test_perp_left (        {make perpendicular vectors, left handed}
  in      vperp: vect_3d_t;            {vector to make perpendicular vectors to}
  in      mag: real;                   {magnitude of perpendicular vectors}
  out     v1, v2: vect_3d_t);          {perpendicular to VPERP and each other}
  val_param;

var
  m: real;                             {scale factor for adjusting magnitude}

begin
  if abs(vperp.x) < abs(vperp.y)
    then begin
      if abs(vperp.x) < abs(vperp.z)
        then begin                     {VPERP is least along X direction}
          v1.x := 0.0;
          v1.y := vperp.z;
          v1.z := -vperp.y;
          end
        else begin                     {VPERP is least along Z direction}
          v1.x := vperp.y;
          v1.y := -vperp.x;
          v1.z := 0.0;
          end
        ;
      end
    else begin
      if abs(vperp.y) < abs(vperp.z)
        then begin                     {VPERP is least along Y direction}
          v1.x := -vperp.z;
          v1.y := 0.0;
          v1.z := vperp.x;
          end
        else begin                     {VPERP is least along Z direction}
          v1.x := vperp.y;
          v1.y := -vperp.x;
          v1.z := 0.0;
          end
        ;
      end
    ;
{
*   V1 is now perpendicular to VPERP.
}
  v2.x := (v1.y * vperp.z) - (v1.z * vperp.y); {make second perpendicular vector}
  v2.y := (v1.z * vperp.x) - (v1.x * vperp.z);
  v2.z := (v1.x * vperp.y) - (v1.y * vperp.x);

  m := mag / sqrt(sqr(v1.x) + sqr(v1.y) + sqr(v1.z)); {adjust vector magnitudes}
  v1.x := v1.x * m;
  v1.y := v1.y * m;
  v1.z := v1.z * m;

  m := mag / sqrt(sqr(v2.x) + sqr(v2.y) + sqr(v2.z));
  v2.x := v2.x * m;
  v2.y := v2.y * m;
  v2.z := v2.z * m;
  end;
