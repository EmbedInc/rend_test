{   Subroutine REND_TEST_CONE (DX,DY,DZ,RADIUS)
*
*   Draw a cone.  DX,DY,DZ is the displacement from the center of the circle
*   to the tip of the cone.  RADIUS is the radius of the circle.  The center of
*   the circle will be put at the current point.
}
module rend_test_CONE;
define rend_test_cone;
%include 'rend_test2.ins.pas';

procedure rend_test_cone (             {draw a cone}
  in      dx, dy, dz: real;            {displacement from circle center to tip}
  in      radius: real);               {circle radius}
  val_param;

const
  pi = 3.141593;                       {PI}
  pi2 = pi * 2.0;                      {2 PI}

var
  cpnt: vect_3d_t;                     {original current point}
  vx, vy: vect_3d_t;                   {basis vectors in circle plane}
  vz: vect_3d_t;                       {basis vector along cone axis}
  vert1, vert2:                        {vertex descriptors that run along angle}
    rend_test_vert3d_t;
  u_p, l_p:                            {point to current upper/lower verticies}
    rend_test_vert3d_p_t;
  vert_cent: rend_test_vert3d_t;       {vertex along cone axis}
  p: univ_ptr;                         {scratch for flipping pointers}
  a, da: real;                         {angle and angle increment}
  gnorm: vect_3d_t;                    {geometric normal vector of curr patch}
  i: sys_int_machine_t;                {loop counter}
  s, c: real;                          {sin and cos of current angle}
  v1, v2: vect_3d_t;                   {scratch vectors}

begin
  rend_get.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {point at center of cylendar start}
  vz.x := dx;                          {make cylendar axis basis vector}
  vz.y := dy;
  vz.z := dz;
  rend_test_perp_right (vz, radius, vx, vy); {make basis vectors in end planes}

  rend_test_vert3d_init (vert1);       {init our vertex descriptors}
  rend_test_vert3d_init (vert2);
  rend_test_vert3d_init (vert_cent);
  vert1.norm_p := nil;                 {we won't use shading normals}
  vert2.norm_p := nil;
  vert_cent.norm_p := nil;

  u_p := addr(vert1);                  {init curr upper/lower verticies}
  l_p := addr(vert2);

  da := pi2 / cirres1;                 {angle increment}
{
*   Draw the facets of the cone part.
}
  vert_cent.coor.x := vz.x + cpnt.x;   {set coordinate of cone tip}
  vert_cent.coor.y := vz.y + cpnt.y;
  vert_cent.coor.z := vz.z + cpnt.z;

  l_p^.coor.x := cpnt.x + vx.x;        {init starting "lower" vertex coordinate}
  l_p^.coor.y := cpnt.y + vx.y;
  l_p^.coor.z := cpnt.z + vx.z;

  a := 0.0;                            {init starting angle}
  for i := 1 to cirres1 do begin       {once for each facet in cone}
    a := a + da;                       {make angle for upper verticies}
    s := sin(a);                       {find sin/cos for new angle}
    c := cos(a);

    u_p^.coor.x := cpnt.x + (c * vx.x) + (s * vy.x); {make new upper coordinate}
    u_p^.coor.y := cpnt.y + (c * vx.y) + (s * vy.y);
    u_p^.coor.z := cpnt.z + (c * vx.z) + (s * vy.z);

    v1.x := u_p^.coor.x - l_p^.coor.x; {edge vectors for finding geometric normal}
    v1.y := u_p^.coor.y - l_p^.coor.y;
    v1.z := u_p^.coor.z - l_p^.coor.z;
    v2.x := vert_cent.coor.x - l_p^.coor.x;
    v2.y := vert_cent.coor.y - l_p^.coor.y;
    v2.z := vert_cent.coor.z - l_p^.coor.z;

    gnorm.x := (v1.y * v2.z) - (v1.z * v2.y); {make geometric normal}
    gnorm.y := (v1.z * v2.x) - (v1.x * v2.z);
    gnorm.z := (v1.x * v2.y) - (v1.y * v2.x);

    rend_test_tri (vert_cent, l_p^, u_p^, gnorm); {draw this facet}

    p := u_p;                          {old upper becomes new lower angle}
    u_p := l_p;
    l_p := p;
    u_p^.vcache.version := rend_cache_version_invalid;
    end;
{
*   Draw the circular end of the cone.
}
  vert_cent.coor.x := cpnt.x;          {center vertex coordinate}
  vert_cent.coor.y := cpnt.y;
  vert_cent.coor.z := cpnt.z;
  vert_cent.vcache.version := rend_cache_version_invalid;

  gnorm.x := -vz.x;                    {make geometric normal for whole circle}
  gnorm.y := -vz.y;
  gnorm.z := -vz.z;

  l_p^.coor.x := cpnt.x + vx.x;        {init starting "lower" vertex coordinate}
  l_p^.coor.y := cpnt.y + vx.y;
  l_p^.coor.z := cpnt.z + vx.z;
  l_p^.vcache.version := rend_cache_version_invalid;

  a := 0.0;                            {init starting angle}
  for i := 1 to cirres1 do begin       {once for each facet in cone}
    a := a + da;                       {make angle for upper verticies}
    s := sin(a);                       {find sin/cos for new angle}
    c := cos(a);

    u_p^.coor.x := cpnt.x + (c * vx.x) + (s * vy.x); {make new upper coordinate}
    u_p^.coor.y := cpnt.y + (c * vx.y) + (s * vy.y);
    u_p^.coor.z := cpnt.z + (c * vx.z) + (s * vy.z);

    rend_test_tri (vert_cent, u_p^, l_p^, gnorm); {draw this triangle}

    p := u_p;                          {old upper becomes new lower angle}
    u_p := l_p;
    l_p := p;
    u_p^.vcache.version := rend_cache_version_invalid;
    end;
{
*   Clean up and leave.
}
  rend_set.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {restore 3D current point}
  end;
