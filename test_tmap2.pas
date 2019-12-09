{   WARNING: This code apparently tries to get into the internals of RENDlib
*   that are not exposed externally.  This should be fixed to not attempt this,
*   or the features used by this program properly exported by RENDlib.  This
*   code is not currently being built.
}

{   Program to test texture mapping capability of RENDlib.  Draws a 3D
*   texture mapped cylinder.
*
*   The standard RENDlib test program command line options are legal in
*   addition to the following:
*
*   -BLEND_LEV n
*
*     Set the number of discrete levels for blending between the two
*     texture maps of the most appropriate size.  The default is 256
*     quantization levels, which is essentially continuous.
*
*   -OBJ object
*
*     Specify the object to draw.  Choices are:
*
*       CYL  -  Cylinder.  The cylinder is centered at the origin, is
*         aligned with the Y axis, and has a radius of 0.5.  Its length
*         is adjusted to be 1/2 its circumference.  The texture is mapped
*         twice around the cylinder, and once along its axis.
*
*       CUBE  -  Cube centered around the origin.  It is axis-aligned
*         extending to +-0.6 in all dimensions.  The texture is mapped
*         once to each face.
*
*   -STAT
*
*     Write information to the image and to the image file comment lines
*     about settings that might be relevant.  The default is not to.
*
*   -NSTAT
*
*     Don't write additional information to the image and image file comment
*     lines.  This is the default.
*
*   -UVQUAD
*
*     Force the U and V texture map indicies to be quadratically interpolated
*     accross each polygon.  This is the default.
*
*   -UVLIN
*
*     Force the U and V texture map indicies to be linearly interpolated
*     accross each polygon.  The default is to interpolate them quadratically.
*
*   -REPT n
*
*     Set the number of texture map replications in each dimension from the
*     default (N = 1).  For example, the texture is mapped to each cube face
*     once by default.  When N = 2, the texture is mapped in a 2 x 2 tiled
*     pattern to each cube face.
*
*   -ZRANGE znear zfar
*
*     Set the Z buffer range limits in the view space.  These will be clipped
*     to not include the eye point, if necessary.  The default Z range extends
*     from 1.5 to -1.5.
}
program "gui" test_tmap2;
%include 'rend_test_all.ins.pas';

const
  max_msg_parms = 2;                   {max parameters we can pass messages}
  cyl_rad = 0.5;                       {cylinder radius}
  cube_rad = 0.6;                      {cube "radius"}
  z_near_def = 1.5;                    {Z buffer range limits}
  z_far_def = -1.5;

  pi = 3.141593;                       {what is sounds like, don't touch}

type
  vert_t = record                      {3D vertex with texture indicies}
    coor_p: vect_3d_fp1_p_t;           {pointer to XYZ coordinate}
    norm_p: vect_3d_fp1_p_t;           {pointer to shading normal vector}
    tmapi_p: rend_uvw_p_t;             {pointer to texture map indicies}
    coor: vect_3d_fp1_t;               {XYZ coordinate}
    norm: vect_3d_fp1_t;               {shading normal vector}
    uvw: rend_uvw_t;                   {texture map idicies}
    end;

  object_k_t = (                       {the different objects selected with -OBJ}
    object_cyl_k,                      {cylinder}
    object_cube_k);                    {cube}

var
  opt:                                 {command line argument name}
    %include '(cog)lib/string32.ins.pas';
  parm:                                {command line parameter}
    %include '(cog)lib/string80.ins.pas';
  pick: sys_int_machine_t;             {number of keyword picked from list}
  blend_lev: sys_int_machine_t;        {-BLEND_LEV value}
  obj: object_k_t;                     {ID of object to draw}
  stat_on: boolean;                    {TRUE if -STAT command line option given}
  uvlin: boolean;                      {TRUE if -UVLIN command line option given}
  rept: real;                          {texture map tiling repeat factor}
  z_near, z_far: real;                 {Z buffer and clip limits}
  top_rat: real;                       {depth ratio of top cube face}
  img_comm_p: string_list_p_t;         {string list handle for image file comments}

  tmap_bitmap: rend_bitmap_handle_t;   {handle to texture map source bitmap}
  img: img_conn_t;                     {connection handle to texture map image}

  top, bot: real;                      {Y coor of cylinder ends}
  da: real;                            {angle increment}
  dy: real;                            {Y increment for each quad}
  du, dv: real;                        {U and V increments each step}
  a: real;                             {current angle}
  ia: sys_int_machine_t;               {angle loop counter}
  iy: sys_int_machine_t;               {Y slice loop counter}
  v1, v2, v3, v4: vert_t;              {3D vertcies}
  p1, p2, p3, p4, p5, p6, p7, p8: vect_3d_t; {scratch points}
  n1, n2, n3, n4, n5, n6: vect_3d_fp1_t; {scratch normal vectors}

  msg_parm:                            {parameter reference for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {system-independent error code}

label
  next_opt, err_parm, done_cmline, redraw;
{
************************************************************************
*
*   Local subroutine INIT_VERT (V)
*
*   Init the internal pointers of one of our 3D verticies.
}
procedure init_vert (
  out     v: vert_t);                  {vertex to init}

begin
  v.coor_p := addr(v.coor);
  v.norm_p := addr(v.norm);
  v.tmapi_p := addr(v.uvw);
  end;
{
************************************************************************
*
*   Local subroutine FACE (P1, P2, P3, P4, NORM)
*
*   Draw a quadrilateral with the entire texture map mapped to it.  Each
*   of the P1-P4 call arguments are simple 3D coordinates.  P1 is top left,
*   p2 bottom left, p3 bottom right, and p4 is top right.  The quad
*   is broken up into CIRRES1 segments along each edge.  Therefore,
*   CIRRES1**2 quads will be generated.
*
*   NORM is the unit shading for the whole face.
}
procedure face (
  in      p1, p2, p3, p4: vect_3d_t;   {face corner points}
  in      norm: vect_3d_fp1_t);        {unit shading normal}
  val_param;

var
  d: real;                             {fractional increment for each segment}
  i: sys_int_machine_t;                {output loop counter}
  j: sys_int_machine_t;                {inner loop counter}
  mi, mj: real;                        {I and J fractions into loops}
{
**********
*
*   Local subroutine IPOLATE (V, MDWN, MACR)
*   This subroutine is local to subroutine FACE.
*
*   Create interpolated vertex V for fraction MDWN down the face, and MACR
*   accross the face.
}
procedure ipolate (
  out     v: vert_t;                   {3D vertex descriptor to fill in}
  in      mdwn, macr: real);           {fractions down and accross face}
  val_param;

var
  m1, m2, m3, m4: real;                {mult factors for the 4 corner points}

begin
  m2 := mdwn;                          {init Mx with from vertical interpolation}
  m3 := m2;
  m1 := 1.0 - m3;
  m4 := m1;

  m4 := m4 * macr;                     {factor in horizontal interpolation}
  m3 := m3 * macr;
  m1 := m1 * (1.0 - macr);
  m2 := m2 * (1.0 - macr);

  v.coor.x :=                          {interpolate coordinate}
    m1 * p1.x +
    m2 * p2.x +
    m3 * p3.x +
    m4 * p4.x;
  v.coor.y :=
    m1 * p1.y +
    m2 * p2.y +
    m3 * p3.y +
    m4 * p4.y;
  v.coor.z :=
    m1 * p1.z +
    m2 * p2.z +
    m3 * p3.z +
    m4 * p4.z;

  v.uvw.u := macr * rept;              {set U, V texture map indicies}
  v.uvw.v := mdwn * rept;
  end;
{
**********
*
*   Start subroutine FACE.
}
begin
  d := 1.0 / cirres1;                  {make increment value for each segment}

  v1.norm := norm;                     {set unit shading normals}
  v2.norm := norm;
  v3.norm := norm;
  v4.norm := norm;

  mi := 0.0;                           {init fraction down the face}
  for i := 1 to cirres1 do begin       {down the rows}
    mj := 0.0;                         {init fraction accross this row}
    for j := 1 to cirres1 do begin     {accross this row}
      ipolate (v1, mi, mj);            {interpolate verticies for this sub-quad}
      ipolate (v2, mi + d, mj);
      ipolate (v3, mi + d, mj + d);
      ipolate (v4, mi, mj + d);
      rend_prim.quad_3d^ (v1, v2, v3, v4); {draw this sub-quad}
      mj := mj + d;                    {make fraction accross for next time}
      end;                             {back to do next quad accross}
    mi := mi + d;                      {make fraction down for next time}
    end;                               {back do to next row down}
  end;
{
************************************************************************
*
*   Local subroutine Z_LIMITS (P)
*
*   Update the current Z depth range limits to include point P.  P is in
*   model space and must be transformed to the RENDlib world space.  The
*   current near Z depth limit is in TOP, and the far limit is in BOT.
}
procedure z_limits (
  in      p: vect_3d_t);               {point to include in z depth limits}
  val_param;

var
  pw: vect_3d_t;                       {point P in RENDlib world space}

begin
  rend_get.xfpnt_3d^ (p, pw);          {transform P to RENDlib world space}
  top := max(top, pw.z);               {update Z depth range limits}
  bot := min(bot, pw.z);
  end;
{
************************************************************************
*
*   Start of main routine.
}
begin
  rend_test_cmline ('TEST_TMAP2');     {process RENDlib test command line args}
{
*   Set command line options to default values.
}
  blend_lev := 256;                    {init number of tmap blend levels}
  obj := object_cyl_k;                 {init to draw cylinder}
  stat_on := false;                    {init to -STAT not given}
  uvlin := false;                      {init to quadratic U and V interpolation}
  rept := 1.0;                         {init to default texture repeat}
  z_near := z_near_def;                {init Z buffer limits to default}
  z_far := z_far_def;

next_opt:                              {back here each new command line option}
  rend_test_cmline_token (opt, stat);  {try to get another command line token}
  if string_eos(stat) then goto done_cmline; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_bad', nil, 0);
  string_upcase (opt);                 {make upper case for keyword matching}
  string_tkpick80 (opt,                {pick option name from list}
    '-BLEND_LEV -OBJ -STAT -UVLIN -REPT -UVQUAD -NSTAT -ZRANGE'(0),
    pick);                             {number of picked keyword}
  case pick of                         {which keyword got picked ?}
{
*   -BLEND_LEV n
}
1: begin
  blend_lev := rend_test_cmline_int (stat);
  end;
{
*   -OBJ object
}
2: begin
  rend_test_cmline_token (parm, stat); {try to get object name token}
  if sys_error(stat) then goto err_parm;
  string_upcase (parm);                {make upper case for keyword matching}
  string_tkpick80 (parm,
    'CYL CUBE',
    pick);                             {number of token picked from list}
  case pick of
1:  obj := object_cyl_k;
2:  obj := object_cube_k;
otherwise
    sys_msg_parm_vstr (msg_parm[1], parm);
    sys_msg_parm_vstr (msg_parm[2], opt);
    sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);
    end;
  end;
{
*   -STAT
}
3: begin
  stat_on := true;
  end;
{
*   -UVLIN
}
4: begin
  uvlin := true;
  end;
{
*   -REPT n
}
5: begin
  rept := rend_test_cmline_fp (stat);
  end;
{
*   -UVQUAD
}
6: begin
  uvlin := false;
  end;
{
*   -NSTAT
}
7: begin
  stat_on := false;
  end;
{
*   -ZRANGE znear zfar
}
8: begin
  z_near := rend_test_cmline_fp (stat);
  if sys_error(stat) then goto err_parm;
  z_far := rend_test_cmline_fp (stat);
  end;
{
*   Unrecognized command line option.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_bad', msg_parm, 1);
    end;                               {end of command line option cases}

err_parm:
  sys_msg_parm_vstr (msg_parm[1], cmline.str_p^);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_error_abort (stat, 'string', 'cmline_parm_bad', msg_parm, 2);
  goto next_opt;                       {back for next command line option}
done_cmline:                           {all done processing command line}

  z_near := min(z_near, eye_dist - 0.05); {clip near Z limit to just before eye}
  z_far := min(z_far, z_near - 1.0);   {make sure far Z is behind near Z}
{
*   Done processing the command line.
*
******************************
*
*   Do general graphics initialization.
}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}

  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k,
      rend_test_comp_z_k]
    );

  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;

  rend_set.z_range^ (z_near, z_far);   {set Z buffer range limits}
  rend_set.z_clip^ (z_near, z_far);
  rend_set.new_view^;
{
******************************
*
*   Read the texture map image file and init the texture mapping state.
}
  img_open_read_img (                  {open texture map image file for read}
    tmap_fnam,                         {image file name}
    img,                               {image connection handle}
    stat);
  sys_msg_parm_vstr (msg_parm[1], tmap_fnam);
  sys_error_abort (stat, 'img', 'open_read', msg_parm, 1);

  rend_test_tmap_read (                {read tmap image file and init tmap state}
    img,                               {image file connection handle}
    tmap_bitmap);                      {returned handle to new texture map bitmap}

  if uvlin then begin                  {use only linear U and V ?}
    rend_set.iterp_shade_mode^ (       {set U, V interpolation to linear}
      rend_iterp_u_k, rend_iterp_mode_linear_k);
    rend_set.iterp_shade_mode^ (
      rend_iterp_v_k, rend_iterp_mode_linear_k);
    rend_set.shade_geom^ (rend_iterp_mode_linear_k); {no need for extra points}
    end;

  rend_sw_mipmap_table_init (          {set number of quantization levels for blending}
    blend_lev, rend_tmap.mip.blend);
  rend_set.tmap_func^ (rend_tmapf_ill_k); {do illuminated texture mapping}
{
******************************
*
*   Set up 3D vertex state.
}
  rend_set.vert3d_ent_all_off^;        {set up 3D vertex to match our data structure}
  rend_set.vert3d_ent_on^ (            {declare offset of 3D coordinate pointer}
    rend_vert3d_coor_p_k,
    sys_int_adr_t(addr(v1.coor_p)) - sys_int_adr_t(addr(v1)));
  rend_set.vert3d_ent_on^ (            {declare offset of shading normal pointer}
    rend_vert3d_norm_p_k,
    sys_int_adr_t(addr(v1.norm_p)) - sys_int_adr_t(addr(v1)));
  rend_set.vert3d_ent_on^ (            {declare offset of texture indicies pointer}
    rend_vert3d_tmapi_p_k,
    sys_int_adr_t(addr(v1.tmapi_p)) - sys_int_adr_t(addr(v1)));

  init_vert (v1);                      {init 3D verticies}
  init_vert (v2);
  init_vert (v3);
  init_vert (v4);
{
******************************
*
*   Precompute some object state.
}
  top_rat := 1.0;                      {init to benign value if not used}

  case obj of                          {what object are we drawing ?}
{
*   Object is CYLINDER.
}
object_cyl_k: begin
  top := 0.5 * pi * cyl_rad;           {Y cylinder top}
  bot := -top;                         {Y cylinder bottom}
  da := 2.0 * pi / cirres1;            {angle increment around the cylinder}
  dy := (top - bot) / cirres1;         {Y increment for each quad}
  du := -2.0 / cirres1;                {U texture index increment}
  dv := 1.0 / cirres1;                 {V texture index increment (UV left handed)}
  end;
{
*   Object is CUBE.
*
*   Set the eight cube corner points.  Points 1-4 are the top four corners
*   traversed counter-clockwise as viewed from the outside.  Points 5-8
*   are the same coordinates as 1-4 except that they are offset in Y to
*   be at the cube bottom.  Therefore, P1 is directly above P5.  P1 is
*   the top left corner of the front face.
}
object_cube_k: begin
  if not cirres1_set then begin        {CIRRES1 not explicitly set by user ?}
    cirres1 := 1;                      {don't break up cube faces at all}
    end;

  p1 := vect_vector (-cube_rad, +cube_rad, +cube_rad); {set cube corner points}
  p2 := vect_vector (+cube_rad, +cube_rad, +cube_rad);
  p3 := vect_vector (+cube_rad, +cube_rad, -cube_rad);
  p4 := vect_vector (-cube_rad, +cube_rad, -cube_rad);
  p5 := vect_vector (-cube_rad, -cube_rad, +cube_rad);
  p6 := vect_vector (+cube_rad, -cube_rad, +cube_rad);
  p7 := vect_vector (+cube_rad, -cube_rad, -cube_rad);
  p8 := vect_vector (-cube_rad, -cube_rad, -cube_rad);

  n1.x :=  0.0; n1.y :=  1.0; n1.z :=  0.0; {set cube face normals}
  n2.x :=  0.0; n2.y :=  0.0; n2.z :=  1.0;
  n3.x :=  1.0; n3.y :=  0.0; n3.z :=  0.0;
  n4.x :=  0.0; n4.y :=  0.0; n4.z := -1.0;
  n5.x := -1.0; n5.y :=  0.0; n5.z :=  0.0;
  n6.x :=  0.0; n6.y := -1.0; n6.z :=  0.0;

  top := -1.0e-30;                     {init Z range limits of top cube face}
  bot := 1.0e-30;
  z_limits (p1);                       {find Z range of top cube face}
  z_limits (p2);
  z_limits (p3);
  z_limits (p4);
  top_rat :=                           {make Z depth ratio of top cube face}
    (eye_dist - bot) / (eye_dist - top);
  end;

    end;                               {end of object type cases}
{
******************************
*
*   Force SW emulation if texture mapped primitives will use SW emulation.
}
  if not force_sw then begin           {could be trying to use hardware ?}
    rend_set.zon^ (true);              {set up state for drawing quads}
    rend_set.iterp_on^ (rend_iterp_u_k, true);
    rend_set.iterp_on^ (rend_iterp_v_k, true);
    rend_set.tmap_on^ (true);
    rend_get.reading_sw_prim^ (rend_prim.quad_3d, force_sw);
    rend_set.force_sw_update^ (force_sw); {force SW updates if quad needs SW bitmap}
    end;
{
******************************
*
*   Back here to redraw image due to refresh event.
}
redraw:
  rend_set.enter_level^ (1);           {make sure we are in graphics mode}
{
*   Clear to background.
}
  rend_set.rgb^ (0.2, 0.2, 0.2);       {set color}
  rend_set.iterp_flat^ (rend_iterp_z_k, -1.0);
  rend_set.zon^ (false);               {disable Z compares for background clear}
  rend_set.tmap_on^ (false);           {disable texture mapping}
  rend_set.iterp_on^ (rend_iterp_u_k, false); {disable U,V interpolants}
  rend_set.iterp_on^ (rend_iterp_v_k, false);
  rend_prim.clear_cwind^;              {draw the background}

  rend_set.zon^ (true);                {re-enable Z buffering}
  rend_set.iterp_on^ (rend_iterp_u_k, true); {re-enable texture index interpolants}
  rend_set.iterp_on^ (rend_iterp_v_k, true);
  rend_set.tmap_on^ (true);            {re-enable texture mapping}

  case obj of                          {what object are we drawing ?}
{
***********
*
*   Draw CYLINDER.
}
object_cyl_k: begin
  v2.coor.x := cyl_rad;                {init previous leading edge info}
  v2.coor.z := 0.0;
  v2.norm.x := 1.0;
  v2.norm.y := 0.0;
  v2.norm.z := 0.0;
  v2.uvw.u := 1.0;

  a := 0.0;                            {init previous angle}

  for ia := 1 to cirres1 do begin      {once for each segment in a circle}
    a := a - da;                       {make leading angle for this slice}

    v2.coor.y := top;                  {re-align with top of cylinder}
    v2.uvw.v := 0.0;

    v1.coor := v2.coor;                {old leading edge is new trailing edge}
    v1.norm := v2.norm;
    v1.uvw := v2.uvw;

    v2.norm.x := cos(a);               {make new leading unit normal}
    v2.norm.z := -sin(a);
    v2.coor.x := v2.norm.x * cyl_rad;  {make new leading coordinate}
    v2.coor.z := v2.norm.z * cyl_rad;
    v2.uvw.u := v1.uvw.u + du;         {make new leading U texture index}

    v4.norm := v1.norm;                {set static values for this slice}
    v4.coor.x := v1.coor.x;
    v4.coor.z := v1.coor.z;
    v4.uvw.u := v1.uvw.u;
    v3.norm := v2.norm;
    v3.coor.x := v2.coor.x;
    v3.coor.z := v2.coor.z;
    v3.uvw.u := v2.uvw.u;

    for iy := 1 to cirres1 do begin    {once for each quad down the slice}
      v4.coor.y := v1.coor.y - dy;     {make values for quad bottom}
      v4.uvw.v := v1.uvw.v + dv;
      v3.coor.y := v2.coor.y - dy;
      v3.uvw.v := v2.uvw.v + dv;

      rend_prim.quad_3d^ (v1, v2, v3, v4); {draw this quad}

      v1.coor.y := v4.coor.y;          {old bottom values are now at top}
      v1.uvw.v := v4.uvw.v;
      v2.coor.y := v3.coor.y;
      v2.uvw.v := v3.uvw.v;
      end;                             {back for next quad down this slice}
    end;                               {back for next slice around cylinder}
  end;                                 {end of object is cylinder case}
{
***********
*
*   Draw CUBE.
}
object_cube_k: begin
  face (p4, p1, p2, p3, n1);           {top}
  face (p1, p5, p6, p2, n2);           {front}
  face (p2, p6, p7, p3, n3);           {right}
  face (p3, p7, p8, p4, n4);           {back}
  face (p4, p8, p5, p1, n5);           {left}
  face (p5, p8, p7, p6, n6);           {bottom}
  end;

    end;                               {end of object type cases}
{
***********
*
*   Draw comment.
}
  rend_set.rgb^ (1.0, 1.0, 1.0);       {set color}
  rend_set.iterp_flat^ (rend_iterp_z_k, -1.0);
  rend_set.zon^ (false);               {disable Z compares for background clear}
  rend_set.tmap_on^ (false);           {disable texture mapping}
  rend_set.iterp_on^ (rend_iterp_u_k, false); {disable U,V interpolants}
  rend_set.iterp_on^ (rend_iterp_v_k, false);
  rend_test_comment_draw;              {draw user's comment, if any was entered}

  if stat_on then begin                {write statistics requested ?}
    rend_get.comments_list^ (img_comm_p); {get handle to image output file comments}
    string_list_pos_last (img_comm_p^); {go to last line of image file comments}
    string_list_line_add (img_comm_p^); {create line for statistics and info}
    string_appendn (img_comm_p^.str_p^, '  ', 2); {indent stats line}

    string_vstring (parm, 'Top face depth rat '(0), -1);
    string_f_fp_fixed (opt, top_rat, 2);
    string_append (parm, opt);
    rend_prim.text^ (parm.str, parm.len);
    string_append (img_comm_p^.str_p^, parm);

    string_vstring (parm, 'Eye pos '(0), -1);
    string_f_fp_fixed (opt, eye_dist, 2);
    string_append (parm, opt);
    rend_prim.text^ (parm.str, parm.len);
    string_appendn (img_comm_p^.str_p^, ', ', 2);
    string_append (img_comm_p^.str_p^, parm);

    string_vstring (parm, 'Segments '(0), -1);
    string_f_int (opt, cirres1);
    string_append (parm, opt);
    rend_prim.text^ (parm.str, parm.len);
    string_appendn (img_comm_p^.str_p^, ', ', 2);
    string_append (img_comm_p^.str_p^, parm);
    end;

  if rend_test_refresh then goto redraw;
  end.
