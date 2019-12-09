{   Subroutine REND_TEST_TRI (V1,V2,V3,GNORM)
*
*   Draw 3D triangle.  This layered routine obeys the current REND_TEST library
*   rendering mode.
}
module rend_test_TRI;
define rend_test_tri;
%include 'rend_test2.ins.pas';

procedure rend_test_tri (              {draw triangle with current render mode}
  in      v1, v2, v3: rend_test_vert3d_t; {data for each triangle vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param;

begin
  if wire_on
    then begin                         {render in wire frame mode}
      rend_set.cpnt_3d^ (v1.coor_p^.x, v1.coor_p^.y, v1.coor_p^.z);
      rend_prim.vect_3d^ (v2.coor_p^.x, v2.coor_p^.y, v2.coor_p^.z);
      rend_prim.vect_3d^ (v3.coor_p^.x, v3.coor_p^.y, v3.coor_p^.z);
      rend_prim.vect_3d^ (v1.coor_p^.x, v1.coor_p^.y, v1.coor_p^.z);
      end
    else begin
      rend_prim.tri_3d^ (v1, v2, v3, gnorm);
      end
    ;
  end;
