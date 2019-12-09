{   WARNING: This program is very old and uses Apollo system calls to get
*   keyboard events.  It needs to be converted to using RENDlib event.
}

{   Program to test 3D TUBE primitives.
*
*   COMMAND LINE PARAMETERS:
*
*     -SCREEN
*
*       Use the entire screen for graphics.  The default is to use the current
*       window only.
*
*     -FLAT
*
*       Draw the tubes facet-shaded.  The default is smoothe shading.
*
*     -SIDES n
*
*       Set the number of sides to be used for the circular tube crossection.
*       The default is the RENDlib default if -FLAT also not given.  Otherwise,
*       the default is 8.
*
*   ACTIVE KEYS:
*
*     Four simple arrow keys:
*
*       Rotate the view space about its center.
*
*     Four simple arrow keys shifted:
*
*       Translate object within view space.  Translation is clipped to near view
*       space limits.
*
*     Up and down box arrow keys shifted:
*
*       Translate object forwards and backwards within view space.  As with other
*       translations, the total range is clipped.
*
*     F0
*
*       Reset to original view and conditions.
*
*     F1
*
*       Toggle background clears on/off.  Background clears wake up or reset to
*       on.  When background clears are off, then the objects are drawn incrementally
*       into the existing image and Z buffer (when enabled).  When background clears
*       are on, then the objects are always drawn into a cleared background.
*
*     F2
*
*       Toggle updates on/off.  The initial and reset conditions is updates are on.
*       When updates are off, nothing is drawn, although incremental transforms and
*       modes are still accumulated.  When updates are turned on, the objects are
*       redrawn in their new positions.
}
program "gui" test_tube;
%include 'rend_test_all.ins.pas';

const
  rot_increment = 0.05;                {rotation factor increment per key stroke}
  trans_increment = 0.1;               {translation per keystroke}
  min_bits_vis_req = 12.0;             {min visible bits per pixel even if SW emul}
  default_n_sides = 8;                 {default number of sides to tube cylender}
  n_tube_points = 10;                  {number of points in tube}
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

  pi = 3.141593;                       {what it sounds like, don't touch}

var
  image_width: integer32;              {horizontal size of real image}
  image_height: integer32;             {vertical size of real image}
  aspect: real;                        {aspect ratio of real image}
  image_bitmap: rend_bitmap_handle_t;  {handle to bitmap for main drawing window}
  z_bitmap: rend_bitmap_handle_t;      {handle to Z buffer for main drawing window}
  pix_x, pix_y: integer32;             {temp image size in pixels}
  asp: real;                           {temp image aspect ratio}
  i, j: integer32;                     {scratch integers and loop counters}
  comment:                             {comment string for labeling image file}
    %include '(cog)lib/string132.ins.pas';
  fnam:                                {generic name of image output file}
    %include '(cog)lib/string_treename.ins.pas';

  cxb, cyb, czb, cofs: vect_3d_t;      {local copy of current xform matrix}
  c_p: ^char;                          {used for reading in key stroke}
  token:                               {for reading stuff from keyboard}
    %include '(cog)lib/string16.ins.pas';
  m: real;                             {mult factor for unitizing vector}
  gpr_event: gpr_$event_t;             {ID for what type of event occurred}
  gpr_data: char;                      {key or button ID character}
  gpr_pos: gpr_$position_t;            {X,Y position of GPR event}
  p1, p2, p3: vect_2d_t;               {scratch 2D coordinates}
  max_buf: integer32;                  {max hardware buffer of double buffering}
  n_sides: sys_int_machine_t;          {number of sides to tube profile}
  force_sw_on: boolean;                {TRUE if need to force SW emulation ON}
  sw_on: boolean;                      {TRUE if tubes require SW emulation}
  read_sw, write_sw: boolean;          {scratch flags}
  on: boolean;                         {scratch boolean flag}
  clear_on: boolean;                   {TRUE if clear image before redraw}
  update_on: boolean;                  {TRUE if update image on REDRAW call}
  whole_screen: boolean;               {TRUE if doing graphics on whole screen}
  smooth: boolean;                     {TRUE if smooth shading tubes}
  set_xsec: boolean;                   {TRUE if we need to reset crossection}
  entered: boolean;                    {TRUE if ENTER_REND_COND succeeded}
  rgb_mode: integer32;                 {RGB interpolation mode for opaque objects}
  min_bits: real;                      {min effective bits of color resolution}
  cmode_vals: rend_cmode_vals_t;       {save area for changeable modes}
  cleanup_handle: pfm_$cleanup_rec;    {handle to our cleanup handler}
  window_handle1: stream_$id_t;        {stream ID for graphics window region}
  pane1_dev:                           {handle to the graphics devices}
    rend_dev_id_t;
  unit: rend_dev_unit_t;               {scratch I/O units for graphics devices}
  stat: sys_err_t;                     {system independent error code}

  parm_num: integer16;                 {next command line parameter number to read}
  opt,                                 {command line option name}
  parm,                                {command line option parameter}
  s:                                   {scratch string}
    %include '(cog)lib/string256.ins.pas';
  pick: integer16;                     {number of token picked from list}

  tube_path: array[1..n_tube_points] of vect_3d_t := [
    [x := 0.3, y := -0.8, z := 0.5],
    [x := 0.5, y := -0.6, z := 0.2],
    [x := 0.3, y := -0.4, z := -0.2],
    [x := 0.0, y := -0.2, z := -0.3],
    [x := 0.0, y := 0.0, z := -0.4],
    [x := 0.1, y := 0.2, z := -0.4],
    [x := 0.1, y := 0.4, z := -0.4],
    [x := -0.1, y := 0.6, z := -0.1],
    [x := -0.3, y := 0.8, z := 0.1],
    [x := -0.3, y := 0.7, z := 0.3]];
  tube_r: array[1..n_tube_points] of real :=
    [0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.07, 0.10, 0.08, 0.05];

label
  next_opt, done_opts,
  min_bits_loop, done_min_bits, cmd_loop, new_xform, done_cmd_loop;
{
****************************************************************************
*
*   Internal subroutine NEXT_TOKEN (S)
*
*   Return the next token from the command line in the variable length
*   string S.
}
procedure next_token (
  in out  s: univ var_string_arg);     {returned command line token}

begin
  string_get_arg (parm_num, s);        {get the command line argument}
  parm_num := parm_num+1;              {advance counter to next token}
  end;
{
****************************************************************************
*
*   Internal subroutine NEXT_TOKEN_INT (I)
*
*   Read the next command line token and return its value as an integer.
}
procedure next_token_int (
  out     i: integer32);

var
  token: var_string16;
  err: boolean;

begin
  token.max := sizeof(token.str);
  next_token (token);
  string_t_int32 (token, i, err);
  if err then begin
    writeln ('Bad integer command line argument "', token.str:token.len, '".');
    sys_bomb;
    end;
  end;
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

  rend_set.zon^ (true);

  rend_set.iterp_shade_mode^ (         {set SHADE_MODE for RGB}
    rend_iterp_red_k, rgb_mode);
  rend_set.iterp_shade_mode^ (
    rend_iterp_grn_k, rgb_mode);
  rend_set.iterp_shade_mode^ (
    rend_iterp_blu_k, rgb_mode);
  rend_set.shade_geom^ (rgb_mode);     {set shading geometry to match RGB mode}

  rend_set.rgb^ (1.0, 0.5, 0.5);

  rend_prim.tube_r_3d^ (n_tube_points, tube_path, tube_r);

  if clear_on and (max_buf > 1) then begin {clear image and swap bufs after drawing ?}
    set_buf_clear;                     {set all state ready for clearing buffer}
    rend_prim.flip_buf^;               {flip buffers and clear new draw buf}
    end;

  rend_set.exit_rend^;
  end;
{
**************************************************************************************
*
*   Start of main routine.
}
begin
  parm_num := 1;                       {init number of next command line parm}
  force_sw_on := false;                {init to try for hardware drawing}
  whole_screen := false;               {init to do graphics in current window}
  smooth := true;                      {init smooth shading to ON}
  set_xsec := false;                   {init to we don't need to set crossection}
  n_sides := default_n_sides;          {init number of sides to a tube}
{
*   Process the command line options.  Come back here each new command line
*   option.
}
next_opt:
  next_token (opt);                    {get next command line option name}
  if opt.len <= 0 then goto done_opts; {nothing more on command line ?}
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (                    {pick option name from list}
    opt,                               {option name}
    '-SCREEN -FLAT -SIDES',
    pick);                             {number of picked option}
  case pick of                         {do routine for specific option}
{
*   -SCREEN
*   Use the entire screen for graphics, not just the current window.
}
1: begin
  whole_screen := true;
  end;
{
*   -FLAT
*   Draw the tubes facet-shaded instead of smoothe shaded.
}
2: begin
  smooth := false;
  set_xsec := true;                    {we now need to explicitly set crossection}
  end;
{
*   -SIDES n
*   Set the number of sides used to approximate the circular profile of the tubes.
}
3: begin
  next_token_int (n_sides);
  set_xsec := true;                    {we now need to explicitly set crossection}
  end;
{
*   Unrecognized command line option.
}
  otherwise
  writeln ('Unrecognized command line option "', opt.str:opt.len, '".');
  sys_bomb;
  end;                                 {end of command line option case statement}
  goto next_opt;                       {back for next command line option}
done_opts:                             {done with all the command line options}
{
*   Done processing the command line options.
}
  rgb_mode := rend_iterp_mode_linear_k;

  rend_start;                          {initialize RENDlib}
  if whole_screen                      {which way to init the graphics ?}
    then begin                         {grab the entire screen}
      unit.screen_id := stream_$stdout; {currently required for Apollo}
      rend_open (                      {open graphics output device}
        rend_devtyp_screen_k,          {type of device}
        unit,                          {I/O unit of this particular device}
        pane1_dev,                     {returned device handle}
        stat);
      sys_error_abort (stat, 'On open whole screen graphics device.');
      end
    else begin                         {we are not grabbing entire screen}
      window_handle1 := stream_$stdout;
      unit.window_id := window_handle1; {open main draw area graphics device}
      rend_open (                      {open graphics output device}
        rend_devtyp_window_k,          {type of device}
        unit,                          {I/O unit of this particular device}
        pane1_dev,                     {returned device handle}
        stat);
      sys_error_abort (stat, 'On open main drawing window for graphics.');
      end
    ;
{
*   Set up RENDlib state for the main drawing pane.
}
  rend_set.enter_rend^;                {enter graphics mode}
  rend_get.image_size^ (               {find out what size image we have}
    image_width, image_height, aspect); {returned values of actual image}

  rend_set.alloc_bitmap_handle^ (rend_scope_dev_k, image_bitmap);
  rend_set.alloc_bitmap^ (             {allocate the RGB pixels for this image}
    image_bitmap,                      {handle to this bitmap}
    image_width, image_height,         {size of image in pixels}
    3,                                 {number of bytes to allocate for each pixel}
    rend_scope_dev_k);

  rend_set.alloc_bitmap_handle^ (rend_scope_dev_k, z_bitmap);
  rend_set.alloc_bitmap^ (             {allocate the Z pixels for this image}
    z_bitmap,                          {handle to this bitmap}
    image_width, image_height,         {size of image in pixels}
    2,                                 {number of bytes to allocate for each pixel}
    rend_scope_dev_k);

  rend_set.iterp_bitmap^ (             {connect bitmap to red interpolator}
    rend_iterp_red_k,                  {interpolant ID to connect bitmap to}
    image_bitmap,                      {handle to the bitmap}
    0);                                {byte index into pixel for this interpolant}

  rend_set.iterp_bitmap^ (             {connect bitmap to green interpolator}
    rend_iterp_grn_k,
    image_bitmap,
    1);

  rend_set.iterp_bitmap^ (             {connect bitmap to blue interpolator}
    rend_iterp_blu_k,
    image_bitmap,
    2);

  rend_set.iterp_bitmap^ (             {connect bitmap to Z interpolator}
    rend_iterp_z_k,                    {interpolant ID to connect bitmap to}
    z_bitmap,                          {handle to the bitmap}
    0);                                {byte index into pixel for this interpolant}

  string_appends (comment, 'From program TEST_TUBE.');
  rend_set.comment^ (0, comment.str, comment.len); {set one line description}
  rend_get.xform_3d^ (cxb, cyb, czb, cofs); {init our copy of 3D transform matrix}
  rend_set.backface^ (rend_bface_front_k);
  rend_set.new_view^;
  clear_on := true;                    {init to clear image before redraw}
  update_on := true;                   {init to update image on REDRAW call}
  sw_on := force_sw_on;                {SW emulation will be used if forced ON}

  if set_xsec then begin               {we need to explicitly set crossection ?}
    rend_set.tube_xsec_circ_3d^ (n_sides, smooth);
    end;
{
*   Determine whether software emulation will be required for drawing the background.
*   This is only the case if the solid triangles read from the software bitmap, and
*   therefore assume it is up to date.
}
  if not force_sw_on then begin        {don't bother if know we need SW emulation}
    rend_set.iterp_on^ (rend_iterp_red_k, true); {turn on red interpolant}
    rend_set.iterp_on^ (rend_iterp_grn_k, true); {turn on green interpolant}
    rend_set.iterp_on^ (rend_iterp_blu_k, true); {turn on blue interpolant}
    p1.x := 0.0;
    p1.y := 0.0;
    rend_set.iterp_linear^ (
      rend_iterp_red_k, p1, 0.0, 0.1, 0.1);
    rend_set.iterp_linear^ (
      rend_iterp_grn_k, p1, 0.0, 0.1, 0.1);
    rend_set.iterp_linear^ (
      rend_iterp_blu_k, p1, 0.0, 0.1, 0.1);
    rend_set.iterp_shade_mode^ (       {set SHADE_MODE for RGB}
      rend_iterp_red_k, rgb_mode);
    rend_set.iterp_shade_mode^ (
      rend_iterp_grn_k, rgb_mode);
    rend_set.iterp_shade_mode^ (
      rend_iterp_blu_k, rgb_mode);
    rend_set.shade_geom^ (rgb_mode);   {set shading geometry to match RGB mode}
    rend_set.iterp_on^ (rend_iterp_z_k, true); {turn on z interpolant}
    rend_set.zon^ (true);              {we will need to do Z buffering}
    rend_set.iterp_linear^ (           {set Z interpolant to linear interpolation}
      rend_iterp_z_k, p1, 0.0, 0.1, 0.1);
    rend_set.iterp_shade_mode^ (       {set Z SHADE_MODE to linear}
      rend_iterp_z_k, rend_iterp_mode_linear_k);
    rend_set.dev_z_curr^ (true);       {pretend device Z buffer is up to date}
    rend_set.start_group^;
    rend_get.reading_sw_prim^ (        {find if our primitive reads SW bitmap}
      rend_prim.tube_3d,               {primitive to inquire about}
      force_sw_on);                    {TRUE if reads from SW bitmap}
    rend_get.update_sw_prim^ (         {find if our primitive uses SW emulation}
      rend_prim.tube_3d,               {primitive to inquire about}
      sw_on);                          {TRUE if SW emulation used}
    rend_set.end_group^;
    rend_get.cmode_vals^ (cmode_vals); {save changeable mode state here}
    end;
{
*   Now determine what buffer configuration we can get away with without forcing
*   software updates, unless already on.
}
  min_bits := 24.0;                    {set first try at min visible color bits}
  rend_set.min_bits_vis^ (min_bits);   {try for maximum color resolution}
  if sw_on
    then max_buf := 1                  {use single buffer if software emulation ON}
    else max_buf := 2;                 {try for double buffering if hardware drawing}
  rend_set.max_buf^ (max_buf);         {set initial buffers request}

  if not sw_on then begin              {hardware drawing possible ?}
min_bits_loop:                         {back here if curr MIN_BITS too high}
    rend_set.start_group^;
    rend_get.update_sw_prim^ (rend_prim.tube_3d, on); {check SW emulation flag}
    rend_set.end_group^;
    if not on then goto done_min_bits; {MIN_BITS setting now not force SW updates ?}
    min_bits := min_bits - 1.0;        {try a little smaller MIN_BITS value}
    if min_bits <= min_bits_vis_req then begin {degraded far enough ?}
      if max_buf > 1 then begin        {requesting more than one buffer ?}
        max_buf := 1;                  {two didn't work, try single buffering}
        min_bits := 24.0;              {reset MIN_BITS request}
        goto min_bits_loop;            {back and try while requesting just 1 buffer}
        end;
      goto done_min_bits;              {all done setting MAX_BUF and MIN_BITS}
      end;
    rend_set.cmode_vals^ (cmode_vals); {reset to state before last test case}
    rend_set.min_bits_vis^ (min_bits); {set to smaller MIN_BITS}
    rend_set.max_buf^ (max_buf);       {re-affirm max requested buffers}
    goto min_bits_loop;                {back and test this new MIN_BITS setting}
done_min_bits:                         {found setting for hardware drawing}
    end;                               {done setting MIN_BITS and number of buffers}

  rend_get.cmode_vals^ (cmode_vals);   {save changeable mode state here}
  rend_get.bits_vis^ (min_bits);       {find out what we really ended up with}
  rend_get.max_buf^ (max_buf);
  rend_set.force_sw_update^ (force_sw_on); {force SW updates on, if necessary}
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
  sys_error_abort (stat, 'On GPR call to enable keystroke events.');
{
*   Configuration is now all decided.  Init the first displayed image.
}
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
  sys_error_abort (stat, 'On call to GPR_$COND_EVENT_WAIT.');
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
