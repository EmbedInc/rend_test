{   Subroutine REND_TEST_CAP (CAP_TYPE,VX,VY,VZ)
*
*   Draw an end cap.  CAP_TYPE is the type of cap to draw.  VPERP must be pointing
*   out from the object that is to be capped.  VX and VY will be used as the
*   basis vectors in the plane of the cap.  It points from the center of the capped
*   end to the tip of the cap.  It is irrelevant for the FLAT or NONE end cap
*   types.
}
module rend_test_CAP;
define rend_test_cap;
%include 'rend_test2.ins.pas';

procedure rend_test_cap (              {draw an end cap}
  in      cap_type: rend_test_cap_k_t; {what kind of end cap to draw}
  in      vx, vy: vect_3d_t;           {vectors in plane of cap}
  in      vz: vect_3d_t);              {vector to tip of cap from capped end center}
  val_param;

const
  pi = 3.141593;                       {PI}
  pi2 = pi * 2.0;                      {2 PI}

var
  vert1, vert2, vert3, vert4:          {verticies for cap triangles}
    rend_test_vert3d_t;
  ul_p, ll_p, ur_p, lr_p:              {pointers to UL, LL, UR, and LR patch verts}
    rend_test_vert3d_p_t;
  a_lon, a_lat: real;                  {longitude and latitude angles}
  da_lon, da_lat: real;                {angle increments}
  n_lon, n_lat: sys_int_machine_t;     {number of angle increments}
  i_lon, i_lat: sys_int_machine_t;     {longitude and latitude loop counters}
  c_lon, c_lat, s_lon, s_lat: real;    {SIN and COS of longitude and latitude}
  c_latu, s_latu: real;                {SIN and COS of upper latitude}
  v1, v2: vect_3d_t;                   {scratch vectors for finding GNORM}
  gnorm: vect_3d_t;                    {geometric normal vector of curr patch}
  p: univ_ptr;                         {scratch for flipping pointers}
  cent: vect_3d_t;                     {center of capped end}

begin
  if cap_type = rend_test_cap_none_k then return;

  rend_get.cpnt_3d^ (cent.x, cent.y, cent.z); {find where sphere center goes}
  rend_test_vert3d_init (vert1);       {init vertex descriptors}
  rend_test_vert3d_init (vert2);
  rend_test_vert3d_init (vert3);
  rend_test_vert3d_init (vert4);
  a_lon := 0.0;                        {init to starting angles}
  a_lat := 0.0;

  case cap_type of
{
*   End cap is flat cutoff.  We will draw a circle.
}
rend_test_cap_flat_k: begin
  ll_p := addr(vert2);                 {init leapfrog pointers}
  lr_p := addr(vert3);

  n_lon := cirres1;                    {number of pie slices in circle}
  da_lon := pi2 / n_lon;               {angle increment for each slice}

  gnorm.x := (vx.y * vy.z) - (vx.z * vy.y); {geometric normal same for whole circle}
  gnorm.y := (vx.z * vy.x) - (vx.x * vy.z);
  gnorm.z := (vx.x * vy.y) - (vx.y * vy.x);

  vert1.norm_p := nil;                 {won't use shading normals, all same plane}
  vert2.norm_p := nil;
  vert3.norm_p := nil;

  vert1.coor.x := cent.x;              {set center vertex coordinate}
  vert1.coor.y := cent.y;
  vert1.coor.z := cent.z;
  ll_p^.coor.x := cent.x + vx.x;       {init starting coordinate}
  ll_p^.coor.y := cent.y + vx.y;
  ll_p^.coor.z := cent.z + vx.z;

  for i_lon := 1 to n_lon do begin     {once for each pie slice}
    a_lon := a_lon + da_lon;           {make angle of right side of this slice}
    s_lon := sin(a_lon);               {make SIN,COS of new angle}
    c_lon := cos(a_lon);
    lr_p^.coor.x := (c_lon * vx.x) + (s_lon * vy.x) + cent.x;
    lr_p^.coor.y := (c_lon * vx.y) + (s_lon * vy.y) + cent.y;
    lr_p^.coor.z := (c_lon * vx.z) + (s_lon * vy.z) + cent.z;
    lr_p^.vcache.version := rend_cache_version_invalid;
    rend_test_tri (vert1, ll_p^, lr_p^, gnorm); {draw this slice}
    p := ll_p;                         {old right is new left}
    ll_p := lr_p;
    lr_p := p;
    end;                               {back for next pie slice}
  end;
{
*   End cap is a hemisphere.
}
rend_test_cap_sph_k: begin
  ll_p := addr(vert1);                 {init leapfrog pointers}
  lr_p := addr(vert2);
  ul_p := addr(vert3);
  ur_p := addr(vert4);

  n_lon := cirres1;                    {find number of segments for each angle}
  da_lon := pi2 / n_lon;
  n_lat := (cirres1 + 3) div 4;
  da_lat := pi / 2.0 / n_lat;
  s_latu := 0.0;                       {init SIN,COS of upper angle}
  c_latu := 1.0;

  for i_lat := 1 to n_lat do begin     {once for each horizontal row of patches}
    a_lat := a_lat + da_lat;           {make latitude angle of top of new row}
    s_lat := s_latu;                   {old upper angle is new lower angle}
    c_lat := c_latu;
    s_latu := sin(a_lat);              {save SIN,COS of new upper angle}
    c_latu := cos(a_lat);

    ll_p^.norm.x := (c_lat * vx.x) + (s_lat * vz.x); {init lower left vertex}
    ll_p^.norm.y := (c_lat * vx.y) + (s_lat * vz.y);
    ll_p^.norm.z := (c_lat * vx.z) + (s_lat * vz.z);
    ll_p^.coor.x := ll_p^.norm.x + cent.x;
    ll_p^.coor.y := ll_p^.norm.y + cent.y;
    ll_p^.coor.z := ll_p^.norm.z + cent.z;
    ll_p^.vcache.version := rend_cache_version_invalid;

    ul_p^.norm.x := (c_latu * vx.x) + (s_latu * vz.x); {init upper left vertex}
    ul_p^.norm.y := (c_latu * vx.y) + (s_latu * vz.y);
    ul_p^.norm.z := (c_latu * vx.z) + (s_latu * vz.z);
    ul_p^.coor.x := ul_p^.norm.x + cent.x;
    ul_p^.coor.y := ul_p^.norm.y + cent.y;
    ul_p^.coor.z := ul_p^.norm.z + cent.z;
    ul_p^.vcache.version := rend_cache_version_invalid;

    a_lon := 0.0;                      {init longitude of starting patch}
    for i_lon := 1 to n_lon do begin
      a_lon := a_lon + da_lon;         {make longitude at right of patch}
      s_lon := sin(a_lon);             {save SIN,COS of longitude at right of patch}
      c_lon := cos(a_lon);

      lr_p^.norm.x := (c_lat*(c_lon*vx.x + s_lon*vy.x) + s_lat*vz.x);
      lr_p^.norm.y := (c_lat*(c_lon*vx.y + s_lon*vy.y) + s_lat*vz.y);
      lr_p^.norm.z := (c_lat*(c_lon*vx.z + s_lon*vy.z) + s_lat*vz.z);
      lr_p^.coor.x := lr_p^.norm.x + cent.x;
      lr_p^.coor.y := lr_p^.norm.y + cent.y;
      lr_p^.coor.z := lr_p^.norm.z + cent.z;
      lr_p^.vcache.version := rend_cache_version_invalid;

      ur_p^.norm.x := (c_latu*(c_lon*vx.x + s_lon*vy.x) + s_latu*vz.x);
      ur_p^.norm.y := (c_latu*(c_lon*vx.y + s_lon*vy.y) + s_latu*vz.y);
      ur_p^.norm.z := (c_latu*(c_lon*vx.z + s_lon*vy.z) + s_latu*vz.z);
      ur_p^.coor.x := ur_p^.norm.x + cent.x;
      ur_p^.coor.y := ur_p^.norm.y + cent.y;
      ur_p^.coor.z := ur_p^.norm.z + cent.z;
      ur_p^.vcache.version := rend_cache_version_invalid;

      v1.x := lr_p^.coor.x - ll_p^.coor.x; {make vectors for finding geometric normal}
      v1.y := lr_p^.coor.y - ll_p^.coor.y;
      v1.z := lr_p^.coor.z - ll_p^.coor.z;
      v2.x := ul_p^.coor.x - ll_p^.coor.x;
      v2.y := ul_p^.coor.y - ll_p^.coor.y;
      v2.z := ul_p^.coor.z - ll_p^.coor.z;

      gnorm.x := (v1.y * v2.z) - (v1.z * v2.y); {geometric normal for this patch}
      gnorm.y := (v1.z * v2.x) - (v1.x * v2.z);
      gnorm.z := (v1.x * v2.y) - (v1.y * v2.x);

      rend_test_tri (ll_p^, lr_p^, ur_p^, gnorm); {write lower right triangle}
      rend_test_tri (ll_p^, ur_p^, ul_p^, gnorm); {write upper left triangle}

      p := ll_p;                       {old right becomes new left}
      ll_p := lr_p;
      lr_p := p;
      p := ul_p;
      ul_p := ur_p;
      ur_p := p;
      end;                             {back for next patch in this slice}
    end;                               {back for next slice up}
  end;                                 {end of spherical end cap case}
  end;                                 {end of end cap cases}

  rend_set.cpnt_3d^ (cent.x, cent.y, cent.z); {restore current point}
  end;
