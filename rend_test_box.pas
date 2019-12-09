{   Subroutine REND_TEST_BOX (V1,V2,V3)
*
*   Draw a box.  Each face will be drawn as two triangles, resulting in a total
*   of 12 triangles.  The current point is at the box corner.  V1-V3 are the three
*   edge vectors eminating from that corner.  If V3 is in the direction of V1xV2,
*   the the triangles will be facing outwards.
}
module rend_test_BOX;
define rend_test_box;
%include 'rend_test2.ins.pas';

procedure rend_test_box (              {draw paralellpiped}
  in      v1, v2, v3: vect_3d_t);      {vectors along each edge from current point}
  val_param;

var
  vert1, vert2, vert3, vert4:          {RENDlib vertex descriptors used for one face}
    rend_test_vert3d_t;
  cpnt: vect_3d_t;                     {original current point}
  oppc: vect_3d_t;                     {opposite corner point}
  v1m, v2m, v3m: vect_3d_t;            {negative V1-V3 edge vectors}
{
***************************************************************
*
*   Local subroutine FACE (P,V1,V2)
*
*   Draw one face of the box.  P is the box corner point, and V1 and V2 are
*   the side vectors eminating from it.
}
procedure face (
  in      p: vect_3d_t;                {face corner point}
  in      v1, v2: vect_3d_t);          {face edge vectors from corner point}
  val_param;

var
  gnorm: vect_3d_t;                    {geometric normal vector of this face}

begin
  version_vcache := version_vcache + 1; {make cache version for this face}
  rend_set.cache_version^ (version_vcache);

  gnorm.x := (v1.y * v2.z) - (v1.z * v2.y); {make geometric normal}
  gnorm.y := (v1.z * v2.x) - (v1.x * v2.z);
  gnorm.z := (v1.x * v2.y) - (v1.y * v2.x);

  vert1.coor.x := p.x;                 {fill in the four corner points}
  vert1.coor.y := p.y;
  vert1.coor.z := p.z;

  vert2.coor.x := p.x + v1.x;
  vert2.coor.y := p.y + v1.y;
  vert2.coor.z := p.z + v1.z;

  vert3.coor.x := vert2.coor.x + v2.x;
  vert3.coor.y := vert2.coor.y + v2.y;
  vert3.coor.z := vert2.coor.z + v2.z;

  vert4.coor.x := p.x + v2.x;
  vert4.coor.y := p.y + v2.y;
  vert4.coor.z := p.z + v2.z;

  rend_prim.tri_3d^ (vert1, vert2, vert3, gnorm);
  rend_prim.tri_3d^ (vert1, vert3, vert4, gnorm);
  end;
{
***************************************************************
*
*   Start of main routine.
}
begin
  rend_get.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {get box corner point}

  oppc.x := cpnt.x + v1.x + v2.x + v3.x; {make opposite box corner}
  oppc.y := cpnt.y + v1.y + v2.y + v3.y;
  oppc.z := cpnt.z + v1.z + v2.z + v3.z;

  v1m.x := -v1.x;                      {make negative box edge vectors}
  v1m.y := -v1.y;
  v1m.z := -v1.z;

  v2m.x := -v2.x;
  v2m.y := -v2.y;
  v2m.z := -v2.z;

  v3m.x := -v3.x;
  v3m.y := -v3.y;
  v3m.z := -v3.z;

  rend_test_vert3d_init (vert1);       {init RENDlib vertex descriptors}
  vert1.norm_p := nil;
  rend_test_vert3d_init (vert2);
  vert2.norm_p := nil;
  rend_test_vert3d_init (vert3);
  vert3.norm_p := nil;
  rend_test_vert3d_init (vert4);
  vert4.norm_p := nil;

  if wire_on
    then begin                         {supposed to render in wire frame mode ?}
      rend_prim.vect_3d^ (
        cpnt.x+v1.x, cpnt.y+v1.y, cpnt.z+v1.z);
      rend_prim.vect_3d^ (
        cpnt.x+v1.x+v2.x, cpnt.y+v1.y+v2.y, cpnt.z+v1.z+v2.z);
      rend_prim.vect_3d^ (
        cpnt.x+v2.x, cpnt.y+v2.y, cpnt.z+v2.z);
      rend_prim.vect_3d^ (
        cpnt.x, cpnt.y, cpnt.z);
      rend_prim.vect_3d^ (
        cpnt.x+v3.x, cpnt.y+v3.y, cpnt.z+v3.z);
      rend_prim.vect_3d^ (
        cpnt.x+v1.x+v3.x, cpnt.y+v1.y+v3.y, cpnt.z+v1.z+v3.z);
      rend_prim.vect_3d^ (
        cpnt.x+v1.x+v2.x+v3.x, cpnt.y+v1.y+v2.y+v3.y, cpnt.z+v1.z+v2.z+v3.z);
      rend_prim.vect_3d^ (
        cpnt.x+v2.x+v3.x, cpnt.y+v2.y+v3.y, cpnt.z+v2.z+v3.z);
      rend_prim.vect_3d^ (
        cpnt.x+v3.x, cpnt.y+v3.y, cpnt.z+v3.z);
      rend_set.cpnt_3d^ (
        cpnt.x+v1.x, cpnt.y+v1.y, cpnt.z+v1.z);
      rend_prim.vect_3d^ (
        cpnt.x+v1.x+v3.x, cpnt.y+v1.y+v3.y, cpnt.z+v1.z+v3.z);
      rend_set.cpnt_3d^ (
        cpnt.x+v1.x+v2.x, cpnt.y+v1.y+v2.y, cpnt.z+v1.z+v2.z);
      rend_prim.vect_3d^ (
        cpnt.x+v1.x+v2.x+v3.x, cpnt.y+v1.y+v2.y+v3.y, cpnt.z+v1.z+v2.z+v3.z);
      rend_set.cpnt_3d^ (
        cpnt.x+v2.x, cpnt.y+v2.y, cpnt.z+v2.z);
      rend_prim.vect_3d^ (
        cpnt.x+v2.x+v3.x, cpnt.y+v2.y+v3.y, cpnt.z+v2.z+v3.z);
      end
    else begin                         {draw as solid object}
      face (cpnt, v1, v3);             {draw the box faces}
      face (cpnt, v3, v2);
      face (cpnt, v2, v1);
      face (oppc, v1m, v2m);
      face (oppc, v2m, v3m);
      face (oppc, v3m, v1m);
      end
    ;

  rend_set.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {restore current point}
  end;
