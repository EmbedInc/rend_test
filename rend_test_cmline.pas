module rend_test_cmline;
define rend_test_cmline;
define rend_test_cmline_fp;
define rend_test_cmline_int;
define rend_test_cmline_token;
%include 'rend_test2.ins.pas';
{
****************************************************************
*
*   Subroutine REND_TEST_CMLINE (PROG)
*
*   Read the command line and process the tokens we understand.  The remaining
*   tokens will be put into CMLINE for the application program to handle.
*   PROG must be the program name.
*
*   The command line options handled here are:
*
*   -DEV <device name> [<optional parameters>]
*
*     Specify the RENDlib device to use.  The device names may be translated
*     thru the rendlib.dev environtment file set.
*
*   -IMG
*
*     Write the result of the drawing to an image file.  Currently, this forces
*     software emulation.  The generic image file name will be the program name.
*
*   -INAME <image file name>
*
*     Same as -IMG, above, except that the image file name is given explicitly.
*
*   -SW
*
*     Force software emulation always on regardless of whether it is really
*     necessary for correct drawing.  The default is to only force software
*     emulation when necessary.
*
*   -SIZE ix iy
*
*     Declare desired image size in pixels.  The requested size may not be
*     possible if also drawing to hardware.  The default size is the size of the
*     hardware draw area in use, if any.  Otherwise the default is set by the
*     constants DEFAULT_IMAGE_WIDTH and DEFAULT_IMAGE_HEIGHT in REND_TEST.INS.PAS.
*
*   -LIGHT_EXACT
*
*     Require that the RENDlib lighting model be followed exactly.  The default
*     is to allow small errors if speedups are available on the current device.
*
*   -BIT_VIS n
*
*     Request a minimum effective visible color resolution in bits/pixel.
*     The default may vary from program to program.  For most programs, the
*     default is either the maximum of mimimum color resolution available.
*
*   -ASPECT width height
*
*     Specify the whole image aspect ratio.  This may have no effect on some
*     output devices.  The default is to assume square pixels.
*
*   -RAY
*
*     Request ray tracing.  It is up each application how it reacts
*     to this switch.
*
*   -CIRRES n
*   -CIRRES1 n
*   -CIRRES2 n
*
*     Set the number of line segments to be used to approximate a circle.
*     CIRRES 1 and 2 are used for major and minor angle parameters, such as would
*     exist when drawing a torus.  -CIRRES sets both these to the same value.
*     This value must be an integer no less than 4.  The default is 20.
*
*   -WIRE
*
*     Request wire frame rendering.  It is up to each application how it reacts
*     to this switch.
*
*   -THICK t
*
*     Set the wire frame vector thickness.  The thickness parameter is in units
*     of pixels for an image which has 512 as its minimum dimension.  Therefore,
*     if T is set to 1.5, then vectors will be 3 pixels wide on a 1280x1024 image.
*     The thickness does not actually kick in unless the resulting thickness
*     is at least two pixels.  The default is T = 1.0.
*
*   -FACET
*
*     Request facet shading.  The default is linear (Gouraud) shading.
*
*   -FLAT
*
*     Request facet shading.  The default is linear (Gouraud) shading.
*
*   -NPERSP
*
*     Turn perspective OFF.  The default is perspective is ON.
*
*   -SUBPIXV
*
*     Request that vectors be drawn using subpixel addressing.
*
*   -NSUBPIXP
*
*     Request that polygons be drawn without subpixel addressing.
*
*   -UDPATE <update mode>
*
*     Indicate the desired display update mode.  Mode names are
*     LIVE or BUFFALL.  The default is LIVE.
*
*   -COM <comment string>
*
*     Define a comment string.  It is up to each program what to do with this
*     string.  Programs that use this feature will generally write the comment
*     string to the image.  Any number of -COM command line arguments may be
*     given.  Each -COM adds one line to the bottom of the comment lines.
*
*   -XF2D xbx xby  ybx yby  ofsx ofsy
*
*     Set initial 2D transform.
*
*   -EYEDIS e
*
*     Set eye distance perspective factor.  Default is 3.3333.  Smaller
*     values result in more extreme perspective.
*
*   -ROTX a
*   -ROTY a
*   -ROTZ a
*
*     Perform incremental rotation about the selected axis.  The angle values
*     are in units of half circles.  A value os 0.5 therefore results in a
*     PI/2 rotation.
*
*     The incremental transform specified by this command line option is
*     post-multiplied by the 3D transform accumulated so far.  The result
*     becomes the new 3D transform.  The 3D transform is initialized to
*     identity before any command line options are processed.
*
*   -OFS3D dx dy dz
*
*     Offset the 3D model space origin.
*
*     The incremental transform specified by this command line option is
*     post-multiplied by the 3D transform accumulated so far.  The result
*     becomes the new 3D transform.  The 3D transform is initialized to
*     identity before any command line options are processed.
*
*   -SCALE3D m
*
*     Uniformly scale the 3D model space.
*
*     The incremental transform specified by this command line option is
*     post-multiplied by the 3D transform accumulated so far.  The result
*     becomes the new 3D transform.  The 3D transform is initialized to
*     identity before any command line options are processed.
*
*   -XF3D XBx XBy XBz YBx YBy YBz ZBx ZBy ZBz DIx DIy DIz
*
*     Define a complete relative 3D transformation.
*
*     The incremental transform specified by this command line option is
*     post-multiplied by the 3D transform accumulated so far.  The result
*     becomes the new 3D transform.  The 3D transform is initialized to
*     identity before any command line options are processed.
*
*   -AA n
*
*     Set anti-aliasing subpixel factor.  Value of 1 disables anti-aliasing,
*     which is also the default.  WARNING: Enabling anti-aliasing can
*     seriously confuse programs not explicitly intended to handle it.
*
*   -TMAP <name>
*
*     Explicitly specify the texture map image file name.  The default is
*     "/cognivision_links/images/tmap/default".
*
*   -TMAP_EXACT
*
*     Require that the RENDlib texture mapping model be followed exactly.  By
*     default, small errors are allowed if this increases performance on the
*     current device.
*
*   -TFILT <subcommand>
*
*     Control the various texture mapping filtering switches.  The subcommands
*     are:
*
*       MAP  -  Filter between adjacent size maps.
*
*       NMAP  -  Disable filtering between maps.
*
*       PIX  -  Filter between nearest pixels within each texture map.  Bi-linear
*         interpolation is used.
*
*       NPIX  -  Disable filtering between pixels in the same map.
*
*     The default is MAP and NPIX.  Note that no interpolation may be performed, or
*     not performed as described unless -TMAP_EXACT is specified.
*
*   -MAXMAP n
*   -MINMAP n
*
*     Set the min and max filtered texture map sizes to use.  The N value
*     is the Log2 of the number of pixels in each dimension.  The default
*     is 0 to 13, meaning maps from 1x1 to 8192x8192 pixels in size.  The
*     values specified will be clipped to the available sizes is whatever
*     texture map is used.
*
*   Any unrecognized command line tokens are placed in CMLINE in the order
*   they appeared on the command line.
}
const
  default_cirres = 20;                 {number of segments for approximating circle}
  n_options = 36;                      {number of command line options}
  max_option_len = 12;                 {max command line option name length in chars}
  default_font = 'simplex.h';
  default_tmap = 'tmap/default';       {default tmap with in COGNIVIS/IMAGES dir}
  max_msg_parms = 2;                   {max parameters we can pass to a message}

  option_len_dim = max_option_len + 1; {how much to dimension each option name}
  option_chars = n_options * option_len_dim; {total chars for holding option names}
  pi = 3.141593;                       {what is sounds like, don't touch}

type
  option_t =                           {string for holding one option name}
    array[1..option_len_dim] of char;

  options_t = record                   {var string to hold command line option names}
    max: string_index_t;
    len: string_index_t;
    str: array[1..n_options] of option_t;
    end;

var
  options: options_t := [              {all the command line options}
    len := option_chars, max := option_chars, str := [
      '-DEV        ',                  {1}
      '-FACET      ',                  {2}
      '-FLAT       ',                  {3}
      '-IMG        ',                  {4}
      '-SW         ',                  {5}
      '-SIZE       ',                  {6}
      '-LIGHT_EXACT',                  {7}
      '-BIT_VIS    ',                  {8}
      '-ASPECT     ',                  {9}
      '-RAY        ',                  {10}
      '-CIRRES     ',                  {11}
      '-CIRRES1    ',                  {12}
      '-CIRRES2    ',                  {13}
      '-WIRE       ',                  {14}
      '-THICK      ',                  {15}
      '-INAME      ',                  {16}
      '-NPERSP     ',                  {17}
      '-COM        ',                  {18}
      '-SUBPIXV    ',                  {19}
      '-NSUBPIXP   ',                  {20}
      '-UPDATE     ',                  {21}
      '-XF2D       ',                  {22}
      '-EYEDIS     ',                  {23}
      '-AA         ',                  {24}
      '-TMAP_EXACT ',                  {25}
      '-MAXMAP     ',                  {26}
      '-MINMAP     ',                  {27}
      '-TMAP       ',                  {28}
      '-ROTX       ',                  {29}
      '-ROTY       ',                  {30}
      '-ROTZ       ',                  {31}
      '-OFS3D      ',                  {32}
      '-SCALE3D    ',                  {33}
      '-XF3D       ',                  {34}
      '-TFILT      ',                  {35}
      '-OLDSPHERE  ',                  {36}
      ]
    ];

procedure rend_test_cmline (           {process standard command line parms}
  in      prog: string);               {program name}
  val_param;

var
  raw_token: string_treename_t;        {raw token as read from command line}
  opt: string_treename_t;              {command line option}
  parm: string_treename_t;             {command line option parameter}
  pick: sys_int_machine_t;             {number of token picked from list}
  dx, dy: real;                        {temp for computing aspect ratio}
  xf3d: vect_mat3x4_t;                 {scratch 4x3 transform}
  r: sys_fp1_t;                        {temp fp1 variable}
  m: real;                             {scratch REAL variable}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, parm_err, parm_bad, done_opts;

begin
  opt.max := sizeof(opt.str);          {init local var strings}
  parm.max := sizeof(parm.str);
  raw_token.max := sizeof(raw_token.str);
{
*   Do REND_TEST library initialization.
}
  img_fnam.max := sizeof(img_fnam.str); {init var strings in common block}
  img_fnam.len := 0;
  prog_name.max := sizeof(prog_name.str);
  prog_name.len := 0;
  dev_name.max := sizeof(dev_name.str);
  dev_name.len := 0;
  comment_font.max := sizeof(comment_font.str);
  comment_font.len := 0;
  string_list_init (comments, util_top_mem_context);
  comments.deallocable := false;       {don't need to deallocate deleted strings}
{
*   Init defaults before processing command line options.
}
  image_width := default_image_width;  {set default image size}
  image_height := default_image_height;
  string_vstring (prog_name, prog, sizeof(prog)); {save program name}
  string_upcase (prog_name);
  string_copy (prog_name, img_fnam);   {set default image output file name}
  string_downcase (img_fnam);
  img_on := false;
  imgname_set := false;
  force_sw := false;
  lighting_accuracy := rend_laccu_dev_k;
  tmap_fnam.max := sizeof(tmap_fnam.str);
  sys_cognivis_dir ('images', tmap_fnam);
  string_append1 (tmap_fnam, '/');
  string_appendn (tmap_fnam, default_tmap, sizeof(default_tmap));
  tmap_fnam_set := false;
  tmap_accuracy := rend_tmapaccu_dev_k;
  tmap_size_max := 13;                 {init min/max allowed texture map sizes}
  tmap_size_min := 0;
  tmap_size_max_set := false;
  tmap_size_min_set := false;
  tmap_filt := [rend_tmapfilt_maps_k];
  tmap_filt_set := [];
  bits_vis := 1.0;                     {init to minimal color resolution required}
  set_bits_vis := false;               {init to BITS_VIS not explicitly set}
  size_set := false;                   {init to image size not explicitly set}
  aspect_set := false;                 {aspect ratio not explicitly set}
  string_list_init (cmline, util_top_mem_context); {init unused cmline tokens list}
  string_cmline_init;                  {init command line parsing}
  ray_on := false;                     {init to ray tracing not requested}
  cirres1 := default_cirres;
  cirres2 := default_cirres;
  cirres1_set := false;
  cirres2_set := false;
  sphere_rendprim := true;
  wire_on := false;                    {init wire frame rendering OFF}
  wire_thick_on := false;              {init to drawing regular pixel vectors}
  wire_thickness := 1.0 / 512.0;       {2 pixels wide on 1280 x 1024 image}
  wire_thick_thresh := 2.01;           {don't kick in for 1280 x 1024 screens}
  shade_mode := rend_test_shmode_linear_k; {default to linear (Gouraud) shading}
  dev_name.len := 0;                   {default RENDlib device name}
  perspective := true;                 {init perspective to ON}
  sys_cognivis_dir ('fonts', comment_font);
  string_append1 (comment_font, '/');
  string_appendn (comment_font, default_font, sizeof(default_font));
  comment_border_left := 0.10;
  comment_border_bottom := 0.10;
  comment_text_size := 0.07;
  comment_text_wide := 0.70;
  subpix_poly := true;
  subpix_vect := false;
  update_mode := rend_updmode_live_k;
  updmode_set := false;
  xform_2d.xb.x := 1.0;
  xform_2d.xb.y := 0.0;
  xform_2d.yb.x := 0.0;
  xform_2d.yb.y := 1.0;
  xform_2d.ofs.x := 0.0;
  xform_2d.ofs.y := 0.0;
  eye_dist := 3.333333;
  aa.nx := 1;
  aa.ny := 1;
  aa.pixx := 0;
  aa.pixy := 0;
  aa.subpixx := 0;
  aa.subpixy := 0;
  aa.borderx := 0;
  aa.bordery := 0;
  aa.aspect := 1.0;
  aa.scale2d := 1.0;
  aa.on := false;
  aa.uset := false;
  aa.done := false;
  xform_3d.m33.xb := vect_vector (1.0, 0.0, 0.0);
  xform_3d.m33.yb := vect_vector (0.0, 1.0, 0.0);
  xform_3d.m33.zb := vect_vector (0.0, 0.0, 1.0);
  xform_3d.ofs :=    vect_vector (0.0, 0.0, 0.0);
  xform_3d_set := false;

next_opt:                              {back here each new command line option}
  string_cmline_token (raw_token, stat); {get next command line option name}
  if string_eos(stat) then goto done_opts; {exahausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_copy (raw_token, opt);        {format assuming this is command line option}
  string_upcase (opt);
  string_tkpick (opt, options, pick);  {pick command line option name from list}
  case pick of
{
*   -DEV
}
1: begin
  string_cmline_token (dev_name, stat);
  end;
{
*   -FACET
}
2: begin
  shade_mode := rend_test_shmode_facet_k;
  end;
{
*   -FLAT
}
3: begin
  shade_mode := rend_test_shmode_flat_k;
  end;
{
*   -IMG
}
4: begin
  img_on := true;
  end;
{
*   -SW
}
5: begin
  force_sw := true;
  end;
{
*   -SIZE ix iy
}
6: begin
  string_cmline_token_int (image_width, stat);
  string_cmline_parm_check (stat, opt);
  string_cmline_token_int (image_height, stat);
  size_set := true;
  end;
{
*   -LIGHT_EXACT
}
7: begin
  lighting_accuracy := rend_laccu_exact_k;
  end;
{
*   -BITS_VIS n
}
8: begin
  string_cmline_token_fp1 (r, stat);
  bits_vis := r;
  set_bits_vis := true;
  end;
{
*   -ASPECT width height
}
9: begin
  string_cmline_token_fp1 (r, stat);
  dx := r;
  string_cmline_parm_check (stat, opt);
  string_cmline_token_fp1 (r, stat);
  dy := r;
  aspect := dx / dy;
  aspect_set := true;
  end;
{
*   -RAY
}
10: begin
  ray_on := true;
  end;
{
*   -CIRRES n
}
11: begin
  string_cmline_token_int (cirres1, stat);
  cirres2 := cirres1;
  cirres1_set := true;
  cirres2_set := true;
  end;
{
*   -CIRRES1 n
}
12: begin
  string_cmline_token_int (cirres1, stat);
  cirres1_set := true;
  end;
{
*   -CIRRES2 n
}
13: begin
  string_cmline_token_int (cirres2, stat);
  cirres2_set := true;
  end;
{
*   -WIRE
}
14: begin
  wire_on := true;
  end;
{
*   -THICK
}
15: begin
  string_cmline_token_fp1 (r, stat);
  wire_thickness := r / 512.0;
  end;
{
*   -INAME <image file name>
}
16: begin
  img_on := true;
  string_cmline_token (img_fnam, stat);
  imgname_set := true;
  end;
{
*   -NPERSP
}
17: begin
  perspective := false;
  end;
{
*   -COM <comment string>
}
18: begin
  string_cmline_token (parm, stat);
  if sys_error(stat) then goto parm_err;
  string_list_pos_last (comments);
  comments.size := parm.len;
  string_list_line_add (comments);
  string_copy (parm, comments.str_p^);
  end;
{
*   -SUBPIXV
}
19: begin
  subpix_vect := true;
  end;
{
*   -NSUBPIXP
}
20: begin
  subpix_poly := false;
  end;
{
*   -UPDATE
*     LIVE
*     BUFFALL
}
21: begin
  string_cmline_token (parm, stat);
  string_cmline_parm_check (stat, opt);
  string_upcase (parm);
  string_tkpick80 (parm, 'LIVE BUFFALL', pick);
  case pick of
1:  begin
      update_mode := rend_updmode_live_k;
      end;
2:  begin
      update_mode := rend_updmode_buffall_k;
      end;
otherwise
    sys_msg_parm_vstr (msg_parm[1], parm);
    sys_msg_parm_vstr (msg_parm[2], opt);
    sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);
    end;
  updmode_set := true;
  end;
{
*   -XF2D  xbx xby  ybx yby  ofsx ofsy
}
22: begin
  string_cmline_token_fpm (xform_2d.xb.x, stat);
  string_cmline_parm_check (stat, opt);
  string_cmline_token_fpm (xform_2d.xb.y, stat);
  string_cmline_parm_check (stat, opt);
  string_cmline_token_fpm (xform_2d.yb.x, stat);
  string_cmline_parm_check (stat, opt);
  string_cmline_token_fpm (xform_2d.yb.y, stat);
  string_cmline_parm_check (stat, opt);
  string_cmline_token_fpm (xform_2d.ofs.x, stat);
  string_cmline_parm_check (stat, opt);
  string_cmline_token_fpm (xform_2d.ofs.y, stat);
  end;
{
*   -EYEDIS e
}
23: begin
  string_cmline_token_fpm (eye_dist, stat);
  end;
{
*   -AA n
}
24: begin
  string_cmline_token_int (aa.nx, stat);
  if sys_error(stat) then goto parm_err;
  aa.nx := max(1, aa.nx);              {don't allow less than 1 (off)}
  aa.ny := aa.nx;
  aa.uset := true;
  end;
{
*   -TMAP_EXACT
}
25: begin
  tmap_accuracy := rend_tmapaccu_exact_k;
  end;
{
*   -MAXMAP n
}
26: begin
  string_cmline_token_int (tmap_size_max, stat);
  tmap_size_max_set := true;
  end;
{
*   -MINMAP n
}
27: begin
  string_cmline_token_int (tmap_size_min, stat);
  tmap_size_min_set := true;
  end;
{
*   -TMAP filename
}
28: begin
  string_cmline_token (tmap_fnam, stat);
  tmap_fnam_set := true;
  end;
{
*   -ROTX a
}
29: begin
  string_cmline_token_fpm (m, stat);
  xform_3d := vect_m3x4_mult (
    xform_3d,
    vect_m3x4_rotate_x(m * pi));
  xform_3d_set := true;
  end;
{
*   -ROTY a
}
30: begin
  string_cmline_token_fpm (m, stat);
  xform_3d := vect_m3x4_mult (
    xform_3d,
    vect_m3x4_rotate_y(m * pi));
  xform_3d_set := true;
  end;
{
*   -ROTZ a
}
31: begin
  string_cmline_token_fpm (m, stat);
  xform_3d := vect_m3x4_mult (
    xform_3d,
    vect_m3x4_rotate_z(m * pi));
  xform_3d_set := true;
  end;
{
*   -OFS3D x y z
}
32: begin
  xf3d.m33.xb := vect_vector (1.0, 0.0, 0.0);
  xf3d.m33.yb := vect_vector (0.0, 1.0, 0.0);
  xf3d.m33.zb := vect_vector (0.0, 0.0, 1.0);
  string_cmline_token_fpm (xf3d.ofs.x, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.ofs.y, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xform_3d.ofs.z, stat);

  xform_3d := vect_m3x4_mult (xform_3d, xf3d);
  xform_3d_set := true;
  end;
{
*   -SCALE3D m
}
33: begin
  string_cmline_token_fpm (m, stat);
  xf3d.m33.xb := vect_vector (  m, 0.0, 0.0);
  xf3d.m33.yb := vect_vector (0.0,   m, 0.0);
  xf3d.m33.zb := vect_vector (0.0, 0.0,   m);
  xf3d.ofs    := vect_vector (0.0, 0.0, 0.0);

  xform_3d := vect_m3x4_mult (xform_3d, xf3d);
  xform_3d_set := true;
  end;
{
*   -XF3D <full 3x4 transform>
}
34: begin
  string_cmline_token_fpm (xf3d.m33.xb.x, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.m33.xb.y, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.m33.xb.z, stat);
  if sys_error(stat) then goto parm_err;

  string_cmline_token_fpm (xf3d.m33.yb.x, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.m33.yb.y, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.m33.yb.z, stat);
  if sys_error(stat) then goto parm_err;

  string_cmline_token_fpm (xf3d.m33.zb.x, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.m33.zb.y, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.m33.zb.z, stat);
  if sys_error(stat) then goto parm_err;

  string_cmline_token_fpm (xf3d.ofs.x, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.ofs.y, stat);
  if sys_error(stat) then goto parm_err;
  string_cmline_token_fpm (xf3d.ofs.z, stat);

  xform_3d := vect_m3x4_mult (xform_3d, xf3d);
  xform_3d_set := true;
  end;
{
*   -TFILT   MAP, NMAP, PIX, or NPIX
}
35: begin
  string_cmline_token (parm, stat);    {get subcommand name}
  if sys_error(stat) then goto parm_err;
  string_upcase (parm);                {make upper case for keyword matching}
  string_tkpick80 (parm,               {pick subcommand from list}
    'MAP NMAP PIX NPIX',
    pick);                             {number of keyword picked from list}
  case pick of
1:  begin                              {-TFILT MAP}
      tmap_filt := tmap_filt + [rend_tmapfilt_maps_k];
      tmap_filt_set := tmap_filt_set + [rend_tmapfilt_maps_k];
      end;
2:  begin                              {-TFILT NMAP}
      tmap_filt := tmap_filt - [rend_tmapfilt_maps_k];
      tmap_filt_set := tmap_filt_set + [rend_tmapfilt_maps_k];
      end;
3:  begin                              {-TFILT PIX}
      tmap_filt := tmap_filt + [rend_tmapfilt_pix_k];
      tmap_filt_set := tmap_filt_set + [rend_tmapfilt_pix_k];
      end;
4:  begin                              {-TFILT NPIX}
      tmap_filt := tmap_filt - [rend_tmapfilt_pix_k];
      tmap_filt_set := tmap_filt_set + [rend_tmapfilt_pix_k];
      end;
otherwise
    goto parm_bad;
    end;
  end;
{
*   -OLDSPHERE
}
36: begin
  sphere_rendprim := false;
  end;
{
*   Unrecognized command line option.  Add it to the list of unprocessed options
*   in CMLINE.
}
otherwise
    string_list_line_add (cmline);     {create new string for this option}
    string_copy (raw_token, cmline.str_p^); {save unrecognized token in list}
    end;                               {end of command line option cases}
{
*   Done processing current command line option.  A bad status here indicates
*   an error with a parameter to the command line option.
}
parm_err:                              {jump here with bad STAT from parm error}
  string_cmline_parm_check (stat, opt); {bomb on bad parameter to current option}
  goto next_opt;                       {back for next command line option}

parm_bad:                              {jump here on illegal parameter}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);

done_opts:                             {all done reading command line}
  string_list_pos_start (cmline);      {position to before first unused token}
  comments.size := 80;                 {set default length for new comment lines}
  end;
{
****************************************************************
*
*   Subroutine REND_TEST_CMLINE_TOKEN (TOKEN, STAT)
*
*   Return the next command line token that has not already been interpreted.
}
procedure rend_test_cmline_token (     {return next unused token from command line}
  in out  token: univ string_var_arg_t; {returned token}
  out     stat: sys_err_t);            {completion status code}
  val_param;

begin
  sys_error_none (stat);
  if cmline.curr >= cmline.n then begin {got to end of strings list ?}
    sys_stat_set (string_subsys_k, string_stat_eos_k, stat);
    token.len := 0;
    return;                            {return with END OF STRING status}
    end;
  string_list_pos_rel (cmline, 1);     {advance to new token in strings list}
  string_copy (cmline.str_p^, token);  {return token string}
  end;
{
****************************************************************
*
*   Function REND_TEST_CMLINE_FP (STAT)
*
*   Read the next unprocessed command line token as a floating point number
*   and return its value.
}
function rend_test_cmline_fp (         {get FP value of enxt unused cmd line token}
  out     stat: sys_err_t)             {completion status code}
  :sys_fp_max_t;                       {returned floating point value}
  val_param;

var
  token: string_var32_t;
  fp: sys_fp_max_t;

begin
  token.max := sizeof(token.str);      {init local var string}
  rend_test_cmline_fp := 0.0;          {prevent uninitialized var compiler warning}

  rend_test_cmline_token (token, stat); {get next command line token}
  if sys_error(stat) then return;
  string_t_fpmax (                     {convert token to FP number}
    token,                             {input string}
    fp,                                {output value}
    [],                                {optional flags}
    stat);
  rend_test_cmline_fp := fp;           {pass back floating point value}
  end;
{
****************************************************************
*
*   Function REND_TEST_CMLINE_INT (STAT)
*
*   Read the next unprocessed command line token as an integer
*   and return its value.
}
function rend_test_cmline_int (        {get integer value of next unused token}
  out     stat: sys_err_t)             {completion status code}
  :sys_int_max_t;                      {returned integer value}
  val_param;

var
  token: string_var32_t;
  i: sys_int_max_t;

begin
  token.max := sizeof(token.str);      {init local var string}
  rend_test_cmline_int := 0;           {prevent uninitialized var compiler warning}

  rend_test_cmline_token (token, stat); {get next command line token}
  if sys_error(stat) then return;
  string_t_int_max (token, i, stat);   {convert token to integer value}
  rend_test_cmline_int := i;
  end;
