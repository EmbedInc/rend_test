{   Test for the ray tracer thru RENDlib.
}
program "gui" test_ray;
%include 'rend_test_all.ins.pas';

const
  rad = 0.90;                          {sphere radius}
  max_msg_parms = 2;                   {max parameters we can pass to a message}

var
  light1, light2, light3: rend_light_handle_t; {handle to our light sources}
  ix, iy: sys_int_machine_t;           {scratch integer pixel coordinates}
  ray_saved: boolean;                  {TRUE if ray tracing prims already saved}

  opt:                                 {command line option name}
    %include '(cog)lib/string32.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {device independent error code}

label
  next_opt, done_opts, redraw;

begin
  rend_test_cmline ('TEST_3D');        {read standard command line options}
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
    '',
    pick);                             {number of picked option}
  case pick of                         {do routine for specific option}
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
      rend_test_comp_blu_k]
    );
  rend_set.backface^ (rend_bface_front_k); {draw only front of polygons}
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

  ray_saved := false;                  {no primitives saved for ray tracing yet}
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
  rend_prim.clear_cwind^;              {draw background}
  rend_prim.flush_all^;                {force all cached drawing to the device}
{
*   Make sure the 3D primitives have been saved.
}
  if not ray_saved then begin          {3D primitives not already saved ?}
    rend_set.ray_save^ (true);         {start saving primitives for ray tracing}

    rend_set.suprop_all_off^;          {init all surface properties to OFF}
    rend_set.suprop_diff^ (0.75, 0.75, 0.85);
    rend_set.suprop_spec^ (0.25, 0.25, 0.25, 31.0);

    rend_test_colors_wire;             {set up wire frame colors, if needed}
    rend_set.cpnt_3d^ (0.0, 0.0, 0.0); {go to sphere center}
    rend_test_sphere (rad);            {draw the sphere}

    rend_set.ray_save^ (false);        {done saving primitives for ray tracing}
    ray_saved := true;                 {remember that 3D primitives have been saved}
    end;
{
*   Draw the ray traced primitives.
}
  ix := round(clip_master.x1);         {make coor of top left pixel in master clip}
  iy := round(clip_master.y1);
  rend_set.cpnt_2dimi^ (ix, iy);       {go to top left corner of master clip region}

  rend_prim.ray_trace_2dimi^ (         {ray trace the master clip rectangle}
    round(clip_master.x2) - ix,
    round(clip_master.y2) - iy);

  rend_prim.flush_all^;                {force all cached drawing to the device}
{
*   Draw any comments as a 2D overlay.
}
  if comments.n > 0 then begin         {user supplied comments ?}
    rend_set.rgb^ (1.0, 1.0, 1.0);     {set color}
    rend_test_comment_draw;            {draw comment string, if given}
    end;

  rend_test_clip_all_off;              {turn off master clip, if there was any}
  if rend_test_refresh then goto redraw; {wait for event, either redraw or exit}
  end.
