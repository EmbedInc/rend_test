{   Test 3D primitives.  Draw "shaft" image.  Command line options are:
*
*   -NOZ
*
*     Disable Z buffering.
*
*   -BENCH
*
*     Force benchmark compatibility mode.  This program has been used as
*     a benchmark test of the ray tracer and machine speed.  However, new
*     changes to RENDlib and the REND_TEST library cause it to no longer
*     perform the same operations by default.  This command line option
*     forces the program to operate in the "old" way.  This allows effective
*     comparisons to historical benchmark results.  See file BENCH in the
*     cognivision INFO directory for more information about the benchmark
*     tests and results on various machines.
}
program "gui" test_3d;
%include 'rend_test_all.ins.pas';

const
  shaft_sx = 0.85;                     {shaft starting coordinate}
  shaft_sy = -0.70;
  shaft_sz = -0.10;
  shaft_ex = -0.75;                    {shaft ending coordinate}
  shaft_ey = 0.55;
  shaft_ez = 0.20;
  shaft_rad = 0.25;                    {shaft radius}
  sph_rad = 0.20;                      {radius of small spheres}
  n_sph = 7;                           {number of small spheres around shaft}
  plate_thick = 0.04;                  {thickness of plates around spheres}
  fat_rad = 0.35;                      {radius of fat part of shaft}
  fat_len = 0.30;                      {length of fat part of shaft}
  max_msg_parms = 2;                   {max parameters we can pass to a message}

  pi = 3.141593;
  pi2 = pi * 2.0;

var
  p1: vect_2d_t;                       {for dummy 2D interpolation anchor point}
  v1, v2, v3: vect_3d_t;               {scratch vectors}
  shaft: vect_3d_t;                    {shaft vector}
  shaftu: vect_3d_t;                   {shaft unit vector}
  shaftum: vect_3d_t;                  {negative shaft unit vector}
  light1, light2, light3: rend_light_handle_t; {handle to our light sources}
  shaft_len: real;                     {length of whole shaft}
  m: real;                             {for adjusting vector magnitude}
  a, da: real;                         {angle and angle increment}
  i: sys_int_machine_t;                {loop counter}
  ix, iy: sys_int_machine_t;           {scratch integer pixel coordinates}
  s, c: real;                          {SIN,COS values at current angle}
  read_sw: boolean;                    {TRUE if triangle prim reads from bitmap}
  ray_saved: boolean;                  {TRUE if ray tracing prims already saved}
  z_on: boolean;                       {TRUE if Z buffering allowed}

  opt: string_var32_t;                 {command line option name}
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {device independent error code}

label
  next_opt, done_opts, redraw, done_3d;

begin
  opt.max := sizeof(opt.str);

  rend_test_cmline ('TEST_3D');        {read standard command line options}
  z_on := true;                        {init to default values}
{
*   Back here for each new command line option.
}
next_opt:
  rend_test_cmline_token (opt, stat);  {get next command line option name}
  if string_eos(stat) then goto done_opts; {nothing more on command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (                    {pick option name from list}
    opt,                               {option name}
    '-NOZ -BENCH',
    pick);                             {number of picked option}
  case pick of                         {do routine for specific option}
{
*   -NOZ
}
1: begin
  z_on := false;
  end;
{
*   -BENCH
}
2: begin
  sphere_rendprim := false;            {don't use RENDlib SPHERE_3D primitive}
  end;
{
*   Illegal command line option.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_bad', msg_parm, 1);
    end;                               {end of command line option cases}
  if not sys_error(stat) then goto next_opt;
  sys_msg_parm_vstr (msg_parm[1], cmline.str_p^);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);

done_opts:                             {done with all the command line options}
  z_on := z_on and (not ray_on);       {TRUE if will be Z buffering}
{
*   Done processing the command line options.
}
  if not set_bits_vis then begin       {-BITS_VIS not explicitly set ?}
    bits_vis := 24.0;                  {default to maximum color resolution}
    set_bits_vis := true;
    end;
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k,
      rend_test_comp_z_k]
    );
  rend_set.zfunc^ (rend_zfunc_gt_k);   {set Z compare function}
  rend_set.dev_z_curr^ (true);         {pretend Z buffer is up to date}
  rend_set.backface^ (rend_bface_front_k); {draw only front of polygons}

  rend_set.z_range^ (1.1, -1.1);       {set object Z limits in 3D world space}
  rend_set.z_clip^ (1.1, -1.1);
  rend_set.new_view^;                  {done changing view parameters}
{
*   Set up light sources.
}
  rend_set.del_all_lights^;            {delete any existing light sources}

  rend_set.create_light^ (light1);
  rend_set.light_dir^ (                {set light source 1, over right shoulder}
    light1,                            {light source handle}
    0.55, 0.55, 0.55,                  {color values}
    3.0, 4.5, 7.0);                    {direction}

  rend_set.create_light^ (light2);
  rend_set.light_dir^ (                {set light source 2, from left and lower}
    light2,                            {light source handle}
    0.30, 0.30, 0.30,                  {color values}
    -7.0, 4.0, 6.5);                   {direction}

  rend_set.create_light^ (light3);
  rend_set.light_pnt^ (                {set light source 3 at the viewer position}
    light3,                            {light source handle}
    0.20, 0.20, 0.20,                  {color values}
    0.0, 0.0, 3.3);                    {light source coordinate}
{
*   Set surface properties for main "shaft".
}
  rend_set.suprop_all_off^;            {init all surface properties to OFF}
  rend_set.suprop_diff^ (0.75, 0.75, 0.85);
  rend_set.suprop_spec^ (0.25, 0.25, 0.25, 31.0);
{
*   Force software emulation if the 3D triangle primitive will read from the
*   software bitmap.
}
  p1.x := 0.0;                         {dummy iterp linear anchor point}
  p1.y := 0.0;
  rend_set.iterp_linear^ (rend_iterp_red_k, p1, 0.1, 0.1, 0.1);
  rend_set.iterp_linear^ (rend_iterp_grn_k, p1, 0.1, 0.1, 0.1);
  rend_set.iterp_linear^ (rend_iterp_blu_k, p1, 0.1, 0.1, 0.1);
  rend_set.iterp_linear^ (rend_iterp_z_k, p1, 0.1, 0.1, 0.1);
  rend_set.zon^ (z_on);                {enable/disable Z appropriately}
  rend_set.iterp_on^ (rend_iterp_z_k, z_on);
  rend_set.start_group^;
  if ray_on then begin                 {check for ray tracing}
    rend_set.ray_save^ (true);
    end;
  read_sw := rend_test_tri_reading_sw; {TRUE if our prim needs SW bitmap current}
  if ray_on then begin
    rend_set.ray_save^ (false);
    end;
  rend_set.end_group^;
  rend_set.force_sw_update^ (force_sw or read_sw); {force SW emulation if necessary}
  ray_saved := false;                  {not primitives saved for ray tracing yet}
{
***********************************************
*
*   Jump back here to redraw the image.
}
redraw:
  rend_set.enter_level^ (1);           {make sure we are in graphics mode}
{
*   Clear the background.
}
  rend_set.rgb^ (0.15, 0.15, 0.60);    {set background color}
  rend_set.zon^ (false);               {disable Z compares for background clear}
  if z_on then begin                   {using Z buffer ?}
    rend_set.iterp_on^ (rend_iterp_z_k, true);
    rend_set.iterp_flat^ (rend_iterp_z_k, -1.0);
    end;
  rend_prim.clear_cwind^;              {draw background}
  rend_prim.flush_all^;                {force all cached drawing to the device}
{
*   Set up for 3D drawing.
}
  rend_set.zon^ (z_on);                {enable Z buffer is we're going to use it}
  rend_set.iterp_on^ (rend_iterp_z_k, z_on);

  if ray_on then begin                 {ray tracing ?}
    if ray_saved then goto done_3d;    {3D primitives already saved ?}
    rend_set.ray_save^ (true);
    end;
{
*   Draw the main "shaft".
}
  rend_set.suprop_diff^ (0.75, 0.75, 0.85);
  rend_set.suprop_spec^ (0.25, 0.25, 0.25, 31.0);
  shaft.x := shaft_ex - shaft_sx;      {make shaft displacement vector}
  shaft.y := shaft_ey - shaft_sy;
  shaft.z := shaft_ez - shaft_sz;
  shaft_len := sqrt(sqr(shaft.x) + sqr(shaft.y) + sqr(shaft.z));
  m := 1.0 / shaft_len;
  shaftu.x := shaft.x * m;             {make unit vector along shaft}
  shaftu.y := shaft.y * m;
  shaftu.z := shaft.z * m;
  shaftum.x := -shaftu.x;              {shaft unit vector in other direction}
  shaftum.y := -shaftu.y;
  shaftum.z := -shaftu.z;

  rend_test_colors_wire;               {set up wire frame colors, if needed}
  rend_set.start_group^;
  rend_set.cpnt_3d^ (shaft_sx, shaft_sy, shaft_sz); {go to shaft start}
  rend_test_cyl (                      {draw shaft cylender}
    shaft.x, shaft.y, shaft.z,         {cylender axis vector}
    shaft_rad,                         {radius}
    rend_test_cap_sph_k,               {start cap type}
    rend_test_cap_sph_k);              {end cap type}
  rend_set.end_group^;
{
*   Draw the set of small spheres around the shaft.
}
  rend_set.suprop_diff^ (0.40, 0.85, 0.40);
  rend_test_colors_wire;               {set up wire frame colors, if needed}
  rend_set.start_group^;

  v1.x := shaft_sx + (0.5 * shaft.x);  {position to center of the spheres}
  v1.y := shaft_sy + (0.5 * shaft.y);
  v1.z := shaft_sz + (0.5 * shaft.z);

  rend_test_perp_right (               {make basis vectors for finding sphere centers}
    shaft,                             {perpendicular to basis vectors}
    shaft_rad + sph_rad,               {length of basis vectors}
    v2, v3);                           {returned orthogonal basis vectors}

  a := 0.0;                            {init starting angle}
  da := pi2 / n_sph;                   {angle increment}
  for i := 1 to n_sph do begin         {once for each sphere}
    s := sin(a);                       {save SIN,COS at this angle}
    c := cos(a);
    rend_set.cpnt_3d^ (                {move to center of this sphere}
      v1.x + (c * v2.x) + (s * v3.x),
      v1.y + (c * v2.y) + (s * v3.y),
      v1.z + (c * v2.z) + (s * v3.z));
    rend_test_sphere (sph_rad);        {draw this sphere}
    a := a + da;                       {increment angle for next sphere}
    end;
  rend_set.end_group^;
{
*   Draw the two plates around the spheres.
}
  rend_set.suprop_diff^ (0.85, 0.40, 0.40);
  rend_test_colors_wire;               {set up wire frame colors, if needed}
  rend_set.start_group^;

  rend_set.cpnt_3d^ (                  {go to center of face of lower plate}
    v1.x - (shaftu.x * sph_rad),
    v1.y - (shaftu.y * sph_rad),
    v1.z - (shaftu.z * sph_rad));
  rend_test_cyl (                      {draw lower plate as cylender}
    -shaftu.x * plate_thick,           {cylender displacement}
    -shaftu.y * plate_thick,
    -shaftu.z * plate_thick,
    shaft_rad + (2.0 * sph_rad),       {cylender radius}
    rend_test_cap_flat_k, rend_test_cap_flat_k); {end caps are flat cutoffs}

  rend_set.cpnt_3d^ (                  {go to center of face of lower plate}
    v1.x + (shaftu.x * sph_rad),
    v1.y + (shaftu.y * sph_rad),
    v1.z + (shaftu.z * sph_rad));
  rend_test_cyl (                      {draw lower plate as cylender}
    shaftu.x * plate_thick,            {cylender displacement}
    shaftu.y * plate_thick,
    shaftu.z * plate_thick,
    shaft_rad + (2.0 * sph_rad),       {cylender radius}
    rend_test_cap_flat_k, rend_test_cap_flat_k); {end caps are flat cutoffs}
  rend_set.end_group^;
{
*   Draw the fat parts of the shaft.
}
  rend_set.suprop_diff^ (0.55, 0.45, 0.45);
  rend_test_colors_wire;               {set up wire frame colors, if needed}
  rend_set.start_group^;

  m := (0.85 * shaft_len) - (fat_len * 0.5); {shaft distance to bottom of fat part}
  rend_set.cpnt_3d^ (                  {move to lower end of fat part}
    shaft_sx + (m * shaftu.x),
    shaft_sy + (m * shaftu.y),
    shaft_sz + (m * shaftu.z));
  rend_test_cyl (                      {draw fat part as cylender}
    shaftu.x * fat_len,                {cylender displacement}
    shaftu.y * fat_len,
    shaftu.z * fat_len,
    fat_rad,                           {radius}
    rend_test_cap_flat_k, rend_test_cap_flat_k); {end caps are flat cutoffs}

  m := (0.15 * shaft_len) - (fat_len * 0.5); {shaft distance to bottom of fat part}
  rend_set.cpnt_3d^ (                  {move to lower end of fat part}
    shaft_sx + (m * shaftu.x),
    shaft_sy + (m * shaftu.y),
    shaft_sz + (m * shaftu.z));
  rend_test_cyl (                      {draw fat part as cylender}
    shaftu.x * fat_len,                {cylender displacement}
    shaftu.y * fat_len,
    shaftu.z * fat_len,
    fat_rad,                           {radius}
    rend_test_cap_flat_k, rend_test_cap_flat_k); {end caps are flat cutoffs}
  rend_set.end_group^;

done_3d:                               {jump here to skip over 3D primitives}
{
*   All done with 3D primitives.
}
  if ray_on then begin                 {ray tracing ?}
    ray_saved := true;                 {all primitives now saved for ray tracing}
    rend_set.ray_save^ (false);
    ix := round(clip_master.x1);       {make coor of top left pixel in master clip}
    iy := round(clip_master.y1);
    rend_set.cpnt_2dimi^ (ix, iy);     {go to top left corner of master clip region}
    rend_prim.ray_trace_2dimi^ (       {ray trace the master clip rectangle}
      round(clip_master.x2) - ix,
      round(clip_master.y2) - iy);
    end;

  if comments.n > 0 then begin         {user supplied comments ?}
    rend_set.zon^ (false);             {shut off the Z buffer}
    rend_set.iterp_on^ (rend_iterp_z_k, false);
    rend_set.rgb^ (1.0, 1.0, 1.0);     {set color}
    rend_set.force_sw_update^ (force_sw); {done doing read-modify-write operations}
    rend_test_comment_draw;            {draw comment string, if given}
    end;

  rend_test_clip_all_off;              {turn off master clip, if there was any}

  if rend_test_refresh then goto redraw;
  end.
