{   Public include file for REND_TEST library.
*
*   The include file REND_TEST_ALL.INS.PAS is provided for convenience to simple
*   programs.  It references all the include files required by
*   REND_TEST.INS.PAS.
*
*   This library is intended to make it easy to create RENDlib functional tests
*   and quick one-off programs.  It makes RENDlib easier to use by having some
*   choices and common facilities built in.  This simplicity comes at the price
*   of less flexibility and some restrictions.  Full-blow applications should
*   use RENDlib directly.
}
const
  default_image_width = 512;
  default_image_height = 410;

type
  rend_test_comp_k_t = (               {all the pixel components}
    rend_test_comp_red_k,              {red}
    rend_test_comp_grn_k,              {green}
    rend_test_comp_blu_k,              {blue}
    rend_test_comp_z_k,                {Z}
    rend_test_comp_alpha_k);           {alpha}

  rend_test_comp_t =                   {set of flags for each pixel component}
    set of rend_test_comp_k_t;

  rend_test_shade_mode_k_t = (         {the different supported shading modes}
    rend_test_shmode_flat_k,           {whole polygon is same color}
    rend_test_shmode_facet_k,          {use geometric normal as shading normals}
    rend_test_shmode_linear_k);        {standard linear (Gouraud) shading}

  rend_test_axis_k_t = (               {mnemonics for the major axies}
    rend_test_axis_x_k,
    rend_test_axis_y_k,
    rend_test_axis_z_k);

  rend_test_vert3d_t = record          {common 3D vertex format used by TEST library}
    coor_p: vect_3d_fp1_p_t;           {pointer to XYZ coordinate}
    norm_p: vect_3d_fp1_p_t;           {pointer to shading normal vector}
    vcache_p: rend_vcache_p_t;         {pointer to RENDlib vertex cache}
    coor: vect_3d_fp1_t;               {XYZ coordinate}
    norm: vect_3d_fp1_t;               {shading normal vector}
    vcache: rend_vcache_t;             {cache for this vertex}
    end;

  rend_test_vert3d_p_t =               {pointer to a REND_TEST library 3D vertex}
    ^rend_test_vert3d_t;

  rend_test_cap_k_t = (                {all the different 3D end cap types}
    rend_test_cap_none_k,              {no cap, leave open}
    rend_test_cap_flat_k,              {flat cut off}
    rend_test_cap_sph_k);              {hemispherical end cap}

  rend_test_func2d_t = ^function (     {scalar function of 2 variables}
    in    t1, t2: real)                {input independent variables}
    :vect_3d_fp1_t;                    {function value at T1 and T2}
    val_param;

  rend_test_clip_t = record            {data for a clip rectangle}
    x1, y1: real;                      {coordinate of top left corner}
    x2, y2: real;                      {coordinate of bottom right corner}
    end;

  rend_test_xform_2d_t = record
    xb: vect_2d_t;
    yb: vect_2d_t;
    ofs: vect_2d_t;
    end;

  rend_test_aa_t = record              {all the info to deal with anti-aliasing}
    nx, ny: sys_int_machine_t;         {subpixel level for each dimension}
    pixx, pixy: sys_int_machine_t;     {pixels in final filtered image}
    subpixx, subpixy: sys_int_machine_t; {subpixels without the extra border}
    borderx, bordery: sys_int_machine_t; {extra border width in subpixels}
    aspect: real;                      {aspect ratio of final filtered image}
    scale2d: real;                     {2D xform shrink to account for border}
    ofs2d: vect_2d_t;                  {2D xform offset to account for border}
    on: boolean;                       {TRUE if any anti-aliasing is enabled}
    uset: boolean;                     {TRUE if user explicitly set AA}
    done: boolean;                     {TRUE after filtering performed}
    end;
{
*   Public common block.
}
var (rend_test)
  image_width: sys_int_machine_t;      {width of raw bitmap in pixels}
  image_height: sys_int_machine_t;     {height of raw bitmap in pixels}
  aspect: real;                        {aspect ratio of raw bitmap}
  width_2d, height_2d: real;           {2D space radii of logical image}
  xform_2d: rend_test_xform_2d_t;      {2D transform, used in GRAPHICS_INIT}
  xform_3d: vect_mat3x4_t;             {3D transform resulting from command line}
  img_fnam: string_treename_t;         {output image file name, if used}
  lighting_accuracy: rend_laccu_k_t;   {light model accuracy requirement}
  tmap_accuracy: rend_tmapaccu_k_t;    {texture mapping accuracy requirement}
  bits_vis: real;                      {requested effective bits/pixel}
  eye_dist: real;                      {eye distance perspective factor}
  aa: rend_test_aa_t;                  {anti-aliasing info}
  tmap_fnam: string_treename_t;        {texture map file name}
  tmap_size_max, tmap_size_min:        {min/max allowable texture map sizes}
    sys_int_machine_t;
  tmap_filt: rend_tmapfilt_t;          {texture mapping filtering flags}
  tmap_filt_set: rend_tmapfilt_t;      {flags explicitly set in TMAP_FILT}
  tmap_fnam_set: boolean;              {TRUE if TMAP_FNAM explicitly set}
  tmap_size_max_set, tmap_size_min_set: {TRUE if associated value explicitly set}
    boolean;
  set_bits_vis: boolean;               {TRUE on -BITS_VIS command line option}
  user_wait: boolean;                  {TRUE causes wait for user exit}
  img_on: boolean;                     {TRUE if write final image to image file}
  imgname_set: boolean;                {TRUE if image file name explicitly set}
  force_sw: boolean;                   {TRUE if must force SW updates always}
  size_set: boolean;                   {TRUE if image pixel size explicitly set}
  aspect_set: boolean;                 {TRUE if aspect ratio explicitly set}
  ray_on: boolean;                     {TRUE if ray tracing requested}
  perspective: boolean;                {TRUE if perspective ON}
  updmode_set: boolean;                {TRUE if -UPDATE command line option given}
  xform_3d_set: boolean;               {TRUE if XFORM_3D altered from command line}
  cirres1_set, cirres2_set: boolean;   {TRUE if corresponding -CIRRES cupplied}
  sphere_rendprim: boolean;            {use RENDlib sphere primtive}
  wire_on: boolean;                    {TRUE on -WIRE command line option}
  wire_thick_on: boolean;              {TRUE if drawing vectors as polygons}
  wire_thickness: real;                {fraction of minimum image dimension}
  wire_thick_thresh: real;             {min vector thickness to enable thickening}
  shade_mode: rend_test_shade_mode_k_t; {what type of shading we are supposed to do}
  rend_dev_id: rend_dev_id_t;          {ID for RENDlib device actually used}
  comp_bitmaps: rend_test_comp_t;      {set of all the components hooked to bitmaps}
  bitmap_rgb: rend_bitmap_handle_t;    {bitmap handle for RGB pixel data}
  bitmap_z: rend_bitmap_handle_t;      {bitmap handle for Z pixel data, if used}
  bitmap_alpha: rend_bitmap_handle_t;  {bitmap handle for alpha pixel data, if used}
  cmline: string_list_t;               {command line tokens read but not understood}
  rend_test_clip_handle: rend_clip_2dim_handle_t; {handle to RENDlib clip rectangle}
  clip_master: rend_test_clip_t;       {master clip rectangle, used for refresh}
  prog_name: string_var80_t;           {program name in upper case}
  dev_name: string_var8192_t;          {device name string to pass to REND_OPEN}
  comments: string_list_t;             {displayed comment lines}
  comment_font: string_treename_t;     {name of font to use for comment string}
  comment_border_left: real;           {comment offset from left edge}
  comment_border_bottom: real;         {comment offset from bottom edge}
  comment_text_size: real;             {text size to use for comment string}
  comment_text_wide: real;             {char cell width to use for comment string}
  comm_p: string_list_p_t;             {points to image file comments list}
  cirres1, cirres2: sys_int_machine_t; {major and minor circle resolutions}
  update_mode: rend_updmode_k_t;       {requested display update mode}
  subpix_poly: boolean;                {TRUE if user wants subpixel polygons}
  subpix_vect: boolean;                {TRUE if user wants subpixel vectors}
  version_vcache: sys_int_machine_t;   {current VCACHE version number}
{
*   Routine entry points.
}
procedure rend_test_arrow (            {draw an arrow with conical head}
  in      dx, dy, dz: real;            {arrow displacement, starts at current point}
  in      rad_shaft: real;             {arrow shaft radius}
  in      rad_head: real;              {max radius of arrow head}
  in      len_head: real;              {length of arrow head}
  in      cap_start: rend_test_cap_k_t); {what kind of cap to put at arrow start}
  val_param; extern;

procedure rend_test_bitmaps (          {alloc bitmaps and connect to interpolants}
  in      comp: rend_test_comp_t);     {set of components to allocate pixels for}
  val_param; extern;

procedure rend_test_box (              {draw paralellpiped}
  in      v1, v2, v3: vect_3d_t);      {vectors along each edge from current point}
  val_param; extern;

procedure rend_test_cap (              {draw an end cap}
  in      cap_type: rend_test_cap_k_t; {what kind of end cap to draw}
  in      vx, vy: vect_3d_t;           {vectors in plane of cap}
  in      vz: vect_3d_t);              {vector to tip of cap from capped end center}
  val_param; extern;

procedure rend_test_cap_rad (          {draw circular end cap}
  in      cap_type: rend_test_cap_k_t; {what kind of end cap to draw}
  in      vperp: vect_3d_t;            {vector along object to be capped, any magn}
  in      radius: real);               {cap radius, plane perpendicular to VPERP}
  val_param; extern;

procedure rend_test_clip (             {set current clip rect, merged with master}
  in      x, y: real;                  {top left corner of 2DIM clip rectangle}
  in      dx, dy: real);               {size of clip rectangle}
  val_param; extern;

procedure rend_test_clip_all (         {set master clip rectangle and enable}
  in      x, y: real;                  {top left corner of 2DIM clip rectangle}
  in      dx, dy: real);               {size of clip rectangle}
  val_param; extern;

procedure rend_test_clip_all_off;      {disable master clip rectangle}
  val_param; extern;

procedure rend_test_cmline (           {process standard command line parms}
  in      prog: string);               {program name}
  val_param; extern;

procedure rend_test_cmline_done;       {abort if unused command line tokens exist}
  extern;

function rend_test_cmline_fp (         {get FP value of next unused cmd line token}
  out     stat: sys_err_t)             {completion status code}
  :sys_fp_max_t;                       {returned floating point value}
  val_param; extern;

function rend_test_cmline_int (        {get integer value of next unused token}
  out     stat: sys_err_t)             {completion status code}
  :sys_int_max_t;                      {returned integer value}
  val_param; extern;

procedure rend_test_cmline_token (     {return next unused token from command line}
  in out  token: univ string_var_arg_t; {returned token}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure rend_test_colors_wire;       {set RGB from diffuse color for wire frame}
  extern;

procedure rend_test_comment_draw;      {draw comment string, if exists}
  extern;

procedure rend_test_cone (             {draw a cone}
  in      dx, dy, dz: real;            {displacement from circle center to tip}
  in      radius: real);               {circle radius}
  val_param; extern;

procedure rend_test_cyl (              {draw a cylender}
  in      dx, dy, dz: real;            {displacement to other end of cylender}
  in      radius: real;                {cylender radius}
  in      cap_start: rend_test_cap_k_t; {what kind of cap to put at start}
  in      cap_end: rend_test_cap_k_t); {what kind of cap to put at end}
  val_param; extern;

procedure rend_test_draw_2d (          {draw some stuff using 2D primitives}
  in      m: real);                    {mult factor on intensity levels}
  val_param; extern;

procedure rend_test_end;               {all done drawing, exit in standard way}
  extern;

procedure rend_test_func2d_vert (      {fill in vertex at arbitrary function point}
  in      t1, t2: real;                {independent variables at this point}
  in      dt1, dt2: real;              {size of T1 and T2 deltas for surface vectors}
  in      func: rend_test_func2d_t;    {function to return surface coor at T1,T2}
  out     vert: rend_test_vert3d_t);   {3D vertex descriptor to fill in}
  val_param; extern;

procedure rend_test_graphics_init;     {init RENDlib, enter graphics mode}
  extern;

procedure rend_test_image_write (      {write IMG_FNAM image file, AA if needed}
  out     stat: sys_err_t);            {completion status code}
  extern;

procedure rend_test_perp_left (        {make perpendicular vectors, left handed}
  in      vperp: vect_3d_t;            {vector to make perpendicular vectors to}
  in      mag: real;                   {magnitude of perpendicular vectors}
  out     v1, v2: vect_3d_t);          {perpendicular to VPERP and each other}
  val_param; extern;

procedure rend_test_perp_right (       {make perpendicular vectors, right handed}
  in      vperp: vect_3d_t;            {vector to make perpendicular vectors to}
  in      mag: real;                   {magnitude of perpendicular vectors}
  out     v1, v2: vect_3d_t);          {perpendicular to VPERP and each other}
  val_param; extern;

procedure rend_test_recompute_aa;      {set AA state from shrink and image size}
  extern;

function rend_test_refresh             {wait on events, TRUE if refresh needed}
  :boolean;                            {TRUE for refresh, FALSE on RENDlib closed}
  extern;

procedure rend_test_resize;            {update bitmaps, etc. to new draw area size}
  val_param; extern;

procedure rend_test_sphere (           {draw sphere centered at current point}
  in      radius: real);               {sphere radius}
  val_param; extern;

procedure rend_test_surf (             {draw surface that is function of 2 variables}
  in      t1_min, t1_max: real;        {range of first independent variable}
  in      t1_seg: sys_int_machine_t;   {number of segments to break T1 into}
  in      t2_min, t2_max: real;        {range of second independent variable}
  in      t2_seg: sys_int_machine_t;   {number of segments to break T2 into}
  in      func: rend_test_func2d_t);   {function to return surface coor at T1,T2}
  val_param; extern;

procedure rend_test_tmap_read (        {read texture map image, setup tmap state}
  in out  img: img_conn_t;             {handle to texture map image file connection}
  out     bitmap: rend_bitmap_handle_t); {handle to new bitmap holding texture map}
  val_param; extern;

procedure rend_test_tri (              {draw triangle with current render mode}
  in      v1, v2, v3: rend_test_vert3d_t; {data for each triangle vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param; extern;

function rend_test_tri_reading_sw      {TRUE if REND_TEST_TRI will read SW bitmap}
  :boolean;
  val_param; extern;

procedure rend_test_vert3d_init (      {initialize one of our 3D vertex descriptors}
  out     vert: rend_test_vert3d_t);   {vertex, will set pointers and version}
  extern;

procedure rend_test_view_set (         {set model transform from view geometry}
  in      eye: vect_3d_t;              {eye point}
  in      lookat: vect_3d_t;           {point to appear at image center}
  in      up: vect_3d_t;               {in direction of image up}
  in      rad: real);                  {image plane "radius" at LOOKAT point}
  val_param; extern;

procedure rend_test_xf3d_premult (     {premultiply to RENDlib 3D transform}
  in      xb, yb, zb: vect_3d_t);      {the relative X, Y, and Z basis vectors}
  val_param; extern;

procedure rend_test_xf3d_rotate (      {rotate the current RENDlib 3D transform}
  in      axis: rend_test_axis_k_t;    {rotation axis select}
  in      a: real);                    {rotation angle in radians}
  val_param; extern;

procedure rend_test_xf3d_scale (       {scale RENDlib 3D transform}
  in      x, y, z: real);              {scale factors for each axis}
  val_param; extern;

procedure rend_test_xf3d_xlate (       {move RENDlib 3D space to new origin}
  in      x, y, z: real);              {coordinates of new origin in old space}
  val_param; extern;

procedure rend_test_xform2d (          {set 2D transform, take AA into account}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}
  val_param; extern;
