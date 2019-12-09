{   Program TEST_SHADE [<options>]
*
*   Test RENDlib shading.  Command line options are:
*
*   -EMIS weight
*   -DIFF weight
*   -SPEC weight
*
*     Set the weighting factor for the emissive, diffuse, and specular surface
*     properties, respectively.  If the weighting factor is exactly zero, then
*     that surface property is shut off.
*
*   -SPEXP exp
*
*     Set the specular exponent.  The default is 15.
*
*   -OPAC front side
*
*     Set object opacity fraction.  Opacity of 0 is totally transparent, and
*     1 is totally opaque.  The FRONT value applies when the object surface
*     is directly facing the eye point.  The SIDE value applies when it is
*     facing at right angle to the eye point.  intermediate angles are interpolated
*     appropriately.  The default is -OPAC 1 1 (everything totally opaque).
*
*     NOTE:  The object polygons are not sorted, so transparent objects will
*     not be drawn correctly with Z buffering.  The -OPAC option is intended
*     to test the ray tracer variable transparency.
*
*   -ROD
*
*     Draw a rod piercing the sphere.  The rod will always be drawn using
*     Z buffering, even if the -RAY command line option is specified.
*     This is intended to test Z correspondance bewteen the ray tracer
*     and the Z buffer renderer.
*
*   -RAY_ROD
*
*     Draw the rod using ray tracing.  This option implies -ROD.  The default
*     is to draw the rod using Z buffering, even when -RAY is specified.
}
program "gui" test_shade;
%include 'rend_test_all.ins.pas';

const
  radius = 0.80;                       {sphere radius}
  border_sph = 0.15;                   {between sphere and top and right image sides}
  border_txt = 0.10;                   {between text and bottom and left image sides}
  rod_dirx = -0.65;                    {rod direction only from sphere center}
  rod_diry = 0.40;
  rod_dirz = -0.60;
  rod_len = 1.50;                      {rod length from sphere center to one end}
  rod_rad = 0.20;                      {rod radius relative to sphere's}
  text_size = 0.07;
  max_msg_parms = 6;                   {max parameters we can pass to a message}

var
  emis: rend_rgb_t;                    {emissive color}
  diff: rend_rgb_t;                    {diffuse color}
  spec: rend_rgb_t;                    {specular color}
  spec_exp: real;                      {specular exponent}
  emis_wat, diff_wat, spec_wat: real;  {weighting factors for surface properties}
  opac_front, opac_side: real;         {opacity fractions}
  rod_dx, rod_dy, rod_dz: real;        {rod end displacement from sphere center}
  m: real;                             {scratch mult factor}
  old_width, old_height: sys_int_machine_t; {image size last time picture drawn}
  ix, iy: sys_int_machine_t;           {scratch integer coordinates}
  opac_on: boolean;                    {TRUE if using variable opacity}
  rod_on: boolean;                     {TRUE on -ROD command line option}
  ray_rod: boolean;                    {draw rod using ray tracing when TRUE}
  ray_sphere: boolean;                 {draw sphere using ray tracing when TRUE}
  ray_any: boolean;                    {TRUE if any ray tracing is done}
  read_sw: boolean;                    {TRUE if triangle prim read from bitmap}
  ray_saved: boolean;                  {TRUE if ray tracing prims already saved}
  p1: vect_2d_t;                       {for dummy 2D interpolation anchor point}
  sph: vect_3d_t;                      {sphere center coordinate}
  ray_xmin, ray_xmax,                  {bounding box used by ray tracer}
  ray_ymin, ray_ymax,
  ray_zmin, ray_zmax:
    real;
  tparms: rend_text_parms_t;           {text control parameters}
  txt:                                 {for drawing text}
    %include '(cog)lib/string80.ins.pas';

  pick: sys_int_machine_t;             {number of token picked from list}
  opt,                                 {command line option name}
  parm:                                {command line option parameter}
    %include '(cog)lib/string32.ins.pas';
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {device independent error code}

label
  next_opt, parm_err, done_opts, redraw;
{
*******************************************************************
*
*   Internal subroutine SUPROP_SPHERE
*
*   Set the current surface properties for drawing the sphere.
}
procedure suprop_sphere;

begin
  rend_set.suprop_all_off^;            {init all surface properties to OFF}

  if emis_wat <> 0.0 then begin        {emissive turned ON ?}
    rend_set.suprop_emis^ (emis.red, emis.grn, emis.blu);
    end;

  if diff_wat <> 0.0 then begin        {diffuse turned ON ?}
    rend_set.suprop_diff^ (diff.red, diff.grn, diff.blu);
    end;

  if spec_wat <> 0.0 then begin        {specular turned ON ?}
    rend_set.suprop_spec^ (spec.red, spec.grn, spec.blu, spec_exp);
    end;

  if opac_on
    then begin                         {variable transparency ON ?}
      rend_set.suprop_trans^ (opac_front, opac_side);
      rend_set.iterp_on^ (rend_iterp_alpha_k, true);
      rend_set.alpha_func^ (rend_afunc_over_k);
      rend_set.alpha_on^ (true);
      end
    else begin                         {variable transparency is OFF ?}
      rend_set.iterp_on^ (rend_iterp_alpha_k, false);
      rend_set.alpha_on^ (false);
      end
    ;
  end;
{
*******************************************************************
*
*   Internal subroutine SUPROP_ROD
*
*   Set the current surface properties for drawing the rod.
}
procedure suprop_rod;

begin
  rend_set.suprop_all_off^;            {init all surface properties to OFF}
  rend_set.suprop_diff^ (0.9, 0.9, 0.9);
  rend_set.suprop_spec^ (0.2, 0.2, 0.2, 15.0);
  rend_set.iterp_on^ (rend_iterp_alpha_k, false);
  rend_set.alpha_on^ (false);
  end;
{
*******************************************************************
*
*   Start of main routine.
}
begin
  m := rod_len / sqrt(sqr(rod_dirx) + sqr(rod_diry) + sqr(rod_dirz));
  rod_dx := m * rod_dirx;              {make scaled rod end displacement}
  rod_dy := m * rod_diry;
  rod_dz := m * rod_dirz;

  emis.red := 0.90;                    {default emissive color}
  emis.grn := 0.20;
  emis.blu := 1.00;
  emis_wat := 0.0;

  diff.red := 1.00;                    {default diffuse color}
  diff.grn := 0.80;
  diff.blu := 0.20;
  diff_wat := 0.90;

  spec.red := 1.00;                    {default specular color}
  spec.grn := 1.00;
  spec.blu := 1.00;
  spec_wat := 0.15;
  spec_exp := 15.0;

  opac_front := 1.0;                   {default opacities}
  opac_side := 1.0;
  opac_on := false;

  rend_test_cmline ('TEST_SHADE');     {process canned command line args}
  if not set_bits_vis then begin       {-BITS_VIS not explicitly set ?}
    bits_vis := 24.0;                  {default to maximum color resolution}
    set_bits_vis := true;
    end;
  rod_on := false;
  ray_rod := false;
{
*   Back here for each new command line option.
}
next_opt:
  rend_test_cmline_token (opt, stat);  {get next command line option name}
  if string_eos(stat) then goto done_opts; {nothing more on command line ?}
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (                    {pick option name from list}
    opt,                               {option name}
    '-EMIS -DIFF -SPEC -SPEXP -ROD -OPAC -RAY_ROD',
    pick);                             {number of picked option}
  case pick of                         {do routine for specific option}
{
*   -EMIS weight
}
1: begin
  emis_wat := rend_test_cmline_fp (stat);
  end;
{
*   -DIFF weight
}
2: begin
  diff_wat := rend_test_cmline_fp (stat);
  end;
{
*   -SPEC weight
}
3: begin
  spec_wat := rend_test_cmline_fp (stat);
  end;
{
*   -SPEXP exp
}
4: begin
  spec_exp := rend_test_cmline_fp (stat);
  end;
{
*   -ROD
}
5: begin
  rod_on := true;
  end;
{
*   -OPAC front side
}
6: begin
  opac_front := rend_test_cmline_fp (stat);
  if sys_error(stat) then goto parm_err;
  opac_side := rend_test_cmline_fp (stat);
  opac_on := true;
  end;
{
*   -RAY_ROD
}
7: begin
  rod_on := true;
  ray_rod := true;
  end;
{
*   Illegal command line option.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_bad', msg_parm, 1);
    end;                               {end of command line option cases}
  if not sys_error(stat) then goto next_opt;
parm_err:
  sys_msg_parm_vstr (msg_parm[1], cmline.str_p^);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);

done_opts:                             {done with all the command line options}
  ray_sphere := ray_on;                {sphere obeys -RAY command line switch}
  ray_any := ray_sphere or ray_rod;    {TRUE if anything is ray traced}
{
*   Done processing the command line options.
}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k,
      rend_test_comp_z_k]
    );
{
*   Do other RENDlib initialization.
}
  rend_set.zfunc^ (rend_zfunc_gt_k);   {set Z compare function}
  rend_set.dev_z_curr^ (true);         {pretend Z buffer is up to date}
  rend_set.backface^ (rend_bface_front_k); {draw only front of polygons}

  rend_set.z_range^ (1.1, -1.1);       {set object Z limits in 3D world space}
  rend_set.z_clip^ (1.1, -1.1);
  rend_set.new_view^;                  {done changing view parameters}

  emis.red := emis.red * emis_wat;     {make final emissive colors}
  emis.grn := emis.grn * emis_wat;
  emis.blu := emis.blu * emis_wat;

  diff.red := diff.red * diff_wat;     {make final diffuse colors}
  diff.grn := diff.grn * diff_wat;
  diff.blu := diff.blu * diff_wat;

  spec.red := spec.red * spec_wat;     {make final specular colors}
  spec.grn := spec.grn * spec_wat;
  spec.blu := spec.blu * spec_wat;
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
  if rend_iterp_alpha_k in rend_get.iterps_on_set^
    then rend_set.iterp_linear^ (rend_iterp_alpha_k, p1, 0.1, 0.1, 0.1);
  rend_set.zon^ (true);                {enable Z compares}
  suprop_sphere;                       {set surface properties of sphere}
  rend_set.ray_save^ (ray_sphere);
  rend_set.start_group^;
  read_sw := rend_test_tri_reading_sw; {does prim require current SW bitmap ?}
  rend_set.end_group^;
  rend_set.ray_save^ (false);
  if rod_on and (not read_sw) then begin {need to test rod separately ?}
    suprop_rod;                        {set surface properties of the rod}
    rend_set.ray_save^ (ray_rod);
    rend_set.start_group^;
    read_sw := rend_test_tri_reading_sw; {does prim require current SW bitmap ?}
    rend_set.end_group^;
    rend_set.ray_save^ (false);
    end;
  rend_set.force_sw_update^ (force_sw or read_sw); {force SW emulation if necessary}
  ray_saved := false;                  {init to no primitives saved for ray tracing}

redraw:                                {back here to redraw image}
  sph.x := width_2d - border_sph - radius; {make sphere center coordinate}
  sph.y := height_2d - border_sph - radius;
  sph.z := 0.0;
{
*   Clear the background and do common init.
}
  rend_set.iterp_on^ (rend_iterp_z_k, true);
  rend_set.rgb^ (0.15, 0.15, 0.60);    {set background color}
  rend_set.iterp_flat^ (rend_iterp_z_k, -1.0);
  rend_set.zon^ (false);               {disable Z compares for background clear}
  rend_set.iterp_on^ (rend_iterp_alpha_k, false); {turn off alpha interpolant}
  rend_set.alpha_on^ (false);          {turn off alpha buffering}
  rend_prim.clear_cwind^;              {draw background}
  rend_set.zon^ (true);                {enable Z compares}
{
*   Draw the rod, if enabled.
}
  if                                   {need to draw the rod now ?}
      rod_on and                       {rod is enabled ?}
      (not (ray_rod and ray_saved))    {not already saved for ray tracing ?}
      then begin
    suprop_rod;                        {set surface properties for the rod}
    rend_test_colors_wire;             {set colors for wire frame, if needed}
    rend_set.cpnt_3d^ (                {go to first end of rod}
      sph.x + (rod_dx * radius),
      sph.y + (rod_dy * radius),
      sph.z + (rod_dz * radius));
    rend_set.ray_save^ (ray_rod);
    ray_on := ray_rod;                 {tell REND_TEST library whether ray tracing}
    rend_set.start_group^;
    rend_test_cyl (                    {draw the cylender}
      -2.0 * rod_dx * radius,          {X displacement to other end}
      -2.0 * rod_dy * radius,          {Y displacement to other end}
      -2.0 * rod_dz * radius,          {Z displacement to other end}
      rod_rad * radius,                {rod radius}
      rend_test_cap_sph_k,             {start cap}
      rend_test_cap_sph_k);            {end cap}
    rend_set.end_group^;
    rend_set.ray_save^ (false);
    ray_on := false;                   {indicate no longer in ray tracing mode}
    end;
{
*   Draw the sphere.
}
  if not (ray_sphere and ray_saved) then begin {not already saved for ray tracing ?}
    suprop_sphere;                     {set surface properties for the sphere}
    rend_set.cpnt_3d^ (sph.x, sph.y, sph.z); {go to sphere center}
    rend_set.ray_save^ (ray_sphere);
    ray_on := ray_sphere;              {tell REND_TEST library whether ray tracing}
    rend_test_colors_wire;             {set colors for wire frame, if needed}
    rend_set.start_group^;
    rend_test_sphere (radius);         {draw the sphere}
    rend_set.end_group^;
    rend_set.ray_save^ (false);
    ray_on := false;                   {indicate no longer in ray tracing mode}
    end;
{
*   Ray trace all the primitives that have been saved for that purpose so far.
}
  if ray_any then begin                {there is something to ray trace ?}
    ray_saved := true;                 {all primitives now saved for ray tracing}
    ix := round(clip_master.x1);       {make coor of top left pixel in master clip}
    iy := round(clip_master.y1);
    rend_set.cpnt_2dimi^ (ix, iy);     {go to top left corner of master clip region}
    rend_prim.ray_trace_2dimi^ (       {ray trace the master clip rectangle}
      round(clip_master.x2) - ix,
      round(clip_master.y2) - iy);
    end;
{
*   Draw the text.
}
  rend_set.zon^ (false);               {shut off the Z buffer}
  rend_set.alpha_on^ (false);          {disable alpha buffering}
  rend_set.iterp_on^ (rend_iterp_z_k, false);
  rend_set.iterp_on^ (rend_iterp_alpha_k, false);
  rend_set.rgb^ (1.0, 1.0, 1.0);       {test color}
  rend_set.force_sw_update^ (force_sw); {done doing read-modify-write operations}

  rend_get.text_parms^ (tparms);       {set up text to our liking}
  tparms.coor_level := rend_space_2d_k;
  tparms.size := text_size;
  tparms.width := 0.70;
  tparms.height := 1.0;
  tparms.slant := 0.0;
  tparms.rot := 0.0;
  tparms.lspace := 1.0;
  tparms.start_org := rend_torg_ll_k;
  tparms.end_org := rend_torg_up_k;
  tparms.vect_width := 0.13;
  tparms.poly := true;
  rend_set.text_parms^ (tparms);

  rend_set.cpnt_2d^ (                  {set lower left corner of text block}
    -width_2d + border_txt,            {X coordinate}
    -height_2d + border_txt);          {Y coordinate}

  string_list_pos_last (comm_p^);      {position to last image file comment}

  if spec_wat > 0.001 then begin       {we are using specular color ?}
    string_f_fp_fixed (                {make percent value number}
      txt,                             {output string}
      spec_wat * 100.0,                {input value}
      0);                              {number of digits to right of decimal point}
    if spec_exp <= 500.0
      then begin                       {normal specular reflection}
        string_appends (txt, '% Specular, exponent =');
        string_append1 (txt, ' ');
        string_f_fp_fixed (            {make specular exponent value string}
          parm,                        {output string}
          spec_exp,                    {input value}
          0);                          {number of digits to right of decimal point}
        string_append (txt, parm);
        end
      else begin                       {mirror reflection}
        string_appends (txt, '% Mirror reflection.');
        end
      ;
    if comments.n <= 0                 {user didn't supply his own comment ?}
      then rend_prim.text^ (txt.str, txt.len); {draw the whole text string}
    string_list_line_add (comm_p^);
    string_appendn (comm_p^.str_p^, '  ', 2);
    string_append (comm_p^.str_p^, txt);
    end;

  if diff_wat > 0.001 then begin       {we are using diffuse color ?}
    string_f_fp_fixed (                {make percent value number}
      txt,                             {output string}
      diff_wat * 100.0,                {input value}
      0);                              {number of digits to right of decimal point}
    string_appends (txt, '% Diffuse');
    if comments.n <= 0                 {user didn't supply his own comment ?}
      then rend_prim.text^ (txt.str, txt.len); {draw the whole text string}
    string_list_pos_rel (comm_p^, -1); {create new comment line before curr}
    string_list_line_add (comm_p^);
    string_appendn (comm_p^.str_p^, '  ', 2);
    string_append (comm_p^.str_p^, txt);
    end;

  if emis_wat > 0.001 then begin       {we are using emissive color ?}
    string_f_fp_fixed (                {make percent value number}
      txt,                             {output string}
      emis_wat * 100.0,                {input value}
      0);                              {number of digits to right of decimal point}
    string_appends (txt, '% Emissive');
    if comments.n <= 0                 {user didn't supply his own comment ?}
      then rend_prim.text^ (txt.str, txt.len); {draw the whole text string}
    string_list_pos_rel (comm_p^, -1); {create new comment line before curr}
    string_list_line_add (comm_p^);
    string_appendn (comm_p^.str_p^, '  ', 2);
    string_append (comm_p^.str_p^, txt);
    end;

  string_list_pos_last (comm_p^);      {to last image comment line}
  string_list_line_add (comm_p^);      {make new last comment line}
  string_appends (comm_p^.str_p^, '  Cirres =');
  string_append1 (comm_p^.str_p^, ' ');
  string_f_int (parm, cirres1);
  string_append (comm_p^.str_p^, parm);

  string_list_pos_last (comments);     {go to last user comment line, if any}
  while comments.str_p <> nil do begin {once for each user comment line}
    rend_prim.text^ (comments.str_p^.str, comments.str_p^.len); {draw comment line}
    string_list_pos_rel (comments, -1); {go to previous comment line}
    end;

  old_width := image_width;            {save image size when image last drawn}
  old_height := image_height;

  if ray_any then begin                {save ray tracer's bounding box, if used}
    rend_get.ray_bounds_3dw^ (         {get bounding box used for ray tracing}
      ray_xmin, ray_xmax,
      ray_ymin, ray_ymax,
      ray_zmin, ray_zmax,
      stat);
    rend_error_abort (stat, '', '', nil, 0);
    end;

  if rend_test_refresh then begin      {need to redraw image ?}
    if                                 {object positions changed within picture ?}
        (image_width <> old_width) or
        (image_height <> old_height)
        then begin
      rend_set.ray_delete^;            {delete any ray primitives at old coordinates}
      ray_saved := false;              {no longer anything saved for ray tracing}
      end;
    goto redraw;
    end;
{
*   Show ray tracer bounding box, if used.
}
  if ray_any then begin
    sys_msg_parm_real (msg_parm[1], ray_xmin);
    sys_msg_parm_real (msg_parm[2], ray_xmax);
    sys_msg_parm_real (msg_parm[3], ray_ymin);
    sys_msg_parm_real (msg_parm[4], ray_ymax);
    sys_msg_parm_real (msg_parm[5], ray_zmin);
    sys_msg_parm_real (msg_parm[6], ray_zmax);
    sys_message_parms ('rend_test', 'ray_bounds', msg_parm, 6);
    end;
  end.
