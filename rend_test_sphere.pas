{   Subroutine REND_TEST_SPHERE (RADIUS)
*
*   Draw a sphere centered at the origin.  RADIUS is the radius of the resulting
*   sphere.
*
*   Normally, this routine calls the RENDlib SPHERE_3D primitive.  However,
*   if the SPHERE_RENDPRIM flag is set in the REND_TEST common block,
*   this routine will tesselate the sphere, calling the TRI_3D primitive.
*   The SPHERE_RENDPRIM flag is intended for compatibility with older
*   benchmarks before the RENDlib SPHERE_3D primitive existed.
*
*   If SPHERE_RENDPRIM is set, this routine will reset the 3D vertex
*   configuration to its liking, then draw the sphere as a list of
*   triangles all within one group.
}
module rend_test_sphere;
define rend_test_sphere;
%include 'rend_test2.ins.pas';

procedure rend_test_sphere (           {draw sphere centered at origin}
  in      radius: real);               {sphere radius}
  val_param;

const
  pi = 3.141593;                       {PI}
  pi2 = pi * 2.0;                      {2 PI}

var
  rad: real;                           {local copy of sphere radius}
  cent: vect_3d_t;                     {sphere center in 3D model coordinate space}
  v1, v2, v3, v4:                      {verticies for current patch}
    rend_test_vert3d_t;
  vul_p, vll_p, vur_p, vlr_p:          {pointers to UL, LL, UR, and LR patch verts}
    rend_test_vert3d_p_t;
  a_lon: real;                         {current longitude angle}
  a_latu, a_latl: real;                {upper and lower current latitude angles}
  da_lon, da_lat: real;                {longitude and latitude angle increments}
  n_lon: sys_int_machine_t;            {number of segments around equator}
  n_lat: sys_int_machine_t;            {number of segments from north to south pole}
  i_lon, i_lat: sys_int_machine_t;     {longitude and latitude loop counters}
  gnorm: vect_3d_t;                    {geometric normal vector of curr patch}
  p: univ_ptr;                         {scratch pointer}
{
*******************************************************************
*
*   Local function MAKE_COOR (LON,LAT)
*
*   Return the sphere surface coordinate at the indicated longitude and latitude.
*   The Y axis will be the polar axis.  Latitude is PI/2 at the Y = radius pole,
*   and -PI/2 at the y = -radius pole.  Longitude varies in the other direction
*   of the convention used for terrestrial navigation.  The longitude angle is
*   zero on the equator at Z = radius, PI/2 at X = radius, PI at Z = -radius, etc.
}
function make_coor (
  in      lon: real;                   {longitude angle, 0 to 2*PI}
  in      lat: real):                  {latitude angle, PI/2 to -PI/2}
  vect_3d_fp1_t;                       {returned sphere surface coordinate}
  val_param;

var
  s_lon, c_lon: real;                  {sin, cos of longitude angle}
  s_lat, c_lat: real;                  {sin, cos of latitude angle}

begin
  s_lon := sin(lon);                   {get sin/cos of the angles}
  c_lon := cos(lon);

  s_lat := sin(lat);
  c_lat := cos(lat);

  make_coor.x := rad * c_lat * s_lon;
  make_coor.y := rad * s_lat;
  make_coor.z := rad * c_lat * c_lon;
  end;
{
*******************************************************************
*
*   Local subroutine ACC_CROSS (P1,P2,P3)
*
*   Find the cross product of the two sides P1-P2 and P3-P2.  The result will be
*   added to GNORM.
}
procedure acc_cross (
  in      p1, p2, p3: vect_3d_fp1_t);  {vertex coordinates}
  val_param;

var
  s1, s2: vect_3d_t;                   {vectors for each side}

begin
  s1.x := p3.x - p2.x;                 {vector along side 1}
  s1.y := p3.y - p2.y;
  s1.z := p3.z - p2.z;

  s2.x := p1.x - p2.x;                 {vector along side 2}
  s2.y := p1.y - p2.y;
  s2.z := p1.z - p2.z;

  gnorm.x := gnorm.x + s1.y*s2.z - s1.z*s2.y; {accumulate cross product}
  gnorm.y := gnorm.y + s1.z*s2.x - s1.x*s2.z;
  gnorm.z := gnorm.z + s1.x*s2.y - s1.y*s2.x;
  end;
{
*******************************************************************
*
*   Start of main routine.
}
begin
  rend_get.cpnt_3d^ (cent.x, cent.y, cent.z); {find where sphere center goes}

  if sphere_rendprim then begin        {use RENDlib sphere primitive ?}
    rend_set.cirres_n^ (1, cirres1);   {set min line segments per circle}
    rend_prim.sphere_3d^ (             {have RENDlib draw the sphere}
      cent.x, cent.y, cent.z,          {sphere center coordinates}
      radius);                         {sphere radius}
    return;                            {all done}
    end;

  rad := radius;                       {make local copy of arg for nested routine}

  n_lon := cirres1;                    {number of segments around the equator}
  n_lat := (cirres1 + 1) div 2;        {number of segments between poles}
  da_lon := pi2 / n_lon;               {longitude angle increment}
  da_lat := pi / n_lat;                {latitude angle increment}

  rend_test_vert3d_init (v1);          {init vertex data structures}
  rend_test_vert3d_init (v2);
  rend_test_vert3d_init (v3);
  rend_test_vert3d_init (v4);
{
*   Loop thru the sphere faces and write each face as two triangles.
}
  a_latu := pi / 2.0;                  {start at north pole}
  for i_lat := 1 to n_lat do begin     {once for each latitude slice}
    a_latl := a_latu - da_lat;         {find latitude of slice bottom}
    a_lon := 0.0;                      {longitude angle for start of first segment}
    v1.norm := make_coor(a_lon, a_latu); {init left patch edge verticies}
    v1.coor.x := v1.norm.x + cent.x;
    v1.coor.y := v1.norm.y + cent.y;
    v1.coor.z := v1.norm.z + cent.z;
    v1.vcache.version := rend_cache_version_invalid;
    v2.norm := make_coor(a_lon, a_latl);
    v2.coor.x := v2.norm.x + cent.x;
    v2.coor.y := v2.norm.y + cent.y;
    v2.coor.z := v2.norm.z + cent.z;
    v2.vcache.version := rend_cache_version_invalid;
    vul_p := addr(v1);                 {init pointers to verticies}
    vll_p := addr(v2);
    vur_p := addr(v3);
    vlr_p := addr(v4);

    for i_lon := 1 to n_lon do begin   {once for each segment around slice}
      a_lon := a_lon + da_lon;         {make longitude of segment right end}
      vur_p^.norm := make_coor(a_lon, a_latu); {upper right coordinate}
      vur_p^.coor.x := vur_p^.norm.x + cent.x;
      vur_p^.coor.y := vur_p^.norm.y + cent.y;
      vur_p^.coor.z := vur_p^.norm.z + cent.z;
      vur_p^.vcache.version := rend_cache_version_invalid;
      vlr_p^.norm := make_coor(a_lon, a_latl); {lower right coordinate}
      vlr_p^.coor.x := vlr_p^.norm.x + cent.x;
      vlr_p^.coor.y := vlr_p^.norm.y + cent.y;
      vlr_p^.coor.z := vlr_p^.norm.z + cent.z;
      vlr_p^.vcache.version := rend_cache_version_invalid;
      gnorm.x := 0.0;
      gnorm.y := 0.0;
      gnorm.z := 0.0;
      acc_cross (vur_p^.coor, vul_p^.coor, vll_p^.coor); {accumulate cross products}
      acc_cross (vll_p^.coor, vlr_p^.coor, vur_p^.coor);
      rend_test_tri (vur_p^, vul_p^, vll_p^, gnorm); {upper left triangle}
      rend_test_tri (vll_p^, vlr_p^, vur_p^, gnorm); {lower right triangle}
      p := vul_p;                      {flip upper verticies}
      vul_p := vur_p;
      vur_p := p;
      p := vll_p;                      {flip lower verticies}
      vll_p := vlr_p;
      vlr_p := p;
      end;                             {back and draw next segment around this slice}

    a_latu := a_latl;                  {old slice bottom is now top of new slice}
    end;                               {back for next slice down the sphere}

  rend_set.cpnt_3d^ (cent.x, cent.y, cent.z); {restore the current point}
  end;
