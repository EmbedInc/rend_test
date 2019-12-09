{   Subroutine REND_TEST_CYL (DX, DY, DZ, RADIUS, CAP_START, CAP_END)
*
*   Draw a cylinder.  The center of one end will be at the 3D current point.
*   DX,DY,DZ is the displacement to the other end.
}
module rend_test_cyl;
define rend_test_cyl;
%include 'rend_test2.ins.pas';

procedure rend_test_cyl (              {draw a cylinder}
  in      dx, dy, dz: real;            {displacement to other end of cylinder}
  in      radius: real;                {cylinder radius}
  in      cap_start: rend_test_cap_k_t; {what kind of cap to put at start}
  in      cap_end: rend_test_cap_k_t); {what kind of cap to put at end}
  val_param;

const
  pi = 3.141593;                       {PI}
  pi2 = pi * 2.0;                      {2 PI}

var
  cpnt: vect_3d_t;                     {original current point}
  vx, vy: vect_3d_t;                   {basis vectors in cylinder end plane}
  vz: vect_3d_t;                       {basis vector along cylinder axis}
  vert1, vert2, vert3, vert4:          {RENDlib vertex descriptors}
    rend_test_vert3d_t;
  ul_p, ur_p, ll_p, lr_p:              {point to current up/low left/right verticies}
    rend_test_vert3d_p_t;
  p: univ_ptr;                         {scratch for flipping pointers}
  a, da: real;                         {angle and angle increment}
  gnorm: vect_3d_t;                    {geometric normal vector of curr patch}
  i: sys_int_machine_t;                {loop counter}
  s, c: real;                          {sin and cos of current angle}
  v: vect_3d_t;                        {scratch vector}
  m: real;                             {for adjusting vector magnitude}
  cap_sphere: boolean;                 {TRUE if draw hemisphere cap as a sphere}

begin
  rend_get.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {point at center of cylendar start}
  vz.x := dx;                          {make cylendar axis basis vector}
  vz.y := dy;
  vz.z := dz;
  rend_test_perp_right (vz, radius, vx, vy); {make basis vectors in end planes}

  rend_test_vert3d_init (vert1);       {init our vertex descriptors}
  rend_test_vert3d_init (vert2);
  rend_test_vert3d_init (vert3);
  rend_test_vert3d_init (vert4);

  da := pi2 / cirres1;                 {angle increment}
  a := 0.0;                            {init starting angle}

  ul_p := addr(vert1);                 {init curr upper/lower left/right verticies}
  ur_p := addr(vert2);
  ll_p := addr(vert3);
  lr_p := addr(vert4);

  lr_p^.norm.x := vx.x;                {init starting "lower" verticies}
  lr_p^.norm.y := vx.y;
  lr_p^.norm.z := vx.z;
  lr_p^.coor.x := cpnt.x + vx.x;
  lr_p^.coor.y := cpnt.y + vx.y;
  lr_p^.coor.z := cpnt.z + vx.z;

  ll_p^.norm.x := vx.x;
  ll_p^.norm.y := vx.y;
  ll_p^.norm.z := vx.z;
  ll_p^.coor.x := lr_p^.coor.x + vz.x;
  ll_p^.coor.y := lr_p^.coor.y + vz.y;
  ll_p^.coor.z := lr_p^.coor.z + vz.z;

  for i := 1 to cirres1 do begin       {once for each cylinder segment}
    a := a + da;                       {make angle for upper verticies}
    s := sin(a);                       {find sin/cos for new angle}
    c := cos(a);

    ur_p^.norm.x := (c * vx.x) + (s * vy.x); {shading normal at new angle}
    ur_p^.norm.y := (c * vx.y) + (s * vy.y);
    ur_p^.norm.z := (c * vx.z) + (s * vy.z);
    ul_p^.norm := ur_p^.norm;

    ur_p^.coor.x := ur_p^.norm.x + cpnt.x; {upper right coordinate}
    ur_p^.coor.y := ur_p^.norm.y + cpnt.y;
    ur_p^.coor.z := ur_p^.norm.z + cpnt.z;

    ul_p^.coor.x := ur_p^.coor.x + vz.x; {upper left coordinate}
    ul_p^.coor.y := ur_p^.coor.y + vz.y;
    ul_p^.coor.z := ur_p^.coor.z + vz.z;

    v.x := ur_p^.coor.x - lr_p^.coor.x; {make vector to find geometric normal}
    v.y := ur_p^.coor.y - lr_p^.coor.y;
    v.z := ur_p^.coor.z - lr_p^.coor.z;

    gnorm.x := (v.y * vz.z) - (v.z * vz.y); {make geometric normal vector}
    gnorm.y := (v.z * vz.x) - (v.x * vz.z);
    gnorm.z := (v.x * vz.y) - (v.y * vz.x);

    rend_test_tri (ll_p^, lr_p^, ur_p^, gnorm); {draw two triangles for this facet}
    rend_test_tri (ll_p^, ur_p^, ul_p^, gnorm);

    p := ul_p;                         {old upper becomes new lower angle}
    ul_p := ll_p;
    ll_p := p;
    p := ur_p;
    ur_p := lr_p;
    lr_p := p;

    ul_p^.vcache.version := rend_cache_version_invalid;
    ur_p^.vcache.version := rend_cache_version_invalid;
    end;                               {back for next cylinder facet}
{
*   Done drawing cylinder.  Now do end caps.
}
  cap_sphere :=                        {OK to draw hemisphere caps as spheres ?}
    (cap_start <> rend_test_cap_none_k) and {both ends of the cylinder are closed}
    (cap_end <> rend_test_cap_none_k) and
    ray_on and                         {ray tracing ?}
    sphere_rendprim;                   {allowed to use RENDlib sphere primitive ?}

  if cap_sphere and (cap_end = rend_test_cap_sph_k)
    then begin                         {draw hemisphere as a sphere}
      rend_prim.sphere_3d^ (           {draw a whole sphere}
        cpnt.x + dx,                   {sphere center point}
        cpnt.y + dy,
        cpnt.z + dz,
        radius);                       {sphere radius}
      end
    else begin                         {draw exactly as specified}
      m := radius / sqrt(sqr(vz.x) + sqr(vz.y) + sqr(vz.z)); {adjust factor for magn}
      vz.x := vz.x * m;                {make vector to top of cap}
      vz.y := vz.y * m;
      vz.z := vz.z * m;
      rend_set.cpnt_3d^ (              {move to end cap}
        cpnt.x + dx,
        cpnt.y + dy,
        cpnt.z + dz);
      rend_test_cap (cap_end, vx, vy, vz); {draw end cap}
      end
    ;

  if cap_sphere and (cap_start = rend_test_cap_sph_k)
    then begin                         {draw hemisphere as a sphere}
      rend_prim.sphere_3d^ (           {draw a whole sphere}
        cpnt.x,                        {sphere center point}
        cpnt.y,
        cpnt.z,
        radius);                       {sphere radius}
      rend_set.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {restore current point}
      end
    else begin                         {draw exactly as specified}
      vz.x := -vz.x;                   {make basis vectors for start cap}
      vz.y := -vz.y;
      vz.z := -vz.z;
      vy.x := -vy.x;
      vy.y := -vy.y;
      vy.z := -vy.z;
      rend_set.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {move to start cap and restore cpnt}
      rend_test_cap (cap_start, vx, vy, vz);
      end
    ;
  end;
