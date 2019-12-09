{   Subroutine REND_TEST_XFORM2D (XB, YB, OFS)
*
*   Set the RENDlib 2D transform, taking into account any anti-aliasing
*   subpixel border.
}
module rend_test_xform2d;
define rend_test_xform2d;
%include 'rend_test2.ins.pas';

procedure rend_test_xform2d (          {set 2D transform, take AA into account}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}
  val_param;

var
  x, y, o: vect_2d_t;                  {local copy of modified transform}

begin
  x.x := xb.x * aa.scale2d;            {make modified transform}
  x.y := xb.y * aa.scale2d;
  y.x := yb.x * aa.scale2d;
  y.y := yb.y * aa.scale2d;
  o.x := ofs.x * aa.scale2d + aa.ofs2d.x;
  o.y := ofs.y * aa.scale2d + aa.ofs2d.y;

  rend_set.xform_2d^ (x, y, o);        {set RENDlib to modified transform}
  end;
