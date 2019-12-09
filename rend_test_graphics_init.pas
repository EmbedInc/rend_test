{   Subroutine REND_TEST_GRAPHICS_INIT
*
*   Init the graphics based on the state found in the common block.  The
*   RENDlib output device will be selected and state updated based on the
*   actual selection.
*
*   NOTE:  This routine will leave RENDlib in graphics mode.  If the calling program
*     does not do graphics immediately following this call, it should call
*     REND_SET.EXIT_REND^.
}
module rend_test_GRAPHICS_INIT;
define rend_test_graphics_init;
%include 'rend_test2.ins.pas';

procedure rend_test_graphics_init;     {initialize graphics from common block state}

var
  vert: rend_test_vert3d_t;            {3D vertex, for finding field offsets}
  vect_parms: rend_vect_parms_t;       {current vector drawing parameters}
  poly_parms: rend_poly_parms_t;       {polygon drawing parameters}
  szx, szy: sys_int_machine_t;         {requested image size values}
  ix, iy: sys_int_machine_t;           {scratch integer values and coordinates}
  asp: real;                           {requested image apsect ratio}
  a: real;
  stat: sys_err_t;

label
  retry_aaoff;

begin
  rend_start;                          {wake up RENDlib}

  rend_open (dev_name, rend_dev_id, stat); {open our main drawing RENDlib device}
  sys_error_abort (stat, 'rend', 'rend_open', nil, 0);

  user_wait := rend_get.close_corrupt^; {flag wait for user EXIT if display corrupted}
  rend_set.enter_rend^;                {enter graphics mode}
{
*   Determine final graphics output resolution.
}
  if not aspect_set then begin         {ASPECT not already set explicitly ?}
    aspect := image_width / image_height; {assume square pixels}
    end;

  if                                   {don't allow anti-aliasing ?}
      (not img_on) or                  {not writing an image file ?}
      (not size_set)                   {user doesn't care about image size ?}
      then begin
    aa.nx := 1;                        {disable anti-aliasing}
    aa.ny := 1;
    aa.uset := false;                  {pretend user never asked for it}
    end;

retry_aaoff:                           {back here to retry with anti-aliasing off}
  aa.on := (aa.nx > 1) or (aa.ny > 1); {TRUE if anti-aliasing requested}
  szx := image_width;                  {get initial image config requests}
  szy := image_height;
  asp := aspect;
  if aa.on then begin                  {anti-aliasing requested ?}
    rend_set.aa_scale^ (1.0/aa.nx, 1.0/aa.ny); {set anti-aliasing scale factor}
    rend_get.aa_border^ (              {find number of pixels to add around edge}
      aa.borderx, aa.bordery);
    szx := (szx * aa.nx) + (2 * aa.borderx); {make total bitmap size in pixels}
    szy := (szy * aa.ny) + (2 * aa.bordery);
    asp :=                             {adjust aspect ratio for new bitmap size}
      aspect * (szx / szy) / (image_width / image_height);
    end;

  rend_set.image_size^ (szx, szy, asp); {try to configure image the way we want it}
  rend_get.image_size^ (ix, iy, a);    {find out what we ended up with}
  if                                   {didn't get exact anti-aliasing config ?}
      aa.on and                        {anti-aliasing on ?}
      ((ix <> szx) or (szy <> iy) or   {not got requested image size ?}
      (abs(a - asp) > 1.0E-5))         {not got requested aspect ratio ?}
      then begin
    aa.nx := 1;                        {disable anti-aliasing}
    aa.ny := 1;
    aa.uset := false;                  {pretend user never asked for it}
    goto retry_aaoff;                  {re-try with anti-aliasing off}
    end;

  if not aa.on then begin              {anti-aliasing is not being used ?}
    aa.borderx := 0;
    aa.bordery := 0;
    end;
  rend_get.image_size^ (               {image raw bitmap config we ended up with}
    image_width, image_height, aspect);
  rend_test_recompute_aa;              {set all derivable anti-aliasing state}
  aa.done := false;                    {init to anti-aliasing not performed yet}

  if aa.aspect >= 1.0
    then begin                         {image is wider than tall}
      width_2d := aa.aspect;
      height_2d := 1.0;
      end
    else begin                         {image is taller than wide}
      width_2d := 1.0;
      height_2d := 1.0 / aa.aspect;
      end
    ;
{
*   Determine the vector drawing parameters.
}
  rend_get.vect_parms^ (vect_parms);
  vect_parms.width :=                  {vector width in pixels, if enabled}
    wire_thickness * min(aa.subpixx, aa.subpixy);
  if vect_parms.width >= (wire_thick_thresh / ((aa.nx + aa.ny)*0.5))
    then begin                         {thickness is wide enough to allow its use}
      wire_thick_on := true;           {remember we are using wide vectors}
      vect_parms.poly_level := rend_space_2dimcl_k; {enable thickening in pixel space}
      end
    else begin                         {too thin to allow vector thickening}
      wire_thick_on := false;
      vect_parms.poly_level := rend_space_none_k;
      end
    ;
  vect_parms.subpixel := subpix_vect;  {set vector subpixel addressing ON/OFF}
  rend_set.vect_parms^ (vect_parms);
{
*   Set the polygon drawing modes.
}
  rend_get.poly_parms^ (poly_parms);
  poly_parms.subpixel := subpix_poly;  {set polygon subpixel addressing ON/OFF}
  rend_set.poly_parms^ (poly_parms);
{
*   Determine whether to force software emulation for all drawing.
}
  force_sw := force_sw or img_on;      {image file output requires SW emulation}
  force_sw := force_sw or aa.on;       {force SW emulation if anti-aliasing enabled}
  rend_set.force_sw_update^ (force_sw);
{
*   Init the image output file comments in case an image file is written.
}
  rend_get.comments_list^ (comm_p);    {get pointer to image output file comments}

  string_list_line_add (comm_p^);      {make a new image file comment line}
  sys_date_time1 (comm_p^.str_p^);     {write date and time}
  string_appends (comm_p^.str_p^, '  Created by program');
  string_append1 (comm_p^.str_p^, ' ');
  string_append (comm_p^.str_p^, prog_name);
  string_append1 (comm_p^.str_p^, '.');

  string_list_pos_abs (comments, 1);   {go to first user comment line, if any}
  while comments.str_p <> nil do begin {once for each comment line in list}
    string_list_line_add (comm_p^);    {create new image file comment line}
    string_vstring (comm_p^.str_p^, '  '(0), -1); {indent for not a new heading}
    string_append (comm_p^.str_p^, comments.str_p^); {copy comment to this line}
    string_list_pos_rel (comments, 1); {advance to next user comment line}
    end;
{
*   Init some other state that might get used.
}
  version_vcache := rend_cache_version_invalid + 1; {init RENDlib cache version}
  rend_set.cache_version^ (version_vcache);

  rend_set.vert3d_ent_all_off^;        {set up 3D vertex to match our data structure}
  rend_set.vert3d_ent_on^ (            {declare offset of 3D coordinate pointer}
    rend_vert3d_coor_p_k,
    sys_int_adr_t(addr(vert.coor_p)) - sys_int_adr_t(addr(vert)));
  rend_set.vert3d_ent_on^ (            {declare offset of vertex cache pointer}
    rend_vert3d_vcache_p_k,
    sys_int_adr_t(addr(vert.vcache_p)) - sys_int_adr_t(addr(vert)));
  case shade_mode of
rend_test_shmode_linear_k: begin
      rend_set.vert3d_ent_on^ (        {declare offset of shading normal pointer}
        rend_vert3d_norm_p_k,
        sys_int_adr_t(addr(vert.norm_p)) - sys_int_adr_t(addr(vert)));
      end;
    end;
{
*   Set up interpolant shade modes.
}
  case shade_mode of
rend_test_shmode_linear_k,
rend_test_shmode_facet_k: begin
      rend_set.iterp_shade_mode^ (rend_iterp_red_k, rend_iterp_mode_linear_k);
      rend_set.iterp_shade_mode^ (rend_iterp_grn_k, rend_iterp_mode_linear_k);
      rend_set.iterp_shade_mode^ (rend_iterp_blu_k, rend_iterp_mode_linear_k);
      end;
rend_test_shmode_flat_k: begin
      rend_set.iterp_shade_mode^ (rend_iterp_red_k, rend_iterp_mode_linear_k);
      rend_set.iterp_shade_mode^ (rend_iterp_grn_k, rend_iterp_mode_linear_k);
      rend_set.iterp_shade_mode^ (rend_iterp_blu_k, rend_iterp_mode_linear_k);
      end;
    end;
  rend_set.iterp_shade_mode^ (rend_iterp_z_k, rend_iterp_mode_linear_k);
{
*   Init clipping state.
}
  rend_get.clip_2dim_handle^ (rend_test_clip_handle); {create a clip handle}
  rend_test_clip_all_off;              {init master clip rect to full area}
{
*   Init transforms.
}
  rend_test_xform2d (xform_2d.xb, xform_2d.yb, xform_2d.ofs);

  rend_set.xform_3d^ (
    xform_3d.m33.xb,
    xform_3d.m33.yb,
    xform_3d.m33.zb,
    xform_3d.ofs);
{
*   Enable the events used by the REND_TEST_REFRESH function.
}
  rend_set.event_req_close^ (true);    {enable events we care about}
  rend_set.event_req_wiped_resize^ (true);
  rend_set.event_req_wiped_rect^ (true);
  rend_event_req_stdin_line (true);
{
*   Init other modes.
}
  rend_set.light_accur^ (lighting_accuracy);
  rend_set.tmap_accur^ (tmap_accuracy);
  rend_set.tmap_filt^ (tmap_filt);
  rend_set.update_mode^ (update_mode);
  if set_bits_vis then begin           {BITS_VIS was explicitly set ?}
    rend_set.min_bits_vis^ (bits_vis);
    end;
  rend_set.eyedis^ (eye_dist);
  rend_set.perspec_on^ (perspective);
  rend_set.new_view^;
  comp_bitmaps := [];                  {init to no components connected to bitmaps}

  rend_set.cirres^ (cirres1);          {set all CIRRES values from CIRRES 1}
  rend_set.cirres_n^ (2, cirres2);     {set only CIRRES 2}
  end;
