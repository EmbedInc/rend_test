{   WARNING: This program is very old and uses Apollo system calls to get
*   keyboard events.  It needs to be converted to using RENDlib event.
}

{   Program TEST_TUBESEG
*
*   Test the RENDlib TUBESEG primitive.  Command line options are:
*
*   -CAP1 style
*   -CAP2 style
*
*     Set endcap styles for each end.  Valid style names are:
*
*       NONE
*       FLAT
*
*     The default is NONE.
}
program "gui" test_tubeseg;
%include 'rend_test_all.ins.pas';

const
  rot_increment = 0.05;                {rotation factor increment per key stroke}
  trans_increment = 0.1;               {translation per keystroke}
  min_bits_vis_req = 12.0;             {min visible bits per pixel even if SW emul}
  trans_px_key = kbd_$lcs;             {define which keys cause translation}
  trans_mx_key = kbd_$las;
  trans_py_key = kbd_$l8s;
  trans_my_key = kbd_$les;
  trans_pz_key = kbd_$lfs;
  trans_mz_key = kbd_$lds;
  quit_key1 = 'q';
  quit_key2 = kbd_$exit;
  reset_key = kbd_$f0;
  clear_on_toggle_key = kbd_$f1;
  update_on_toggle_key = kbd_$f2;
  max_msg_parms = 4;                   {number of parameters we can pass to messages}

  pi = 3.141593;                       {what it sounds like, don't touch}
  deg_rad = pi/180.0;                  {mult factor to convert degrees to radians}

var
  pix_x, pix_y: sys_int_machine_t;     {temp image size in pixels}
  i, j: sys_int_machine_t;             {scratch integers and loop counters}
  cxb, cyb, czb, cofs: vect_3d_t;      {local copy of current xform matrix}
  tp1, tp2: rend_tube_point_t;         {points for start/end of tube segment}
  c_p: ^char;                          {used for reading in key stroke}
  m: real;                             {mult factor for unitizing vector}
  p2d: vect_2d_t;                      {scratch 2D vector/point}
  gpr_event: gpr_$event_t;             {ID for what type of event occurred}
  gpr_data: char;                      {key or button ID character}
  gpr_pos: gpr_$position_t;            {X,Y position of GPR event}
  coor1, coor2: vect_3d_t;             {coordinates of tube end points}
  max_buf: sys_int_machine_t;          {max hardware buffer of double buffering}
  vect_parms: rend_vect_parms_t;       {vector drawing parameters}
  sw_on: boolean;                      {TRUE if tubeseg uses SW emulation}
  read_sw, write_sw: boolean;          {scratch flags}
  cap_style1, cap_style2: rend_tbcap_k_t; {end cap styles}
  on: boolean;                         {scratch boolean flag}
  clear_on: boolean;                   {TRUE if clear image before redraw}
  update_on: boolean;                  {TRUE if update image on REDRAW call}
  entered: boolean;                    {TRUE if ENTER_REND_COND succeeded}
  cmode_vals: rend_cmode_vals_t;       {save area for changeable modes}
  window_handle1: stream_$id_t;        {stream ID for graphics window region}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {system independent error code}
  stat2: sys_err_t;                    {second status code to avoid corrupting STAT}

  opt,                                 {command line option name}
  parm:                                {command line option parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}

label
  next_opt, parm_err, done_opts,
  min_bits_loop, done_min_bits, cmd_loop, new_xform, done_cmd_loop;
{
**************************************************************************************
*
*   Local subroutine ROTATE (RX,RY,RZ)
*
*   Rotate the current 3D transformation small incremental amounts about X, Y, and
*   Z in world coordinate space.  An incremental rotation matrix will be created
*   and then post-multiplied by the current transformation.  This result will become
*   the new current 3D transformation.
}
procedure rotate (
  in      rx, ry, rz: real);           {small rotation values about each axis}

var
  xbx, xby, xbz: real;                 {scratch matrix X basis vector}
  ybx, yby, ybz: real;                 {scratch matrix Y basis vector}
  zbx, zby, zbz: real;                 {scratch matrix Z basis vector}
  xb, yb, zb, ofs: vect_3d_t;          {new absolute matrix}
  m: real;                             {mult factor for unitizing a vector}

begin
{
*   Conceptually, we will first create a matrix with the small rotation increments
*   just added to each of the basis vectors in the appropriate places.  This matrix
*   would look like this:
*
*     XB = (   1,  rz, -ry)
*     YB = ( -rz,   1,  rx)
*     ZB = (  ry, -rx,   1)
*
*   However, this matrix is not necessarily orthogonal and of unit size.  To get
*   this, we will first make a new Z vector from XBxYB, and then a new Y vector
*   from ZBxXB.  The vectors are then guaranteed to be orthogonal.  These vectors
*   are unitized to form the final incremental rotation matrix.
}
  zbx := rz*rx + ry;                   {make new Z vector from XB x YB}
  zby := ry*rz - rx;
  zbz := 1.0 + sqr(rz);
  m := 1.0/sqrt(sqr(zbx)+sqr(zby)+sqr(zbz)); {mult factor for unitizing ZB}
  zbx := zbx*m;                        {make final unit Z basis vector}
  zby := zby*m;
  zbz := zbz*m;

  ybx := -zby*ry - zbz*rz;             {make new Y vector from ZB x XB}
  yby := zbz + zbx*ry;
  ybz := zbx*rz - zby;
  m := 1.0/sqrt(sqr(ybx)+sqr(yby)+sqr(ybz)); {mult factor for unitizing YB}
  ybx := ybx*m;                        {make final unit Y basis vector}
  yby := yby*m;
  ybz := ybz*m;

  m := 1.0/sqrt(1.0 + sqr(rz) + sqr(ry)); {mult factor for unitizing XB}
  xbx := m;
  xby := rz*m;
  xbz := -m*ry;
{
*   The final incremental rotation matrix is all set.  The vectors are orthogonal
*   and of unit length.  Now post-multiply this new matrix to the existing matrix
*   to create the new absolute rotation matrix.
}
  xb.x := cxb.x*xbx + cxb.y*ybx + cxb.z*zbx;
  xb.y := cxb.x*xby + cxb.y*yby + cxb.z*zby;
  xb.z := cxb.x*xbz + cxb.y*ybz + cxb.z*zbz;

  yb.x := cyb.x*xbx + cyb.y*ybx + cyb.z*zbx;
  yb.y := cyb.x*xby + cyb.y*yby + cyb.z*zby;
  yb.z := cyb.x*xbz + cyb.y*ybz + cyb.z*zbz;

  zb.x := czb.x*xbx + czb.y*ybx + czb.z*zbx;
  zb.y := czb.x*xby + czb.y*yby + czb.z*zby;
  zb.z := czb.x*xbz + czb.y*ybz + czb.z*zbz;

  ofs.x := cofs.x*xbx + cofs.y*ybx + cofs.z*zbx;
  ofs.y := cofs.x*xby + cofs.y*yby + cofs.z*zby;
  ofs.z := cofs.x*xbz + cofs.y*ybz + cofs.z*zbz;
{
*   The new absolute transformation matrix is in the local variables
*   XB, YB, ZB and OFS.  Now copy this into our saved copy of the 3D transform and
*   send it to RENDlib.
}
  cxb := xb;
  cyb := yb;
  czb := zb;
  cofs := ofs;
  rend_set.xform_3d^ (cxb, cyb, czb, cofs);
  rend_set.new_view^;
  end;
{
**************************************************************************************
*
*   Local subroutine SET_BUF_CLEAR
*
*   Set up all the state ready for clearing the current drawing buffer.  Nothing
*   is actually written to the pixels.
}
procedure set_buf_clear;

var
  p1, p2, p3: vect_2d_t;               {scratch 2D vectors}

begin
  rend_set.zon^ (false);
  p1.x := 0.0; p1.y := 0.0;
  p2.x := 0.0; p2.y := image_height;
  p3.x := image_width; p3.y := image_height;
  rend_set.lin_geom_2dim^ (p1, p2, p3);
  rend_set.lin_vals^ (rend_iterp_red_k, 0.5, 0.1, 0.1);
  rend_set.lin_vals^ (rend_iterp_grn_k, 0.5, 0.1, 0.1);
  rend_set.lin_vals^ (rend_iterp_blu_k, 0.5, 0.1, 0.1);
  rend_set.iterp_flat^ (rend_iterp_z_k, -1.0);
  end;
{
**************************************************************************************
*
*   Local subroutine REDRAW
*
*   Cause all our graphics to be redrawn.  The current displayed image is completely
*   overwritten.
}
procedure redraw;

begin
  rend_set.enter_rend^;

  if not update_on then begin          {not supposed to update the display ?}
    rend_set.exit_rend^;
    return;
    end;

  if clear_on and (max_buf <= 1) then begin {clear image before redraw ?}
    set_buf_clear;                     {set state ready for clearing buffer}
    rend_prim.clear_cwind^;            {clear the current drawing buffer}
    end;

  rend_set.iterp_shade_mode^ (
    rend_iterp_red_k, rend_iterp_mode_linear_k);
  rend_set.iterp_shade_mode^ (
    rend_iterp_grn_k, rend_iterp_mode_linear_k);
  rend_set.iterp_shade_mode^ (
    rend_iterp_blu_k, rend_iterp_mode_linear_k);
  rend_set.shade_geom^ (rend_iterp_mode_linear_k);
  rend_set.zon^ (true);

  rend_set.start_group^;
  rend_prim.tubeseg_3d^ (tp1, tp2, cap_style1, cap_style2);
  rend_set.end_group^;

  if clear_on and (max_buf > 1) then begin {clear image and swap bufs after drawing ?}
    set_buf_clear;                     {set all state ready for clearing buffer}
    rend_prim.flip_buf^;               {flip buffers and clear new draw buf}
    end;

  rend_set.exit_rend^;
  end;
{
****************************************************************************
*
*   Internal subroutine NEXT_TOKEN (S,STAT)
*
*   Return the next token from the command line in the variable length
*   string S.
}
procedure next_token (
  in out  s: univ string_var_arg_t;    {returned command line token}
  out     stat: sys_err_t);

begin
  sys_error_none (stat);
  if cmline.curr >= cmline.n then begin {got to end of strings list ?}
    sys_stat_set (string_subsys_k, string_stat_eos_k, stat);
    s.len := 0;
    return;                            {return with END OF STRING status}
    end;
  string_list_pos_rel (cmline, 1);     {advance to new token in strings list}
  string_copy (cmline.str_p^, s);      {return token string}
  end;
{
**************************************************************************************
*
*   Start of main routine.
}
begin
  sys_error_none (stat);               {init to no error indicated}
  rend_test_cmline ('TEST_TUBSEG');    {process canned command line args}
  cap_style1 := rend_tbcap_none_k;
  cap_style2 := rend_tbcap_none_k;
{
*   Back here for each new command line option.
}
next_opt:
  next_token (opt, stat);              {get next command line option name}
  if string_eos(stat) then goto done_opts; {nothing more on command line ?}
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (                    {pick option name from list}
    opt,                               {option name}
    '-CAP1 -CAP2',
    pick);                             {number of picked option}
  case pick of                         {do routine for specific option}
{
*   -CAP1 style
}
1: begin
  next_token (parm, stat);
  if sys_error(stat) then goto parm_err;
  string_upcase (parm);
  string_tkpick80 (
    parm,
    'NONE FLAT',
    pick);
  case pick of
1: cap_style1 := rend_tbcap_none_k;
2: cap_style1 := rend_tbcap_flat_k;
otherwise
    goto parm_err;
    end;
  end;
{
*   -CAP2 style
}
2: begin
  next_token (parm, stat);
  if sys_error(stat) then goto parm_err;
  string_upcase (parm);
  string_tkpick80 (
    parm,
    'NONE FLAT',
    pick);
  case pick of
1: cap_style2 := rend_tbcap_none_k;
2: cap_style2 := rend_tbcap_flat_k;
otherwise
    goto parm_err;
    end;
  end;
{
*   Illegal command line option.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_bad', msg_parm, 1);
    end;                               {end of command line option cases}
  goto next_opt;                       {back for next command line option}

parm_err:                              {error reading parameter to with parm content}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_parms ('string', 'cmline_parm_bad', msg_parm, 2);
  sys_error_print (stat, '', '', nil, 0); {print any additional info in STAT}
  sys_bomb;

done_opts:                             {done with all the command line options}
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

  rend_get.xform_3d^ (cxb, cyb, czb, cofs); {init our copy of 3D transform matrix}
  rend_set.backface^ (rend_bface_front_k);
  rend_set.new_view^;
  rend_set.vert3d_ent_all_off^;
  rend_set.vert3d_ent_on^ (            {enable XYZ coordinate pointer in vert desc}
    rend_vert3d_coor_p_k,
    0);                                {byte offset into vertex descriptor}
  rend_set.vert3d_ent_on^ (            {enable shading normal pointer in vert desc}
    rend_vert3d_norm_p_k,
    sizeof(univ_ptr));                 {byte offset into vertex descriptor}
  rend_set.vert3d_ent_on^ (            {enable shading normal pointer in vert desc}
    rend_vert3d_vcache_p_k,
    sizeof(univ_ptr)*2);               {adr offset into vertex descriptor}

  clear_on := true;                    {init to clear image before redraw}
  update_on := true;                   {init to update image on REDRAW call}
  sw_on := force_sw;                   {SW emulation will be used if forced ON}
{
*   Set up the tube endpoint descriptor for end 1.
}
  tp1.coor_p := addr(coor1);
  coor1.x := -0.5;
  coor1.y := 0.0;
  coor1.z := 0.0;

  tp1.xb.x := 0.02;
  tp1.xb.y := 0.0;
  tp1.xb.z := 0.3;

  tp1.yb.x := 0.0;
  tp1.yb.y := 0.5;
  tp1.yb.z := 0.0;

  rend_tbpoint_2d_3d (tp1);            {fill in full 3D xforms}

  tp1.xsec_p := nil;
  tp1.shade := rend_tblen_shade_facet_k;
  tp1.rgba_p := nil;
  tp1.rad0 := false;
{
*   Set up the tube endpoint descriptor for end 2.
}
  tp2.coor_p := addr(coor2);
  coor2.x := 0.5;
  coor2.y := 0.0;
  coor2.z := 0.0;

  tp2.xb.x := -0.02;
  tp2.xb.y := 0.0;
  tp2.xb.z := 0.5;

  tp2.yb.x := 0.0;
  tp2.yb.y := 0.3;
  tp2.yb.z := 0.0;

  rend_tbpoint_2d_3d (tp2);            {fill in full 3D xforms}

  tp2.xsec_p := nil;
  tp2.shade := rend_tblen_shade_facet_k;
  tp2.rgba_p := nil;
  tp2.rad0 := false;
{
*   Set up "typical" state for drawing.  This will be used to test whether
*   software emulation is required.
}
  p2d.x := 0.0;
  p2d.y := 0.0;
  rend_set.iterp_linear^ (
    rend_iterp_red_k, p2d, 0.0, 0.1, 0.1);
  rend_set.iterp_linear^ (
    rend_iterp_grn_k, p2d, 0.0, 0.1, 0.1);
  rend_set.iterp_linear^ (
    rend_iterp_blu_k, p2d, 0.0, 0.1, 0.1);
  rend_set.iterp_shade_mode^ (         {set SHADE_MODE for RGB}
    rend_iterp_red_k, rend_iterp_mode_linear_k);
  rend_set.iterp_shade_mode^ (
    rend_iterp_grn_k, rend_iterp_mode_linear_k);
  rend_set.iterp_shade_mode^ (
    rend_iterp_blu_k, rend_iterp_mode_linear_k);
  rend_set.shade_geom^ (rend_iterp_mode_linear_k); {set shading geometry to match RGB mode}

  rend_set.dev_z_curr^ (true);         {pretend device Z buffer is up to date}
  rend_set.iterp_linear^ (             {set Z interpolant to linear interpolation}
    rend_iterp_z_k, p2d, 0.0, 0.1, 0.1);
  rend_set.iterp_shade_mode^ (         {set Z SHADE_MODE to linear}
    rend_iterp_z_k, rend_iterp_mode_linear_k);
{
*   Determine whether software emulation will be required for drawing the background.
*   This is only the case if the solid triangles read from the software bitmap, and
*   therefore assume it is up to date.
}
  if not force_sw then begin           {don't bother if know we need SW emulation}
    rend_set.zon^ (true);              {we will need to do Z buffering}
    rend_set.start_group^;
    rend_get.reading_sw_prim^ (        {find if TUBESEG_3D reads SW bitmap}
      rend_prim.tubeseg_3d,            {primitive to inquire about}
      force_sw);                       {TRUE if reads from SW bitmap}
    rend_get.update_sw_prim^ (         {find if TUBESEG_3D uses SW emulation}
      rend_prim.tubeseg_3d,            {primitive to inquire about}
      sw_on);                          {TRUE if SW emulation used}
    rend_set.end_group^;
    rend_get.cmode_vals^ (cmode_vals); {save changeable mode state here}
    end;
{
*   Now determine what buffer configuration we can get away with without forcing
*   software updates, unless already on.
}
  if set_bits_vis then goto done_min_bits; {used explicitly set color resolution ?}
  bits_vis := 24.0;
  rend_set.min_bits_vis^ (bits_vis);   {try for maximum color resolution}
  if sw_on
    then max_buf := 1                  {use single buffer if software emulation ON}
    else max_buf := 2;                 {try for double buffering if hardware drawing}
  rend_set.max_buf^ (max_buf);         {set initial buffers request}

  if not sw_on then begin              {hardware drawing possible ?}
min_bits_loop:                         {back here if curr BITS_VIS too high}
    rend_set.start_group^;
    rend_get.update_sw_prim^ (rend_prim.tubeseg_3d, on); {check SW emulation flag}
    rend_set.end_group^;
    if not on then goto done_min_bits; {BITS_VIS setting now not force SW updates ?}
    bits_vis := bits_vis - 1.0;        {try a little smaller BITS_VIS value}
    if bits_vis <= min_bits_vis_req then begin {degraded far enough ?}
      if max_buf > 1 then begin        {requesting more than one buffer ?}
        max_buf := 1;                  {two didn't work, try single buffering}
        bits_vis := 24.0;              {reset BITS_VIS request}
        goto min_bits_loop;            {back and try while requesting just 1 buffer}
        end;
      goto done_min_bits;              {all done setting MAX_BUF and BITS_VIS}
      end;
    rend_set.cmode_vals^ (cmode_vals); {reset to state before last test case}
    rend_set.min_bits_vis^ (bits_vis); {set to smaller BITS_VIS}
    rend_set.max_buf^ (max_buf);       {re-affirm max requested buffers}
    goto min_bits_loop;                {back and test this new BITS_VIS setting}
done_min_bits:                         {found setting for hardware drawing}
    end;                               {done setting BITS_VIS and number of buffers}

  rend_get.cmode_vals^ (cmode_vals);   {save changeable mode state here}
  rend_get.bits_vis^ (bits_vis);       {find out what we really ended up with}
  rend_get.max_buf^ (max_buf);
  rend_set.force_sw_update^ (force_sw); {force SW updates on, if necessary}
  rend_get.cmode_vals^ (cmode_vals);   {save changeable mode state here}
  rend_set.exit_rend^;
{
*   Set up keypad so that we can read the arrow keys.
}
  gpr_$enable_input (                  {enable all the keys/buttons we care about}
    gpr_$keystroke,                    {which type of event to enable}
    [ kbd_$up_arrow,
      kbd_$left_arrow,
      kbd_$right_arrow,
      kbd_$down_arrow,
      trans_px_key,
      trans_mx_key,
      trans_py_key,
      trans_my_key,
      trans_pz_key,
      trans_mz_key,
      reset_key,
      clear_on_toggle_key,
      update_on_toggle_key,
      quit_key1,
      quit_key2
      ],
    stat.sys);                         {system error return code}
  sys_error_abort (stat, 'rend', 'test_tubeseg_gpr_enable', nil, 0);
{
*   Configuration is now all decided.  Init the first displayed image.
}
  sys_error_none (stat);               {clear to indicate no error condition}
  rend_set.enter_rend^;
  rend_set.disp_buf^ (1);              {init to displaying first buffer}
  rend_set.draw_buf^ (2);              {draw into second buffer if double buf on}
  if max_buf > 1 then begin
    set_buf_clear;                     {set state ready for clearing buffer}
    rend_prim.clear_cwind^;            {clear current drawing buffer to background}
    end;
  rend_set.exit_rend^;
  redraw;                              {draw initial image}
{
*   Main loop.  Come back here to get each new command event.
}
cmd_loop:
  discard( gpr_$cond_event_wait (      {wait for next keystroke}
    gpr_event,                         {returned ID of this particular event type}
    gpr_data,                          {one char window or keystroke ID}
    gpr_pos,                           {XY position of event}
    stat.sys));                        {error return code}
  sys_error_abort (stat, 'rend', 'test_3dt_gpr_event', nil, 0);
  if gpr_event = gpr_$no_event then begin
    rend_set.enter_rend^;              {allow other GPR refresh events to come thru}
    rend_set.exit_rend^;
    sys_wait (0.25);
    goto cmd_loop;
    end;
  if gpr_event <> gpr_$keystroke then begin {this shouldn't happen}
    writeln (gpr_event);
    sys_wait (0.5);
    goto cmd_loop;
    end;
  case gpr_data of

kbd_$up_arrow: begin
      rotate (-rot_increment, 0.0, 0.0);
      redraw;
      end;

kbd_$left_arrow: begin
      rotate (0.0, -rot_increment, 0.0);
      redraw;
      end;

kbd_$right_arrow: begin
      rotate (0.0, rot_increment, 0.0);
      redraw;
      end;

kbd_$down_arrow: begin
      rotate (rot_increment, 0.0, 0.0);
      redraw;
      end;

trans_px_key: begin                    {translate in +X direction}
      cofs.x := cofs.x + trans_increment;
      if cofs.x > 0.9 then cofs.x := 0.9;
      goto new_xform;
      end;

trans_mx_key: begin                    {translate in -X direction}
      cofs.x := cofs.x - trans_increment;
      if cofs.x < -0.9 then cofs.x := -0.9;
      goto new_xform;
      end;

trans_py_key: begin                    {translate in +Y direction}
      cofs.y := cofs.y + trans_increment;
      if cofs.y > 0.9 then cofs.y := 0.9;
      goto new_xform;
      end;

trans_my_key: begin                    {translate in -Y direction}
      cofs.y := cofs.y - trans_increment;
      if cofs.y < -0.9 then cofs.y := -0.9;
      goto new_xform;
      end;

trans_pz_key: begin                    {translate in +Z direction}
      cofs.z := cofs.z + trans_increment;
      if cofs.z > 0.9 then cofs.z := 0.9;
      goto new_xform;
      end;

trans_mz_key: begin                    {translate in -Z direction}
      cofs.z := cofs.z - trans_increment;
      if cofs.z < -0.9 then cofs.z := -0.9;
      goto new_xform;
      end;

reset_key: begin                       {reset to initial transform}
      cxb.x := 1.0; cxb.y := 0.0; cxb.z := 0.0;
      cyb.x := 0.0; cyb.y := 1.0; cyb.z := 0.0;
      czb.x := 0.0; czb.y := 0.0; czb.z := 1.0;
      cofs.x := 0.0; cofs.y := 0.0; cofs.z := 0.0;
      rend_set.xform_3d^ (cxb, cyb, czb, cofs);
      redraw;
      end;

clear_on_toggle_key: begin             {toggle state of clear screen before redraw}
      clear_on := not clear_on;
      redraw;
      end;

update_on_toggle_key: begin            {toggle state of UPDATE_ON flag}
      update_on := not update_on;
      redraw;
      end;

quit_key1,                             {exit the program}
quit_key2:
    goto done_cmd_loop;

    end;                               {done with keystroke cases}

  goto cmd_loop;

new_xform:                             {local xform changed but not sent yet}
  rend_set.xform_3d^ (cxb, cyb, czb, cofs);
  redraw;
  goto cmd_loop;

done_cmd_loop:
{
**************************************************************************************
*
*   All done with graphics.  Clean up and leave.
}
  rend_end;
  end.
