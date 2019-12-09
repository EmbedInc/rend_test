{   WARNING: This program is very old and uses Apollo system calls to get
*   keyboard events.  It needs to be converted to using RENDlib event.
}

{   Program to test 3D vectors.
*
*   This program obeys all the standard RENDlib test program command line options
*   in addition to the following:
*
*   -SUBPIX
*
*     Force the vectors to be drawn with subpixel addressing ON.  The default
*     is subpixel positioning is not required.
*
*   -Z
*
*     Use Z buffering when drawing the vectors.
}
program "gui" test_3dv;
%include 'rend_test_all.ins.pas';
%include '/cognivision_links/sys_ins/gpr.ins.pas';
%include '/cognivision_links/sys_ins/kbd.ins.pas';

const
  pi = 3.141593;
  deg_rad = pi/180.0;                  {mult factor to convert degrees to radians}
  rot_increment = 0.05;                {rotation factor increment per key stroke}
  trans_increment = 0.1;               {translation per keystroke}
  max_msg_parms = 4;                   {max parameters we can pass to a message}
  trans_px_key = kbd_$lcs;             {define which keys cause translation}
  trans_mx_key = kbd_$las;
  trans_py_key = kbd_$l8s;
  trans_my_key = kbd_$les;
  trans_pz_key = kbd_$lfs;
  trans_mz_key = kbd_$lds;

var
  cxb, cyb, czb, cofs: vect_3d_t;      {local copy of current xform matrix}
  c_p: ^char;                          {used for reading in key stroke}
  vparms: rend_vect_parms_t;           {vector drawing control parameters}
  p1, p2, p3: vect_2d_t;
  subpixel: boolean;                   {TRUE on -SUBPIX command line option}
  use_z: boolean;                      {TRUE if should do Z buffering}
  read_sw: boolean;                    {TRUE if vectors read from SW bitmap}

  gpr_event: gpr_$event_t;             {ID for what type of event occurred}
  gpr_data: char;                      {key or button ID character}
  gpr_pos: gpr_$position_t;            {X,Y position of GPR event}

  pick: sys_int_machine_t;             {number of token picked from list}
  opt:                                 {command line option name}
    %include '(cog)lib/string16.ins.pas';
  parm:                                {command line option parameter}
    %include '(cog)lib/string80.ins.pas';
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {system-independent error code}

label
  next_opt, done_opts, cmd_loop, new_xform, done_cmd_loop;
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
*   send it to the rendering pipe.
}
  cxb := xb;
  cyb := yb;
  czb := zb;
  cofs := ofs;
  rend_set.xform_3d^ (cxb, cyb, czb, cofs);
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

const
  hb = 0.9;                            {coor that arrow head goes back to}
  ho = 0.05;                           {how far out arrow head goes}
  ab = 0.2;                            {how far back arrow goes}

begin
  rend_set.enter_rend^;
  rend_set.zon^ (false);
  p1.x := 0.0; p1.y := 0.0;
  p2.x := 0.0; p2.y := image_height;
  p3.x := image_width; p3.y := image_height;
  rend_set.lin_geom_2dim^ (p1, p2, p3);
  rend_set.lin_vals^ (rend_iterp_red_k, 0.5, 0.1, 0.1);
  rend_set.lin_vals^ (rend_iterp_grn_k, 0.5, 0.1, 0.1);
  rend_set.lin_vals^ (rend_iterp_blu_k, 0.5, 0.1, 0.1);
  if use_z then begin
    rend_set.iterp_flat^ (rend_iterp_z_k, -1.0);
    end;
  rend_prim.clear_cwind^;              {clear background}
  if use_z then begin                  {we will be using Z buffer ?}
    rend_set.zon^ (true);
    end;
{
*   Draw our stuff.
}
  rend_set.rgb^ (1.0, 0.3, 0.3);       {red arrow}
  rend_set.start_group^;
  rend_set.cpnt_3d^ (-ab, 0.0, 0.0);
  rend_prim.vect_3d^ (1.0, 0.0, 0.0);
  rend_prim.vect_3d^ (hb, ho, 0.0);
  rend_set.cpnt_3d^ (1.0, 0.0, 0.0);
  rend_prim.vect_3d^ (hb, -ho, 0.0);
  rend_set.cpnt_3d^ (1.0, 0.0, 0.0);
  rend_prim.vect_3d^ (hb, 0.0, ho);
  rend_set.cpnt_3d^ (1.0, 0.0, 0.0);
  rend_prim.vect_3d^ (hb, 0.0, -ho);
  rend_set.end_group^;

  rend_set.rgb^ (0.3, 1.0, 0.3);       {green arrow}
  rend_set.start_group^;
  rend_set.cpnt_3d^ (0.0, -ab, 0.0);
  rend_prim.vect_3d^ (0.0, 1.0, 0.0);
  rend_prim.vect_3d^ (ho, hb, 0.0);
  rend_set.cpnt_3d^ (0.0, 1.0, 0.0);
  rend_prim.vect_3d^ (-ho, hb, 0.0);
  rend_set.cpnt_3d^ (0.0, 1.0, 0.0);
  rend_prim.vect_3d^ (0.0, hb, ho);
  rend_set.cpnt_3d^ (0.0, 1.0, 0.0);
  rend_prim.vect_3d^ (0.0, hb, -ho);
  rend_set.end_group^;

  rend_set.rgb^ (0.3, 0.3, 1.0);       {blue arrow}
  rend_set.start_group^;
  rend_set.cpnt_3d^ (0.0, 0.0, -ab);
  rend_prim.vect_3d^ (0.0, 0.0, 1.0);
  rend_prim.vect_3d^ (ho, 0.0, hb);
  rend_set.cpnt_3d^ (0.0, 0.0, 1.0);
  rend_prim.vect_3d^ (-ho, 0.0, hb);
  rend_set.cpnt_3d^ (0.0, 0.0, 1.0);
  rend_prim.vect_3d^ (0.0, ho, hb);
  rend_set.cpnt_3d^ (0.0, 0.0, 1.0);
  rend_prim.vect_3d^ (0.0, -ho, hb);
  rend_set.end_group^;

  rend_set.exit_rend^;
  end;
{
**************************************************************************************
*
*   Start of main routine.
}
begin
  sys_error_none (stat);               {init to indicate no error}

  subpixel := false;                   {init subpixel addressing OFF}
  use_z := false;                      {init to not do Z buffering}
  rend_test_cmline ('TEST_3DV');       {process command line}
{
*   Back here for each new command line option.
}
next_opt:
  rend_test_cmline_token (opt, stat);  {get next command line option name}
  if string_eos(stat) then goto done_opts; {nothing more on command line ?}
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (                    {pick option name from list}
    opt,                               {option name}
    '-SUBPIX -Z',
    pick);                             {number of picked option}
  case pick of                         {do routine for specific option}
{
*   -SUBPIX
}
1: begin
  subpixel := true;
  end;
{
*   -Z
}
2: begin
  use_z := true;
  end;
{
*   Illegal command line option.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_bad', msg_parm, 1);
    end;                               {end of command line option cases}
  goto next_opt;                       {back for next command line option}

done_opts:                             {done with all the command line options}
{
*   Done processing the command line options.  Initialize the graphics.
}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k]
    );
  if use_z then begin                  {we will do Z buffering ?}
    rend_test_bitmaps (                {create bitmaps and init interpolants}
      [rend_test_comp_z_k]);
    rend_set.zfunc^ (rend_zfunc_gt_k); {set Z compare function}
    end;

  rend_get.xform_3d^ (cxb, cyb, czb, cofs); {init our copy of 3D transform matrix}
  rend_get.vect_parms^ (vparms);       {get current vector parameters}
  vparms.subpixel := subpixel;         {set subpixel addressing ON/OFF as selected}
  rend_set.vect_parms^ (vparms);
{
*   Determine whether we need to force on SW emulation for clearing the background.
*   This happens when the vectors need to read from the SW bitmap.
}
  read_sw := false;                    {init to vectors don't read SW bitmap}
  if use_z then begin                  {vectors use read/modify/write operation ?}
    rend_set.rgb^ (1.0, 0.3, 0.3);
    rend_set.start_group^;
    rend_get.reading_sw_prim^ (rend_prim.vect_3d, read_sw);
    rend_set.end_group^;
    end;
  force_sw := force_sw or read_sw;     {merge with existing SW update flag}
  rend_set.force_sw_update^ (force_sw);
  rend_set.exit_rend^;
  redraw;
{
*   Set up keypad so that we can read the arrow keys.
}
  gpr_$enable_input (                  {enable all the keys/buttons we care about}
    gpr_$keystroke,                    {which type of event to enable}
    [ kbd_$up_arrow,
      kbd_$left_arrow,
      kbd_$right_arrow,
      kbd_$down_arrow,
      kbd_$f0,
      kbd_$exit,
      trans_px_key,
      trans_mx_key,
      trans_py_key,
      trans_my_key,
      trans_pz_key,
      trans_mz_key,
      ],
    stat.sys);                         {system error return code}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Main loop.  Come back here to get each new command event.
}
cmd_loop:
  discard( gpr_$event_wait (           {wait for next keystroke}
    gpr_event,                         {returned ID of this particular event type}
    gpr_data,                          {one char window or keystroke ID}
    gpr_pos,                           {XY position of event}
    stat.sys));                        {error return code}
  sys_error_abort (stat, '', '', nil, 0);
  if gpr_event <> gpr_$keystroke then goto cmd_loop; {ignore non-keystroke events}
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

kbd_$f0: begin                         {reset to initial transform}
      cxb.x := 1.0; cxb.y := 0.0; cxb.z := 0.0;
      cyb.x := 0.0; cyb.y := 1.0; cyb.z := 0.0;
      czb.x := 0.0; czb.y := 0.0; czb.z := 1.0;
      cofs.x := 0.0; cofs.y := 0.0; cofs.z := 0.0;
      rend_set.xform_3d^ (cxb, cyb, czb, cofs);
      redraw;
      end;

kbd_$exit: goto done_cmd_loop;

    end;                               {done with keystroke cases}

  goto cmd_loop;

new_xform:                             {local xform changed but not sent yet}
  rend_set.xform_3d^ (cxb, cyb, czb, cofs);
  redraw;
  goto cmd_loop;

done_cmd_loop:                         {all done with graphics, leave program}
  rend_end;
  end.
