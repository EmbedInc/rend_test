{   Subroutine REND_TEST_TMAP_READ (IMG, BITMAP)
*
*   Read a texture map image file and setup the texture mapping state
*   accordingly.  IMG is the handle to the previously open image file
*   connection.  BITMAP is the returned handle to the newly created RENDlib
*   bitmap holding the texture map from the input image.
*
*   Any interpolants that have corresponding values in the image will
*   be set up for texture mapping from the newly created bitmap.
*   The global texture mapping state that can be determined from the
*   image file information will be set up.  This includes TMAP_DIMENSION,
*   TMAP_FLIMS, and TMAP_METHOD.  TMAP_CHANGED will also be called.
*
*   Texture map image files always contain a set of separate texture maps.
*   The size of each individual map is always a power of two pixels
*   in each dimension.  There must be one individual map for each power of
*   two up to the largest map in the image.
*
*   The individual maps must be stored at specific locations within the
*   image file.  The top left pixel of the largest map is always at 0,0.
*   If the largest map is N pixels in each dimension, then the next largest
*   is stored at (meaning the upper left pixel is at) 0,N.  Additional
*   maps are stored adjacent to the right, in order of decending size.
*   Therefore, the next map is at N/2,N, then 3N/4,N, 7N/8,N, etc.
*
*   For example, the largest map is 1024x1024 pixels in size.  Its upper
*   left pixel is at 0,0 within the image file.  The upper left pixel
*   of the 512x512 map is at 0,1024 within the image file.  The 256x256
*   map is at 512x1024, the 128x128 map at 768x1024, etc.  See example
*   texture map image files in /cognivision_links/images/tmap.
*
*   A texture map image file must always be a power of two pixels wide,
*   and at least 1 1/2 times that tall.  This will contain some unused
*   space in the lower right corner.  The size of the new bitmap will
*   also always be this 2**N x 1.5(2**N) value.
}
module rend_test_tmap_read;
define rend_test_tmap_read;
%include 'rend_test2.ins.pas';

procedure rend_test_tmap_read (        {read texture map image, setup tmap state}
  in out  img: img_conn_t;             {handle to texture map image file connection}
  out     bitmap: rend_bitmap_handle_t); {handle to new bitmap holding texture map}
  val_param;

const
  max_msg_parms = 2;                   {max parameters we can pass messages}

var
  i: sys_int_machine_t;                {scratch integer}
  maxmap: sys_int_machine_t;           {Log2 of max texture map size}
  nlines: sys_int_machine_t;           {number of lines in new bitmap}
  tdev: rend_dev_id_t;                 {ID of temp RENDlib device for TMAP}
  dev_old: rend_dev_id_t;              {ID of existing RENDlib device}
  elev_old: sys_int_machine_t;         {ENTER LEVEL of old RENDlib device}
  tmap_x, tmap_y: sys_int_machine_t;   {current texture map coordinates}
  lev: sys_int_machine_t;              {current texture map 0-N level}
  size: sys_int_machine_t;             {current texture map size (2**LEV)}
  msg_parm:                            {parameter reference for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;

begin
{
*   Check to make sure the image file is exactly a power of two pixels
*   wide, and at least 1 1/2 times that tall.
}
  i := 1;                              {init minimum require image file width}
  maxmap := 0;                         {init Log2 of max texture map size}
  while i < img.x_size do begin        {find first power of 2 large enough}
    i := i * 2;
    maxmap := maxmap + 1;
    end;
  if img.x_size <> i then begin        {image file not power of 2 wide ?}
    sys_msg_parm_int (msg_parm[1], img.x_size);
    sys_msg_parm_int (msg_parm[2], img.y_size);
    rend_message_bomb ('rend_test', 'tmap_imfile_npower2', msg_parm, 2);
    end;
  nlines := img.x_size + (img.x_size div 2); {number of lines needed in image file}
  if img.y_size < nlines then begin    {image file not tall enough ?}
    sys_msg_parm_int (msg_parm[1], img.x_size);
    sys_msg_parm_int (msg_parm[2], img.y_size);
    rend_message_bomb ('rend_test', 'tmap_imfile_ntall', msg_parm, 2);
    end;
{
*   Image file dimensions are OK.  MAXMAP is Log2 of the largest map size
*   in the image file.  NLINES are the number of lines we have to read from
*   the image file.
}
  rend_get.enter_level^ (elev_old);    {save ENTER LEVEL of existing RENDlib device}
  rend_get.dev_id^ (dev_old);          {get ID of existing RENDlib device}

  rend_open (string_v('*SW*'), tdev, stat); {make device for tmap}
  rend_error_abort (stat, 'rend', 'rend_open_sw', nil, 0);

  rend_set.enter_rend^;                {enter graphics mode}
  rend_set.image_size^ (               {set size to texture map size}
    img.x_size, nlines,
    img.x_size / nlines);

  if img.bits_alpha > 0
    then begin                         {texture map image contains alpha}
      i := 4;                          {set number of components in image}
      end
    else begin                         {texture map image is just RGB}
      i := 3;
      end
    ;
  rend_set.alloc_bitmap_handle^ (      {create handle to texture map bitmap}
    rend_scope_rend_k,                 {bitmap belongs to all RENDlib}
    bitmap);                           {returned bitmap handle}
  rend_set.alloc_bitmap^ (             {allocate the pixels for texture map}
    bitmap,                            {handle to this bitmap}
    img.x_size, nlines,                {size of texture map in pixels}
    i,                                 {number of bytes to allocate for each pixel}
    rend_scope_rend_k);                {bitmap is tied to RENDlib}
{
*   Set up interpolants and read the image file into bitmap BITMAP.
}
  rend_set.iterp_on^ (rend_iterp_red_k, true); {enable RED interpolant}
  rend_set.iterp_bitmap^ (             {connect interpolant to texture map}
    rend_iterp_red_k,
    bitmap,
    0);

  rend_set.iterp_on^ (rend_iterp_grn_k, true); {enable GREEN interpolant}
  rend_set.iterp_bitmap^ (             {connect interpolant to texture map}
    rend_iterp_grn_k,
    bitmap,
    1);

  rend_set.iterp_on^ (rend_iterp_blu_k, true); {enable BLUE interpolant}
  rend_set.iterp_bitmap^ (             {connect interpolant to texture map}
    rend_iterp_blu_k,
    bitmap,
    2);

  if img.bits_alpha > 0 then begin     {texture image contains alpha data ?}
    rend_set.iterp_on^ (rend_iterp_alpha_k, true); {enable ALPHA interpolant}
    rend_set.iterp_bitmap^ (           {connect interpolant to texture map}
      rend_iterp_alpha_k,
      bitmap,
      3);
    end;

  rend_prim.image_2dimcl^ (            {read texture map into tmap bitmap}
    img,                               {image file connection handle}
    0, 0,                              {bitmap anchor coordinates}
    rend_torg_ul_k,                    {anchor is upper left of bitmap}
    stat);
  sys_error_abort (stat, 'rend', 'rend_read_image', nil, 0);
  rend_set.close^;                     {texture map all set, done with device}

  rend_dev_set (dev_old);              {return to caller's RENDlib device}
  rend_set.enter_level^ (elev_old);    {restore caller's ENTER LEVEL}
  rend_set.enter_rend^;                {make sure we are in graphics mode}
{
*   The texture map is sitting in bitmap BITMAP.  Our temporary RENDlib
*   device has been closed, and the current device restored to that found
*   on entry.
*
*   Set up global texture mapping state.
}
  rend_set.tmap_dimension^ (rend_tmapd_uv_k); {use 2D texture mapping, UV indicies}
  rend_set.tmap_method^ (rend_tmapm_mip_k); {use mip-map filtering method}
  rend_set.tmap_flims^ (               {set min/max allowable map sizes}
    2 ** max(tmap_size_min, 0),        {dimensions of smallest allowable tmap}
    2 ** min(tmap_size_max, maxmap));  {dimensions of largest allowable tmap}
{
*   Loop thru all the individual texture maps from the largest to the smallest,
*   and set up the per-interpolant state.
}
  size := 2 ** (maxmap + 1);           {init size to that of "previous" map}
  for lev := maxmap downto 0 do begin  {once for each individual texture map}

    if lev = maxmap
      then begin                       {doing the largest map}
        tmap_x := 0;                   {largest map is always on top}
        tmap_y := 0;
        end
      else begin                       {not doing the largest map}
        if lev = (maxmap - 1)
          then begin                   {doing the next to largest map}
            tmap_y := size;            {always immediately below top map}
            end
          else begin                   {not first or second largest map}
            tmap_x := tmap_x + size;   {immediately to right of previous map}
            end
          ;
        end
      ;                                {TMAP_X, TMAP_Y all set}
    size := size div 2;                {make pixel dimension of this map}

    rend_set.tmap_src^ (               {set RED texture map source info}
      rend_iterp_red_k,                {interpolant ID}
      bitmap,                          {handle to bitmap containing texture map}
      0,                               {pixel byte offset for this interpolant}
      size, size,                      {dimensions of texture map}
      tmap_x,                          {X coor of top left corner}
      tmap_y);                         {Y coor of top left corner}
    rend_set.tmap_src^ (               {set GREEN texture map source info}
      rend_iterp_grn_k,                {interpolant ID}
      bitmap,                          {handle to bitmap containing texture map}
      1,                               {pixel byte offset for this interpolant}
      size, size,                      {dimensions of texture map}
      tmap_x,                          {X coor of top left corner}
      tmap_y);                         {Y coor of top left corner}
    rend_set.tmap_src^ (               {set BLU texture map source info}
      rend_iterp_blu_k,                {interpolant ID}
      bitmap,                          {handle to bitmap containing texture map}
      2,                               {pixel byte offset for this interpolant}
      size, size,                      {dimensions of texture map}
      tmap_x,                          {X coor of top left corner}
      tmap_y);                         {Y coor of top left corner}

    if img.bits_alpha > 0 then begin   {texture image contains alpha data ?}
      rend_set.tmap_src^ (             {set ALPHA texture map source info}
        rend_iterp_alpha_k,            {interpolant ID}
        bitmap,                        {handle to bitmap containing texture map}
        3,                             {pixel byte offset for this interpolant}
        size, size,                    {dimensions of texture map}
        tmap_x,                        {X coor of top left corner}
        tmap_y);                       {Y coor of top left corner}
      end;
    end;                               {back and do next smaller map}
{
*   Init some global texture mapping state to the way it will most likely
*   need to be.
}
  rend_set.tmap_on^ (true);            {turn on texture mapping}
  rend_set.tmap_changed^;              {indicate texture map pixels were altered}

  rend_set.iterp_on^ (rend_iterp_u_k, true); {turn on texture index interpolants}
  rend_set.iterp_on^ (rend_iterp_v_k, true);
  rend_set.iterp_iclamp^ (rend_iterp_u_k, false); {allow texture to wrap}
  rend_set.iterp_iclamp^ (rend_iterp_v_k, false);
  rend_set.iterp_shade_mode^ (         {allow quadratic texture index interpolation}
    rend_iterp_u_k, rend_iterp_mode_quad_k);
  rend_set.iterp_shade_mode^ (
    rend_iterp_v_k, rend_iterp_mode_quad_k);
  rend_set.shade_geom^ (rend_iterp_mode_quad_k); {will need data for quad U and V}

  rend_set.exit_rend^;                 {back to ENTER LEVEL found on entry}
  end;
