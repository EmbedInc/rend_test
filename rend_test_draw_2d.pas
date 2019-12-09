{   Subroutine REND_TEST_DRAW_2D (M)
*
*   Do some drawing using 2D primitives.  M is a scale factor to apply to any
*   colors.  M = 1.0 will produce the "normal" color intensities.  M can be made
*   less than 1.0 to reduce the intensity.
}
module rend_test_DRAW_2D;
define rend_test_draw_2d;
%include 'rend_test2.ins.pas';

procedure rend_test_draw_2d (          {draw some stuff using 2D primitives}
  in      m: real);                    {mult factor on intensity levels}
  val_param;

var
  verts: rend_2dverts_t;               {verticies for polygon}
  nv: sys_int_machine_t;               {number of verticies currently in VERTS}
{
**************************************************************************************
*
*   Internal subroutine VERTEX (X,Y)
*
*   Stuff the X,Y coordinate into the next vertex in the VERT array.
}
procedure vertex (
  in      x, y: real);                 {coordinate to stuff into the vertex}
  val_param;

begin
  nv := nv+1;                          {make index of new vertex}
  if nv > rend_max_verts then begin
    writeln ('Internal error.  Too many verticies specified in REND_TEST_DRAW_2D.');
    sys_bomb;
    end;
  verts[nv].x := x;                    {stuff the data into the vertex}
  verts[nv].y := y;
  end;
{
**************************************************************************************
*
*   Start of main routine.
}
begin
  nv := 0;                             {chimney}
  vertex (-0.5, 0.8);
  vertex (-0.5, 0.2);
  vertex (-0.3, 0.4);
  vertex (-0.3, 0.8);
  rend_set.rgb^ (1.0*m, 0.4*m, 0.3*m);
  rend_prim.poly_2d^ (nv, verts);

  nv := 0;                             {roof}
  vertex (0.0, 0.6);
  vertex (-0.8, 0.1);
  vertex (0.8, 0.1);
  rend_set.rgb^ (0.5*m, 0.5*m, 0.5*m);
  rend_prim.poly_2d^ (nv, verts);

  nv := 0;                             {main rectangle}
  vertex (-0.6, 0.1);
  vertex (-0.6, -0.9);
  vertex (0.6, -0.9);
  vertex (0.6, 0.1);
  rend_set.rgb^ (1.0*m, 1.0*m, 0.0*m);
  rend_prim.poly_2d^ (nv, verts);

  rend_set.rgb^ (0.8*m, 0.8*m, 0.8*m);
  rend_set.cpnt_2d^ (-0.4, -0.1);      {vectors for window}
  rend_prim.vect_2d^ (-0.4, -0.4);
  rend_prim.vect_2d^ (0.0, -0.4);
  rend_prim.vect_2d^ (0.0, -0.1);
  rend_prim.vect_2d^ (-0.4, -0.1);
  rend_set.cpnt_2d^ (-0.2, -0.1);
  rend_prim.vect_2d^ (-0.2, -0.4);
  rend_set.cpnt_2d^ (0.0, -0.25);
  rend_prim.vect_2d^ (-0.4, -0.25);

  rend_set.cpnt_2d^ (0.35, -0.89);     {vectors for door}
  rend_prim.vect_2d^ (0.35, -0.5);
  rend_prim.vect_2d^ (0.1, -0.5);
  rend_prim.vect_2d^ (0.1, -0.89);

  rend_set.rgb^ (1.0*m, 1.0*m, 1.0*m); {random scribbles}
  rend_set.cpnt_2d^ (-1.0, 0.3);
  rend_prim.vect_2d^ (-0.4, 0.8);
  rend_prim.vect_2d^ (0.9, -0.2);
  rend_prim.vect_2d^ (0.4, -0.9);
  rend_prim.vect_2d^ (0.6, 0.7);
  rend_prim.vect_2d^ (-0.8, -0.2);
  rend_prim.vect_2d^ (0.1, -0.9);
  rend_prim.vect_2d^ (0.4, 0.7);
  rend_prim.vect_2d^ (0.9, 0.4);
  rend_prim.vect_2d^ (-0.8, 0.1);
  rend_prim.vect_2d^ (1.0, 0.0);
  end;
