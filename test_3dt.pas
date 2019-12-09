{   Program to test 3D triangles.
*
*   This program obeys all the standard RENDlib test program command line options
*   in addition to the following:
*
*     -NOZ
*
*       Turn off Z buffer compares when drawing objects.
*
*     -ALPHA
*
*       Force on the alpha buffered triangle.  By default, this triangle is displayed
*       whenever it is not the cause of forcing software emulation mode.
*
*     -NOALPHA
*
*       Force off the alpha buffered triangle.  By default, this triangle is displayed
*       whenever it is not the cause of forcing software emulation mode.
*
*     -QUAD
*
*       Quadratically interpolate RGB for the solid objects.
*
*     -PANES
*
*       Break up the current window to create separate panes for the graphics.
*
*     -LINE
*
*       Draw only the edges of the trianlges using the LINE_3D primitive.  The
*       default is to draw the triangles solid using the TRI_3D primitive.
*       This will also cause the text, if enabled, to be drawn with vectors
*       instead of polygons.
*
*     -TEXT
*
*       Draw some text in the 3DPL space.  This is for testing the 3DPL space
*       primitives.
*
*     -DEV2 <RENDlib device string>
*     -DEV3 <RENDlib device string>
*
*       Specify explicit RENDlib device strings for the two optional panes.
*       Either of these options implies -PANES.
*
*   ACTIVE KEYS:
*
*     Four arrow keys:
*
*       Rotate the view space about its center.
*
*     Four arrow keys shifted:
*
*       Translate object withing view space.  Translation is clipped to near view
*       space limits.
*
*     Up and down arrow keys with control:
*
*       Translate object forwards and backwards within view space.  As with other
*       translations, the total range is clipped.
*
*     First function key
*
*       Reset to original view and conditions.
*
*     Second function key
*
*       Toggle background clears on/off.  Background clears wake up or reset to
*       on.  When background clears are off, then the objects are drawn incrementally
*       into the existing image and Z buffer (when enabled).  When background clears
*       are on, then the objects are always drawn into a cleared background.
*
*     Third function key
*
*       Toggle updates on/off.  The initial and reset conditions is updates are on.
*       When updates are off, nothing is drawn, although incremental transforms and
*       modes are still accumulated.  When updates are turned on, the objects are
*       redrawn in their new positions.
*
*     Fourth function key
*
*       Toggle double buffer mode, if possible.  Double buffering is enabled
*       be default, if available.
*
*     Mouse button 1 (usually left button)
*
*       Pan the camera.  Drags point on virtual sphere centered on the eye
*       point and extending to Z=0.
*
*     Shift mouse button 1
*
*       Dolly in/out.
*
*     Mouse button 3 (usually right button)
*
*       Rotate object.  Drags point on large virtual sphere centered at the
*       origin.
}
program "gui" test_3dt;
%include 'rend_test_all.ins.pas';

const
  rot_increment = 0.05;                {rotation factor increment per key stroke}
  trans_increment = 0.1;               {translation per keystroke}
  min_bits_vis_req = 12.0;             {min visible bits per pixel even if SW emul}
  key_left_k = 1;                      {left arrow key}
  key_right_k = 2;                     {right arrow key}
  key_up_k = 3;                        {up arrow key}
  key_down_k = 4;                      {down arrow key}
  key_reset_k = 5;                     {key to reset transform}
  key_clear_toggle_k = 6;              {key to toggle clear mode}
  key_update_toggle_k = 7;             {key to toggle update mode}
  key_dblbuf_toggle_k = 8;             {key to toggle double buffer mode}
  key_pan_dolly_k = 9;                 {pan or dolly the camera}
  key_rot_k = 10;                      {rotate object by dragging front of virt sph}

  max_msg_parms = 4;                   {number of parameters we can pass to messages}

type
  vert3d_t = record                    {vertex descriptor passed to TRI_3D}
    coor_p: vect_3d_fp1_p_t;           {pointer to XYZ coordinate}
    diff_p: rend_rgba_p_t;             {pointer to RGBA diffuse replacement colors}
    end;

var
  p1: vect_2d_t;                       {scratch 2D interpolant anchor point}
  cxb, cyb, czb, cofs: vect_3d_t;      {local copy of current xform matrix}
  mat: vect_mat3x4_t;                  {scratch 3x4 transformation matrix}
  max_buf: sys_int_machine_t;          {max hardware buffer of double buffering}
  max_buf_available: sys_int_machine_t; {max buffers we allows ourselves to use}
  vect_parms: rend_vect_parms_t;       {vector drawing parameters}
  bmap_used: rend_test_comp_t;         {set of interpolants we need bitmaps for}
  sw_on: boolean;                      {TRUE if solid triangles use SW emulation}
  read_sw, write_sw: boolean;          {scratch flags}
  on: boolean;                         {scratch boolean flag}
  z_on: boolean;                       {TRUE if Z compares turned on}
  alpha_on: boolean;                   {TRUE if draw alpha buffered triangle}
  no_alpha: boolean;                   {TRUE if -NOALPHA command line argument}
  yes_alpha: boolean;                  {TRUE if -ALPHA command line argument}
  clear_on: boolean;                   {TRUE if clear image before redraw}
  update_on: boolean;                  {TRUE if update image on REDRAW call}
  quad: boolean;                       {TRUE for quadratic RGB}
  pane: boolean;                       {TRUE if make separate pane for graphics}
  line: boolean;                       {TRUE on -LINE command line argument}
  text: boolean;                       {TRUE on -TEXT command line argument}
  dev2_set, dev3_set: boolean;         {TRUE if appropriate -DEVn option given}
  refresh1, refresh2, refresh3         {TRUE for panes that need refresh}
    :boolean;
  wiped1: boolean;                     {TRUE if pixels for pane1 got wiped out}
  refresh_any: boolean;                {TRUE if any pane needs refresh}
  rgb_mode: sys_int_machine_t;         {RGB interpolation mode for opaque objects}
  cmode_vals: rend_cmode_vals_t;       {save area for changeable modes}
  tparm: rend_text_parms_t;            {text control parameters}
  pane2_dev, pane3_dev:                {handles to the extra graphics devices}
    rend_dev_id_t;
  event: rend_event_t;                 {descriptor for last RENDlib event}
  v: vert3d_t;                         {scratch RENDlib vertex descriptor}

  opt:                                 {command line option name}
    %include '(cog)lib/string256.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}

  pane2_rgb: rend_rgb_t                {color for pane 2}
    := [red := 0.15, grn := 0.60, blu := 0.15];
  pane3_rgb: rend_rgb_t                {color for pane 3}
    := [red := 0.15, grn := 0.15, blu := 0.60];
  pane1_name: string_var80_t :=
    [str := 'foto_render', len := 11, max := sizeof(pane1_name.str)];
  pane2_name: string_var80_t :=
    [str := 'foto_scene_diagram', len := 18, max := sizeof(pane2_name.str)];
  pane3_name: string_var80_t :=
    [str := 'foto_menu', len := 9, max := sizeof(pane3_name.str)];

  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {system independent error code}

label
  next_opt, done_opts, min_bits_loop, done_min_bits,
  refresh, event_wait, event_done;
{
************************************************
*
*   Local subroutine ROTATE (RX, RY, RZ)
*
*   Rotate the current 3D transformation small incremental amounts about X, Y, and
*   Z in world coordinate space.  An incremental rotation matrix will be created
*   and then post-multiplied by the current transformation.
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
  end;
{
************************************************
*
*   Local subroutine SET_BUF_CLEAR
*
*   Set up all the state ready for clearing the current drawing buffer.  Nothing
*   is actually written to the pixels.
}
procedure set_buf_clear;

var
  p1, p2, p3: vect_2d_t;               {2D coordinates used as anchor points}

begin
  rend_set.zon^ (false);
  p1.x := 0.0; p1.y := 0.0;
  p2.x := 0.0; p2.y := image_height;
  p3.x := image_width; p3.y := image_height;
  rend_set.lin_geom_2dim^ (p1, p2, p3);
  rend_set.lin_vals^ (rend_iterp_red_k, 0.5, 0.1, 0.1);
  rend_set.lin_vals^ (rend_iterp_grn_k, 0.5, 0.1, 0.1);
  rend_set.lin_vals^ (rend_iterp_blu_k, 0.5, 0.1, 0.1);
  if z_on then begin
    rend_set.iterp_flat^ (rend_iterp_z_k, -1.0);
    end;
  end;
{
************************************************
*
*   Local subroutine DRAW_TRI (V1, V2, V3, GNORM)
*
*   Draw a triangle with the current modes.  V1-V3 are RENDlib vertex
*   descriptors.  GNORM is the geometric normal vector.  If the flag LINE
*   is TRUE, then the edges of the triangle will be written using the LINE_3D
*   primitive.  Otherwise, the whole triangle will be drawn using the TRI_3D
*   primitive.
}
procedure draw_tri (
  in      v1, v2, v3: univ rend_vert3d_t; {pointer info for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}

begin
  if line
    then begin                         {draw edges of triangle}
      rend_prim.line_3d^ (v1, v2, gnorm);
      rend_prim.line_3d^ (v2, v3, gnorm);
      rend_prim.line_3d^ (v3, v1, gnorm);
      end
    else begin                         {draw whole triangle filled}
      rend_prim.tri_3d^ (v1, v2, v3, gnorm);
      end
    ;
  end;
{
************************************************
*
*   Local subroutine REDRAW
*
*   Cause all our graphics to be redrawn.  The current displayed image is completely
*   overwritten.
}
procedure redraw;

const
  ho = 0.1;                            {how far out arrow head goes}
  ab = 0.2;                            {how far back arrow goes}
  rsq2 = 1.0 / sqrt(2.0);

var
  v1, v2, v3: vert3d_t;                {verticies for a triangle}
  coor1, coor2, coor3: vect_3d_fp1_t;  {XYZ coordinates for triangle verticies}
  c1, c2, c3: vect_3d_t;               {extra scratch coordinates}
  norm_x, norm_y, norm_z: vect_3d_t;   {used for geometric unit normal vectors}
  norm_a: vect_3d_t;                   {geometric normal for alpha buffered triangle}
  suprop_val: rend_suprop_val_t;       {used for setting a suprop value}
  white: rend_rgba_t;                  {explicit vertex color}
  xb2d, yb2d, of2d: vect_2d_t;         {2D transform}

begin
  rend_set.enter_rend^;

  if not update_on then begin          {not supposed to update the display ?}
    rend_set.exit_rend^;
    return;
    end;

  rend_set.xform_3d^ (cxb, cyb, czb, cofs);
  rend_set.new_view^;

  if clear_on and (max_buf <= 1) then begin {clear image before redraw ?}
    set_buf_clear;                     {set state ready for clearing buffer}
    rend_prim.clear_cwind^;            {clear the current drawing buffer}
    end;

  if z_on then begin
    rend_set.zon^ (true);
    end;

  rend_set.iterp_shade_mode^ (         {set SHADE_MODE for RGB}
    rend_iterp_red_k, rgb_mode);
  rend_set.iterp_shade_mode^ (
    rend_iterp_grn_k, rgb_mode);
  rend_set.iterp_shade_mode^ (
    rend_iterp_blu_k, rgb_mode);
  rend_set.shade_geom^ (rgb_mode);     {set shading geometry to match RGB mode}

  white.red := 1.0;
  white.grn := 1.0;
  white.blu := 1.0;
  white.alpha := 1.0;

  v1.coor_p := addr(coor1);
  v1.diff_p := nil;

  v2.coor_p := addr(coor2);
  v2.diff_p := addr(white);

  v3.coor_p := addr(coor3);
  v3.diff_p := addr(white);

  norm_x.x := 3.0;
  norm_x.y := 0.0;
  norm_x.z := 0.0;

  norm_y.x := 0.0;
  norm_y.y := 3.0;
  norm_y.z := 0.0;

  norm_z.x := 0.0;
  norm_z.y := 0.0;
  norm_z.z := 3.0;

  norm_a.x := 0.1;
  norm_a.y := 0.1;
  norm_a.z := 0.1;
{
*   Draw the triangles.
}
  suprop_val.diff_red := 1.0; suprop_val.diff_grn := 0.4; suprop_val.diff_blu := 0.4;
  rend_set.suprop_val^ (rend_suprop_diff_k, suprop_val);
  coor1.x := 1.0; coor1.y := 0.0; coor1.z := 0.0;
  coor2.x := -ab; coor2.y := ho; coor2.z := 0.0;
  coor3.x := -ab; coor3.y := -ho; coor3.z := 0.0;

  rend_set.start_group^;
  draw_tri (v1, v2, v3, norm_z);
  coor2.x := -ab; coor2.y := 0.0; coor2.z := -ho;
  coor3.x := -ab; coor3.y := 0.0; coor3.z := ho;
  draw_tri (v1, v2, v3, norm_y);
  rend_set.end_group^;

  suprop_val.diff_red := 0.4; suprop_val.diff_grn := 1.0; suprop_val.diff_blu := 0.4;
  rend_set.suprop_val^ (rend_suprop_diff_k, suprop_val);
  coor1.x := 0.0; coor1.y := 1.0; coor1.z := 0.0;
  coor2.x := 0.0; coor2.y := -ab; coor2.z := ho;
  coor3.x := 0.0; coor3.y := -ab; coor3.z := -ho;

  rend_set.start_group^;
  draw_tri (v1, v2, v3, norm_x);
  coor2.x := -ho; coor2.y := -ab; coor2.z := 0.0;
  coor3.x := ho; coor3.y := -ab; coor3.z := 0.0;
  draw_tri (v1, v2, v3, norm_z);
  rend_set.end_group^;

  suprop_val.diff_red := 0.4; suprop_val.diff_grn := 0.4; suprop_val.diff_blu := 1.0;
  rend_set.suprop_val^ (rend_suprop_diff_k, suprop_val);
  coor1.x := 0.0; coor1.y := 0.0; coor1.z := 1.0;
  coor2.x := ho; coor2.y := 0.0; coor2.z := -ab;
  coor3.x := -ho; coor3.y := 0.0; coor3.z := -ab;

  rend_set.start_group^;
  draw_tri (v1, v2, v3, norm_y);
  coor2.x := 0.0; coor2.y := -ho; coor2.z := -ab;
  coor3.x := 0.0; coor3.y := ho; coor3.z := -ab;
  draw_tri (v1, v2, v3, norm_x);
  rend_set.end_group^;

  if text then begin                   {supposed to exercise 3DPL space using text ?}
    if line
      then begin                       {text will be draw with vectors}
        rend_set.rgb^ (0.7, 0.7, 0.7); {set fixed color}
        end
      else begin                       {text will be drawn with polygons}
        suprop_val.diff_red := 0.7; suprop_val.diff_grn := 0.7; suprop_val.diff_blu := 0.7;
        rend_set.suprop_val^ (rend_suprop_diff_k, suprop_val);
        end
      ;
    xb2d.x := rsq2; xb2d.y := -rsq2;   {rotate 2D space right pi/4}
    yb2d.x := rsq2; yb2d.y := rsq2;
    of2d.x := 0.0; of2d.y := 0.0;
    rend_set.xform_3dpl_2d^ (xb2d, yb2d, of2d);

    rend_set.start_group^;

    c1.x := 0.5; c1.y := 0.5; c1.z := 0.0; {label XY plane}
    c2.x := 1.0; c2.y := 0.0; c2.z := 0.0;
    c3.x := 0.0; c3.y := 1.0; c3.z := 0.0;
    rend_set.xform_3dpl_plane^ (c1, c2, c3); {set current plane}
    rend_set.cpnt_3dpl^ (0.0, 0.0);
    rend_prim.text^ ('XY plane', 8);

    c1.x := 0.0; c1.y := 0.5; c1.z := 0.5; {label YZ plane}
    c2.x := 0.0; c2.y := 1.0; c2.z := 0.0;
    c3.x := 0.0; c3.y := 0.0; c3.z := 1.0;
    rend_set.xform_3dpl_plane^ (c1, c2, c3); {set current plane}
    rend_set.cpnt_3dpl^ (0.0, 0.0);
    rend_prim.text^ ('YZ plane', 8);

    c1.x := 0.5; c1.y := 0.0; c1.z := 0.5; {label ZX plane}
    c2.x := 0.0; c2.y := 0.0; c2.z := 1.0;
    c3.x := 1.0; c3.y := 0.0; c3.z := 0.0;
    rend_set.xform_3dpl_plane^ (c1, c2, c3); {set current plane}
    rend_set.cpnt_3dpl^ (0.0, 0.0);
    rend_prim.text^ ('ZX plane', 8);

    rend_set.end_group^;
    end;                               {done drawing text}

  if alpha_on then begin               {supposed to draw alpha buffered triangle ?}
    rend_set.alpha_on^ (true);         {turn on alpha buffering}
    rend_set.iterp_on^ (rend_iterp_alpha_k, true); {turn on ALPHA interpolant}
    rend_set.iterp_shade_mode^ (       {set SHADE_MODE for RGB}
      rend_iterp_red_k, rend_iterp_mode_quad_k);
    rend_set.iterp_shade_mode^ (
      rend_iterp_grn_k, rend_iterp_mode_quad_k);
    rend_set.iterp_shade_mode^ (
      rend_iterp_blu_k, rend_iterp_mode_quad_k);
    rend_set.shade_geom^ (             {set for auto quad RGB, linear alpha}
      rend_iterp_mode_linear_k);
    rend_set.iterp_shade_mode^ (
      rend_iterp_alpha_k, rend_iterp_mode_linear_k);

    suprop_val.diff_red := 0.7; suprop_val.diff_grn := 0.7; suprop_val.diff_blu := 1.0;
    rend_set.suprop_val^ (rend_suprop_diff_k, suprop_val);
    rend_set.suprop_on^ (rend_suprop_trans_k, true); {enable transparent surface prop}
    coor1.x := 1.0; coor1.y := -0.2; coor1.z := -0.2;
    coor2.x := -0.2; coor2.y := 1.0; coor2.z := -0.2;
    coor3.x := -0.2; coor3.y := -0.2; coor3.z := 1.0;
    draw_tri (v1, v2, v3, norm_a);
    rend_set.suprop_on^ (rend_suprop_trans_k, false); {disable transparency}
    rend_set.alpha_on^ (false);        {turn alpha buffering back off}
    rend_set.iterp_on^ (rend_iterp_alpha_k, false); {turn alpha interpolant back off}

    rend_set.iterp_shade_mode^ (       {restore SHADE_MODE for RGB}
      rend_iterp_red_k, rgb_mode);
    rend_set.iterp_shade_mode^ (
      rend_iterp_grn_k, rgb_mode);
    rend_set.iterp_shade_mode^ (
      rend_iterp_blu_k, rgb_mode);
    end;

  if clear_on and (max_buf > 1) then begin {clear image and swap bufs after drawing ?}
    set_buf_clear;                     {set all state ready for clearing buffer}
    rend_prim.flip_buf^;               {flip buffers and clear new draw buf}
    end;

  rend_set.exit_rend^;
  end;
{
************************************************
*
*   Local subroutine ENABLE_EVENTS
}
procedure enable_events;

var
  i: sys_int_machine_t;                {scratch integer}

begin
  rend_set.event_req_close^ (true);    {enable events we care about}
  rend_set.event_req_resize^ (true);
  rend_set.event_req_wiped_resize^ (true);
  rend_set.event_req_wiped_rect^ (true);
  rend_set.event_req_rotate_on^ (1.0);
  rend_set.event_req_translate^ (true);

  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_arrow_left_k, 0),
    key_left_k);
  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_arrow_right_k, 0),
    key_right_k);
  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_arrow_up_k, 0),
    key_up_k);
  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_arrow_down_k, 0),
    key_down_k);

  i := 1;                              {init detail number of last pointer key}
  while rend_get.key_sp^(rend_key_sp_pointer_k, i) <> rend_key_none_k do begin
    i := i + 1;
    end;                               {back to check next pointer key number}
  i := i - 1;                          {make number of last pointer key}
  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_pointer_k, 1),
    key_pan_dolly_k);
  if i > 1 then begin                  {there is at least one more pointer key ?}
    rend_set.event_req_key_on^ (
      rend_get.key_sp^ (rend_key_sp_pointer_k, i),
      key_rot_k);
    end;

  if rend_get.key_sp^(rend_key_sp_func_k, 0) <> rend_key_none_k {F0 exists ?}
    then i := 0
    else i := 1;
  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_func_k, i),
    key_reset_k);
  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_func_k, i+1),
    key_clear_toggle_k);
  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_func_k, i+2),
    key_update_toggle_k);
  rend_set.event_req_key_on^ (
    rend_get.key_sp^ (rend_key_sp_func_k, i+3),
    key_dblbuf_toggle_k);
  end;
{
************************************************
*
*   Local subroutine DEVICES_OPEN
*
*   Open the RENDlib devices for the separate panes.
}
procedure devices_open;

begin
  if dev_name.len = 0 then begin       {assume no -DEV command line option used ?}
    string_copy (pane1_name, dev_name);
    end;
  rend_test_graphics_init;             {open main draw device}

  rend_open (pane2_name, pane2_dev, stat); {try to open pane 2}
  if sys_stat_match (rend_subsys_k, rend_stat_no_device_k, stat)
    then pane2_dev := rend_dev_none_k;
  rend_error_abort (stat, '', '', nil, 0);

  rend_open (pane3_name, pane3_dev, stat); {try to opne pane 3}
  if sys_stat_match (rend_subsys_k, rend_stat_no_device_k, stat)
    then pane3_dev := rend_dev_none_k;
  rend_error_abort (stat, '', '', nil, 0);

  rend_dev_set (rend_dev_id);          {swap back to main drawing device}
  rend_set.enter_rend^;                {leave in graphics mode}
  end;
{
************************************************
*
*   Start of main routine.
}
begin
  sys_error_none (stat);               {init to no error indicated}

  z_on := true;                        {init to Z compares turned on}
  no_alpha := false;                   {init to alpha buffered triangle allowed}
  yes_alpha := false;                  {init to alpha triangle not required}
  quad := false;                       {init to linear RGB}
  pane := false;                       {init to not break up current window}
  line := false;                       {init to draw whole triangle, not just edges}
  text := false;                       {init to not draw text}
  dev2_set := false;                   {init to no -DEVn command line options given}
  dev3_set := false;
  rend_test_cmline ('TEST_3DT');       {process canned command line args}
{
*   Back here for each new command line option.
}
next_opt:
  rend_test_cmline_token (opt, stat);  {get next command line option name}
  if string_eos(stat) then goto done_opts; {nothing more on command line ?}
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (                    {pick option name from list}
    opt,                               {option name}
    '-NOZ -QUAD -NOALPHA -PANES -ALPHA -LINE -TEXT -DEV2 -DEV3',
    pick);                             {number of picked option}
  case pick of                         {do routine for specific option}
{
*   -NOZ
*   Turn off Z buffer compares.
}
1: begin
  z_on := false;
  end;
{
*   -QUAD
*   Cause quadratic interpolation of RGB for solid objects.
}
2: begin
  quad := true;
  end;
{
*   -NOALPHA
*   Disallow alpha buffered triangle.
}
3: begin
  no_alpha := true;
  yes_alpha := false;
  end;
{
*   -PANES
}
4: begin
  pane := true;
  end;
{
*   -ALPHA
}
5: begin
  yes_alpha := true;
  no_alpha := false;
  end;
{
*   -LINE
}
6: begin
  line := true;
  end;
{
*   -TEXT
}
7: begin
  text := true;
  end;
{
*   -DEV2 <string>
}
8: begin
  rend_test_cmline_token (pane2_name, stat);
  dev2_set := true;
  pane := true;
  end;
{
*   -DEV3 <string>
}
9: begin
  rend_test_cmline_token (pane3_name, stat);
  dev3_set := true;
  pane := true;
  end;
{
*   Illegal command line option.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_bad', msg_parm, 1);
    end;                               {end of command line option cases}

  string_cmline_parm_check (stat, opt); {check for parm errors}
  goto next_opt;                       {back for next command line option}

done_opts:                             {done with all the command line options}
{
*   Done reading the command line options.
}
  if quad                              {force quadratic interpolation of RGB ?}
    then rgb_mode := rend_iterp_mode_quad_k
    else rgb_mode := rend_iterp_mode_linear_k;
{
*   Open the RENDlib device(s).
}
  if pane
    then begin                         {drawing is to multiple panes in curr window}
      devices_open;                    {open the devices for each pane}
      end                              {done handling -PANES case}
    else begin                         {-PANES not specified}
      rend_test_graphics_init;
      pane2_dev := rend_dev_none_k;    {indicate optional pane devices don't exist}
      pane3_dev := rend_dev_none_k;
      end
    ;
{
*   Set up RENDlib state for the main drawing pane.
}
  bmap_used := [                       {init to minimum bitmap components we need}
    rend_test_comp_red_k,
    rend_test_comp_grn_k,
    rend_test_comp_blu_k];
  if z_on then begin                   {also need a Z bitmap ?}
    bmap_used := bmap_used + [rend_test_comp_z_k];
    end;
  rend_test_bitmaps (bmap_used);       {create bitmaps and init interpolants}
  rend_get.xform_3d^ (cxb, cyb, czb, cofs); {init our copy of 3D transform matrix}
  rend_set.backface^ (rend_bface_flip_k);
  rend_set.new_view^;

  rend_set.vert3d_ent_all_off^;
  rend_set.vert3d_ent_on^ (            {enable XYZ coordinate pointer in vert desc}
    rend_vert3d_coor_p_k,
    sys_int_adr_t(addr(v.coor_p)) - sys_int_adr_t(addr(v)));
  rend_set.vert3d_ent_on^ (            {enable RGB color pointer in vert desc}
    rend_vert3d_diff_p_k,
    sys_int_adr_t(addr(v.diff_p)) - sys_int_adr_t(addr(v)));

  rend_get.vect_parms^ (vect_parms);   {get current vector parameters}
  vect_parms.poly_level := rend_space_2dimcl_k;
  vect_parms.width := 3.0;
  vect_parms.start_style.style := rend_end_style_circ_k;
  vect_parms.start_style.nsides := 6;
  vect_parms.end_style.style := rend_end_style_circ_k;
  vect_parms.end_style.nsides := 6;
  vect_parms.subpixel := true;
  rend_set.vect_parms^ (vect_parms);

  rend_get.text_parms^ (tparm);        {get current text control parameters}
  tparm.coor_level := rend_space_3dpl_k;
  tparm.size := 0.1;
  tparm.width := 0.8;
  tparm.start_org := rend_torg_mid_k;
  tparm.vect_width := 0.15;
  tparm.poly := not line;
  rend_set.text_parms^ (tparm);        {set to our text parameters}

  clear_on := true;                    {init to clear image before redraw}
  update_on := true;                   {init to update image on REDRAW call}
  sw_on := force_sw;                   {SW emulation will be used if forced ON}

  p1.x := 0.0;
  p1.y := 0.0;
  case rgb_mode of
rend_iterp_mode_linear_k: begin        {set RGB to linear interpolation}
      rend_set.iterp_linear^ (
        rend_iterp_red_k, p1, 0.0, 0.1, 0.1);
      rend_set.iterp_linear^ (
        rend_iterp_grn_k, p1, 0.0, 0.1, 0.1);
      rend_set.iterp_linear^ (
        rend_iterp_blu_k, p1, 0.0, 0.1, 0.1);
      end;
rend_iterp_mode_quad_k: begin          {set RGB to quadratic interpolation}
      rend_set.iterp_quad^ (
        rend_iterp_red_k, p1, 0.0, 0.1, 0.1, 0.1, 0.1, 0.1);
      rend_set.iterp_quad^ (
        rend_iterp_grn_k, p1, 0.0, 0.1, 0.1, 0.1, 0.1, 0.1);
      rend_set.iterp_quad^ (
        rend_iterp_blu_k, p1, 0.0, 0.1, 0.1, 0.1, 0.1, 0.1);
      end;
    end;                               {end of RGB_MODE cases}
  rend_set.iterp_shade_mode^ (         {set SHADE_MODE for RGB}
    rend_iterp_red_k, rgb_mode);
  rend_set.iterp_shade_mode^ (
    rend_iterp_grn_k, rgb_mode);
  rend_set.iterp_shade_mode^ (
    rend_iterp_blu_k, rgb_mode);
  rend_set.shade_geom^ (rgb_mode);     {set shading geometry to match RGB mode}

  if z_on then begin                   {Z buffering turned on ?}
    rend_set.dev_z_curr^ (true);       {pretend device Z buffer is up to date}
    rend_set.iterp_linear^ (           {set Z interpolant to linear interpolation}
      rend_iterp_z_k, p1, 0.0, 0.1, 0.1);
    rend_set.iterp_shade_mode^ (       {set Z SHADE_MODE to linear}
      rend_iterp_z_k, rend_iterp_mode_linear_k);
    end;
{
*   Determine whether software emulation will be required for drawing the background.
*   This is only the case if the solid triangles read from the software bitmap, and
*   therefore assume it is up to date.
}
  if not force_sw then begin           {don't bother if know we need SW emulation}
    if z_on then begin                 {Z buffering turned on ?}
      rend_set.zon^ (true);            {we will need to do Z buffering}
      end;
    rend_set.start_group^;
    if line
      then begin                       {will be using LINE_3D primitive}
        rend_get.reading_sw_prim^ (    {find if LINE_3D reads SW bitmap}
          rend_prim.line_3d,           {primitive to inquire about}
          force_sw);                   {TRUE if reads from SW bitmap}
        rend_get.update_sw_prim^ (     {find if LINE_3D uses SW emulation}
          rend_prim.line_3d,           {primitive to inquire about}
          sw_on);                      {TRUE if SW emulation used}
        end
      else begin                       {will be using TRI_3D primitive}
        rend_get.reading_sw_prim^ (    {find if TRI_3D reads SW bitmap}
          rend_prim.tri_3d,            {primitive to inquire about}
          force_sw);                   {TRUE if reads from SW bitmap}
        rend_get.update_sw_prim^ (     {find if TRI_3D uses SW emulation}
          rend_prim.tri_3d,            {primitive to inquire about}
          sw_on);                      {TRUE if SW emulation used}
        end
      ;
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
    rend_get.update_sw_prim^ (rend_prim.tri_3d, on); {check SW emulation flag}
    rend_set.end_group^;
    if not on then goto done_min_bits; {BITS_VIS setting now not force SW updates ?}
    bits_vis := bits_vis - 1.0;        {try a little smaller BITS_VIS value}
    if bits_vis <= min_bits_vis_req then begin {degraded far enough ?}
      if max_buf > 1 then begin        {requesting more than one buffer ?}
        max_buf := 1;                  {two didn't work, try single buffering}
        bits_vis := 24.0;              {reset BITS_VIS request}
        goto min_bits_loop;            {back and try while requesting just 1 buffer}
        end;
      sw_on := true;                   {giving up, we will use SW emulation}
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
  max_buf_available := max_buf;        {save max buffers to use ever}
{
*   SW_ON is TRUE if the basic mandatory drawing modes require software emulation.
*   Now determine whether the alpha buffered triangle should be drawn.  This is
*   drawn only as long as it is not the cause for software emulation.
*   In other words, if SW_ON is currently FALSE, but drawing the alpha buffered
*   trianlge would require software emulation, then don't draw it, otherwise go ahead.
}
  rend_set.alpha_on^ (true);           {turn on alpha buffering}
  rend_set.iterp_on^ (rend_iterp_alpha_k, true); {turn on alpha interpolant}
  rend_set.iterp_shade_mode^ (         {set SHADE_MODE for RGB}
    rend_iterp_red_k, rend_iterp_mode_quad_k);
  rend_set.iterp_shade_mode^ (
    rend_iterp_grn_k, rend_iterp_mode_quad_k);
  rend_set.iterp_shade_mode^ (
    rend_iterp_blu_k, rend_iterp_mode_quad_k);
  rend_set.shade_geom^ (               {set for auto quad RGB, linear alpha}
    rend_iterp_mode_linear_k);
  rend_set.iterp_shade_mode^ (
    rend_iterp_alpha_k, rend_iterp_mode_linear_k);
  if line
    then begin                         {will be using LINE_3D primitive}
      rend_get.reading_sw_prim^ (      {find if LINE_3D reads SW bitmap}
        rend_prim.line_3d,             {primitive to inquire about}
        read_sw);                      {TRUE if reads from SW bitmap}
      rend_get.update_sw_prim^ (       {find if LINE_3D uses SW emulation}
        rend_prim.line_3d,             {primitive to inquire about}
        write_sw);                     {TRUE if SW emulation used}
      end
    else begin                         {will be using TRI_3D primitive}
      rend_get.reading_sw_prim^ (      {find if TRI_3D reads SW bitmap}
        rend_prim.tri_3d,              {primitive to inquire about}
        read_sw);                      {TRUE if reads from SW bitmap}
      rend_get.update_sw_prim^ (       {find if TRI_3D uses SW emulation}
        rend_prim.tri_3d,              {primitive to inquire about}
        write_sw);                     {TRUE if SW emulation used}
      end
    ;
  rend_set.alpha_on^ (false);          {reset modes}
  rend_set.iterp_on^ (rend_iterp_alpha_k, false);
  rend_set.iterp_shade_mode^ (         {set SHADE_MODE for RGB}
    rend_iterp_red_k, rgb_mode);
  rend_set.iterp_shade_mode^ (
    rend_iterp_grn_k, rgb_mode);
  rend_set.iterp_shade_mode^ (
    rend_iterp_blu_k, rgb_mode);
  rend_set.shade_geom^ (rgb_mode);     {set shading geometry to match RGB mode}
  rend_set.cmode_vals^ (cmode_vals);   {reset to state before this test case}
{
*   READ_SW is TRUE if the alpha buffered triangle would read from the software bitmap
*   and WRITE_SW is TRUE if the alpha buffered triangle would write to the
*   software bitmap.
}
  alpha_on := sw_on or (not write_sw); {default alpha ON/OFF}
  alpha_on := alpha_on or yes_alpha;   {take -ALPHA switch into account}
  alpha_on := alpha_on and (not no_alpha); {take -NOALPHA switch into account}
  force_sw := force_sw or              {alpha on and requires SW emulation ?}
    (alpha_on and write_sw);
  rend_set.force_sw_update^ (force_sw); {force SW updates on, if necessary}
  rend_get.cmode_vals^ (cmode_vals);   {save changeable mode state here}
  rend_set.exit_rend^;
{
*   Set up RENDlib state for window pane 2.
}
  if pane2_dev <> rend_dev_none_k then begin
    rend_dev_set (pane2_dev);
    rend_set.enter_rend^;
    enable_events;
    rend_set.min_bits_vis^ (1);
    rend_set.iterp_on^ (rend_iterp_red_k, true);
    rend_set.iterp_on^ (rend_iterp_grn_k, true);
    rend_set.iterp_on^ (rend_iterp_blu_k, true);
    rend_set.rgb^ (pane2_rgb.red, pane2_rgb.grn, pane2_rgb.blu);
    rend_set.exit_rend^;
    end;
{
*   Set up RENDlib state for window pane 3.
}
  if pane3_dev <> rend_dev_none_k then begin
    rend_dev_set (pane3_dev);
    rend_set.enter_rend^;
    enable_events;
    rend_set.min_bits_vis^ (1);
    rend_set.iterp_on^ (rend_iterp_red_k, true);
    rend_set.iterp_on^ (rend_iterp_grn_k, true);
    rend_set.iterp_on^ (rend_iterp_blu_k, true);
    rend_set.rgb^ (pane3_rgb.red, pane3_rgb.grn, pane3_rgb.blu);
    rend_set.exit_rend^;
    end;

  rend_event_req_stdin_line (false);
{
*   Configuration is now all decided.  Init the first displayed image.
}
  rend_dev_set (rend_dev_id);          {set RENDlib to main drawing pane}
  rend_set.enter_rend^;
  enable_events;
  rend_set.disp_buf^ (1);              {init to displaying first buffer}
  rend_set.draw_buf^ (2);              {draw into second buffer if double buf on}
  rend_set.exit_rend^;

  refresh1 := true;                    {flag everything as needing to be refreshed}
  refresh2 := true;
  refresh3 := true;
  refresh_any := true;
  wiped1 := true;
{
*   Come back here to redraw whatever is necessary.
}
refresh:
  if wiped1 and (max_buf > 1) then begin {explicitly clear drawing buffer ?}
    rend_set.enter_rend^;
    set_buf_clear;                     {set state ready for clearing buffer}
    rend_prim.clear_cwind^;            {clear current drawing buffer to background}
    rend_set.exit_rend^;
    end;

  if refresh1 then begin               {pane 1 needs to be refreshed ?}
    rend_dev_set (rend_dev_id);        {set RENDlib device to pane 1}
    redraw;                            {refresh pane 1}
    end;

  if refresh2 and (pane2_dev <> rend_dev_none_k) then begin
    rend_dev_set (pane2_dev);
    rend_set.enter_rend^;
    rend_prim.clear_cwind^;
    rend_set.exit_rend^;
    end;

  if refresh3 and (pane3_dev <> rend_dev_none_k) then begin
    rend_dev_set (pane3_dev);
    rend_set.enter_rend^;
    rend_prim.clear_cwind^;
    rend_set.exit_rend^;
    end;

  refresh1 := false;                   {indicate no more pending refreshes}
  wiped1 := false;
  refresh2 := false;
  refresh3 := false;
  refresh_any := false;
{
*   Main loop.  Come back here to get each new command event.
}
event_wait:
  rend_set.enter_level^ (0);           {make sure we are out of graphics mode}
  if refresh_any
    then begin                         {there are pending refreshes}
      rend_event_get_nowait (event);   {get next event, none if there is none}
      end
    else begin                         {there are no pending refreshes}
      rend_event_get (event);          {get next event, wait until there is one}
      end
    ;
  case event.ev_type of                {what kind of event is this ?}
{
*   All pending events have been exhausted.  It is now time to take care of
*   any pending refreshes.
}
rend_ev_none_k: begin                  {there are no pending events}
  goto refresh;                        {do any pending refreshes}
  end;
{
***********************
*
*   One of the panes has been closed, the user asked us to close it,
*   or the user hit RETURN at the STDIN line.   We will exit the program.
}
rend_ev_close_k,
rend_ev_close_user_k,
rend_ev_stdin_line_k: begin
  rend_dev_set (rend_dev_id);          {swap in main drawing device}
  user_wait := false;                  {don't wait on user any more to exit}
  rend_test_end;                       {exit in standard way for our test routines}
  return;                              {exit the program}
  end;
{
***********************
*
*   Some pixels got wiped out, and are now drawable again.
}
rend_ev_wiped_rect_k,
rend_ev_wiped_resize_k: begin
  refresh1 := refresh1 or (event.dev = rend_dev_id);
  wiped1 := wiped1 or (event.dev = rend_dev_id);
  refresh2 := refresh2 or (event.dev = pane2_dev);
  refresh3 := refresh3 or (event.dev = pane3_dev);
  refresh_any := true;
  end;
{
***********************
*
*   The size of one of the panes changed.  We only really care about the
*   size of the main draw area changing.
}
rend_ev_resize_k: begin
  if event.dev <> rend_dev_id          {not the main drawing area ?}
    then goto event_done;
  rend_dev_set (rend_dev_id);          {set RENDlib device to main draw area}
  rend_set.enter_rend^;                {enter graphics mode on main draw area}
  rend_test_resize;                    {update state to new draw area size}
  end;
{
***********************
*
*   3D transformation event.
}
rend_ev_xf3d_k: begin
  if rend_ev3d_abs_k in event.xf3d.comp
    then begin                         {this is an absolute transform}
      cxb := event.xf3d.mat.m33.xb;    {replace current matrix}
      cyb := event.xf3d.mat.m33.yb;
      czb := event.xf3d.mat.m33.zb;
      cofs := event.xf3d.mat.ofs;
      end
    else begin                         {this is a relative transform}
      mat.m33.xb.x :=                  {postmultiply to current matrix}
        (cxb.x * event.xf3d.mat.m33.xb.x) +
        (cxb.y * event.xf3d.mat.m33.yb.x) +
        (cxb.z * event.xf3d.mat.m33.zb.x);
      mat.m33.xb.y :=
        (cxb.x * event.xf3d.mat.m33.xb.y) +
        (cxb.y * event.xf3d.mat.m33.yb.y) +
        (cxb.z * event.xf3d.mat.m33.zb.y);
      mat.m33.xb.z :=
        (cxb.x * event.xf3d.mat.m33.xb.z) +
        (cxb.y * event.xf3d.mat.m33.yb.z) +
        (cxb.z * event.xf3d.mat.m33.zb.z);

      mat.m33.yb.x :=
        (cyb.x * event.xf3d.mat.m33.xb.x) +
        (cyb.y * event.xf3d.mat.m33.yb.x) +
        (cyb.z * event.xf3d.mat.m33.zb.x);
      mat.m33.yb.y :=
        (cyb.x * event.xf3d.mat.m33.xb.y) +
        (cyb.y * event.xf3d.mat.m33.yb.y) +
        (cyb.z * event.xf3d.mat.m33.zb.y);
      mat.m33.yb.z :=
        (cyb.x * event.xf3d.mat.m33.xb.z) +
        (cyb.y * event.xf3d.mat.m33.yb.z) +
        (cyb.z * event.xf3d.mat.m33.zb.z);

      mat.m33.zb.x :=
        (czb.x * event.xf3d.mat.m33.xb.x) +
        (czb.y * event.xf3d.mat.m33.yb.x) +
        (czb.z * event.xf3d.mat.m33.zb.x);
      mat.m33.zb.y :=
        (czb.x * event.xf3d.mat.m33.xb.y) +
        (czb.y * event.xf3d.mat.m33.yb.y) +
        (czb.z * event.xf3d.mat.m33.zb.y);
      mat.m33.zb.z :=
        (czb.x * event.xf3d.mat.m33.xb.z) +
        (czb.y * event.xf3d.mat.m33.yb.z) +
        (czb.z * event.xf3d.mat.m33.zb.z);

      mat.ofs.x :=
        (cofs.x * event.xf3d.mat.m33.xb.x) +
        (cofs.y * event.xf3d.mat.m33.yb.x) +
        (cofs.z * event.xf3d.mat.m33.zb.x) +
        event.xf3d.mat.ofs.x;
      mat.ofs.y :=
        (cofs.x * event.xf3d.mat.m33.xb.y) +
        (cofs.y * event.xf3d.mat.m33.yb.y) +
        (cofs.z * event.xf3d.mat.m33.zb.y) +
        event.xf3d.mat.ofs.y;
      mat.ofs.z :=
        (cofs.x * event.xf3d.mat.m33.xb.z) +
        (cofs.y * event.xf3d.mat.m33.yb.z) +
        (cofs.z * event.xf3d.mat.m33.zb.z) +
        event.xf3d.mat.ofs.z;

      cxb := mat.m33.xb;               {update local copy of current transform}
      cyb := mat.m33.yb;
      czb := mat.m33.zb;
      cofs := mat.ofs;
      end
    ;

  cofs.x := min(0.9, max(-0.9, cofs.x)); {clip offset to small volume around origin}
  cofs.y := min(0.9, max(-0.9, cofs.y));
  cofs.z := min(0.9, max(-0.9, cofs.z));

  refresh1 := true;                    {flag image as being out of date}
  refresh_any := true;
  end;
{
***********************
*
*   The 2D pointer left our window.
}
rend_ev_pnt_exit_k: begin
  rend_set.event_req_pnt^ (false);     {diable any pointer events}
  rend_set.event_mode_pnt^ (rend_pntmode_direct_k); {disable funny pointer handling}
  end;
{
***********************
*
*   The state of one of our keys changed.
}
rend_ev_key_k: begin
  rend_set.event_req_pnt^ (false);     {diable any pointer events}
  rend_set.event_mode_pnt^ (rend_pntmode_direct_k); {disable funny pointer handling}
  if not event.key.down then goto event_done; {we only care about down transitions}

  case event.key.key_p^.id_user of     {which one of our keys is this ?}

key_left_k: begin                      {left arrow key}
      if rend_key_mod_shift_k in event.key.modk
        then begin                     {translate left}
          cofs.x := max(-0.9, cofs.x - trans_increment);
          end
        else begin                     {rotate left}
          rotate (0.0, -rot_increment, 0.0)
          end
        ;
      end;

key_right_k: begin                     {right arrow key}
      if rend_key_mod_shift_k in event.key.modk
        then begin                     {translate right}
          cofs.x := min(0.9, cofs.x + trans_increment);
          end
        else begin                     {rotate right}
          rotate (0.0, rot_increment, 0.0)
          end
        ;
      end;

key_up_k: begin                        {up arrow key}
      if rend_key_mod_ctrl_k in event.key.modk
        then begin                     {translate back}
          cofs.z := max(-0.9, cofs.z - trans_increment);
          end
        else if rend_key_mod_shift_k in event.key.modk then begin {translate up}
          cofs.y := min(0.9, cofs.y + trans_increment);
          end
        else begin                     {rotate up}
          rotate (-rot_increment, 0.0, 0.0);
          end
        ;
      end;

key_down_k: begin                      {down arrow key}
      if rend_key_mod_ctrl_k in event.key.modk
        then begin                     {translate forwards}
          cofs.z := min(0.9, cofs.z + trans_increment);
          end
        else if rend_key_mod_shift_k in event.key.modk then begin {translate down}
          cofs.y := max(-0.9, cofs.y - trans_increment);
          end
        else begin                     {rotate down}
          rotate (rot_increment, 0.0, 0.0);
          end
        ;
      end;

key_reset_k: begin                     {key to reset transform}
      cxb.x := 1.0; cxb.y := 0.0; cxb.z := 0.0;
      cyb.x := 0.0; cyb.y := 1.0; cyb.z := 0.0;
      czb.x := 0.0; czb.y := 0.0; czb.z := 1.0;
      cofs.x := 0.0; cofs.y := 0.0; cofs.z := 0.0;
      clear_on := true;
      update_on := true;
      end;

key_clear_toggle_k: begin              {key to toggle clear mode}
      clear_on := not clear_on;        {toggle clear mode}
      end;

key_update_toggle_k: begin             {key to toggle update mode}
      update_on := not update_on;      {toggle update mode}
      end;

key_dblbuf_toggle_k: begin             {key to toggle double buffer mode}
      rend_get.max_buf^ (max_buf);     {get current max buffers in rendlib}
      if max_buf = 1                   {make new desired double buffering state}
        then max_buf := 2
        else max_buf := 1;
      max_buf := min(max_buf_available, max_buf); {clip to our own max buf rule}
      rend_set.max_buf^ (max_buf);     {toggle to new double buffering state}
      rend_get.max_buf^ (max_buf);     {update our local copy of max buffers value}
      if max_buf = 2 then begin        {just switched to double buffering mode ?}
        rend_set.draw_buf^ (2);        {set drawing to the back buffer}
        end;
      wiped1 := true;
      end;

key_pan_dolly_k: begin                 {key to pan or dolly the camera}
      if rend_key_mod_shift_k in event.key.modk
        then begin                     {dolly}
          rend_set.event_mode_pnt^ (rend_pntmode_dolly_k);
          end
        else begin                     {pan}
          rend_set.event_mode_pnt^ (rend_pntmode_pan_k);
          end
        ;
      rend_set.event_req_pnt^ (true);  {enable pointer events}
      end;

key_rot_k: begin                       {key to rotate object about origin}
      rend_set.event_mode_pnt^ (rend_pntmode_rot_k);
      rend_set.event_req_pnt^ (true);  {enable pointer events}
      end;

    end;                               {end of which key cases}
  refresh1 := true;
  refresh_any := true;
  end;                                 {end of event type is key state change}
{
*   End of different event type cases.
}
    end;                               {end of event type cases}

event_done:                            {end up here when done with current event}
  goto event_wait;
  end.
