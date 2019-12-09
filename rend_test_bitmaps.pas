module rend_test_bitmaps;
define rend_test_bitmaps;
define rend_test_resize;
define rend_test_alloc_connect;
%include 'rend_test2.ins.pas';

procedure rend_test_alloc_connect;
  extern;
{
************************************************
*
*   Local subroutine REND_TEST_ALLOC_CONNECT
*
*   Allocate the pixel memory for each of the bitmaps as required and connect
*   the interpolants to their bitmaps.  The participating interpolants are
*   listed in COMP_BITMAPS.  The bitmap handles must already have been created.
}
procedure rend_test_alloc_connect;

var
  rgb_n: sys_int_machine_t;            {number of RGB components in use}
  c: rend_test_comp_k_t;               {ID of current component}
  ofs: sys_int_machine_t;              {next pixel offset in bitmap}

begin
{
*   Handle RGB components together.
}
  rgb_n := 0;                          {init no RGB components selected}
  for c := rend_test_comp_red_k to rend_test_comp_blu_k do begin {once for each RGB}
    if c in comp_bitmaps               {this component selected ?}
      then rgb_n := rgb_n + 1;         {count one more RGB component}
    end;

  if rgb_n > 0 then begin              {allocate RGB pixels if used}
    rend_set.alloc_bitmap^ (           {allocate pixel memory for RGB bitmap}
      bitmap_rgb,                      {bitmap handle}
      image_width, image_height,       {size of bitmap in pixels}
      rgb_n,                           {amount of memory per pixel}
      rend_scope_rend_k);              {pixel memory will belong to all devices}
    end;

  ofs := 0;                            {init next pixel offset for RGB bitmap}
  if rend_test_comp_red_k in comp_bitmaps then begin {red selected ?}
    rend_set.iterp_bitmap^ (           {connect interpolant to bitmap}
      rend_iterp_red_k,                {interpolant ID}
      bitmap_rgb,                      {handle to bitmap}
      ofs);                            {offset within pixel for this interpolant}
    ofs := ofs + 1;                    {advance offset for next interpolant}
    end;
  if rend_test_comp_grn_k in comp_bitmaps then begin {green selected ?}
    rend_set.iterp_bitmap^ (           {connect interpolant to bitmap}
      rend_iterp_grn_k,                {interpolant ID}
      bitmap_rgb,                      {handle to bitmap}
      ofs);                            {offset within pixel for this interpolant}
    ofs := ofs + 1;                    {advance offset for next interpolant}
    end;
  if rend_test_comp_blu_k in comp_bitmaps then begin {blue selected ?}
    rend_set.iterp_bitmap^ (           {connect interpolant to bitmap}
      rend_iterp_blu_k,                {interpolant ID}
      bitmap_rgb,                      {handle to bitmap}
      ofs);                            {offset within pixel for this interpolant}
    end;
{
*   Handle Z component, if selected.
}
  if rend_test_comp_z_k in comp_bitmaps then begin {Z selected ?}
    rend_set.alloc_bitmap^ (           {allocate pixel memory for bitmap}
      bitmap_z,                        {bitmap handle}
      image_width, image_height,       {size of bitmap in pixels}
      2,                               {amount of memory per pixel}
      rend_scope_rend_k);              {pixel memory will belong to all devices}
    rend_set.iterp_bitmap^ (           {connect interpolant to bitmap}
      rend_iterp_z_k,                  {interpolant ID}
      bitmap_z,                        {handle to bitmap}
      0);                              {offset within pixel for this interpolant}
    end;
{
*   Handle ALPHA component, if selected.
}
  if rend_test_comp_alpha_k in comp_bitmaps then begin {ALPHA selected ?}
    rend_set.alloc_bitmap^ (           {allocate pixel memory for bitmap}
      bitmap_alpha,                    {bitmap handle}
      image_width, image_height,       {size of bitmap in pixels}
      1,                               {amount of memory per pixel}
      rend_scope_rend_k);              {pixel memory will belong to all devices}
    rend_set.iterp_bitmap^ (           {connect interpolant to bitmap}
      rend_iterp_alpha_k,              {interpolant ID}
      bitmap_alpha,                    {handle to bitmap}
      0);                              {offset within pixel for this interpolant}
    end;
  end;
{
************************************************
*
*   Subroutine REND_TEST_BITMAPS (COMP)
*
*   Allocate bitmaps for particular pixel components and connect the interpolators
*   to them, and turn the interpolants ON.  COMP is a set describing which pixel
*   components to allocate bitmaps for.  The selected interpolants will be
*   turned ON.  This routine may only be called once, since it creates the
*   bitmap handles for future use.
}
procedure rend_test_bitmaps (          {alloc bitmaps and connect to interpolants}
  in      comp: rend_test_comp_t);     {set of components to allocate pixels for}
  val_param;

begin
  comp_bitmaps := comp;                {save seleted component mask in common block}

  if                                   {RGB bitmap will be used ?}
      (rend_test_comp_red_k in comp_bitmaps) or
      (rend_test_comp_grn_k in comp_bitmaps) or
      (rend_test_comp_blu_k in comp_bitmaps)
      then begin
    rend_set.alloc_bitmap_handle^ (    {create handle to bitmap for RGB components}
      rend_scope_rend_k,               {bitmap belongs to all devices}
      bitmap_rgb);                     {handle to bitmap}
    if rend_test_comp_red_k in comp_bitmaps
      then rend_set.iterp_on^ (rend_iterp_red_k, true);
    if rend_test_comp_grn_k in comp_bitmaps
      then rend_set.iterp_on^ (rend_iterp_grn_k, true);
    if rend_test_comp_blu_k in comp_bitmaps
      then rend_set.iterp_on^ (rend_iterp_blu_k, true);
    end;

  if rend_test_comp_z_k in comp_bitmaps then begin {Z selected ?}
    rend_set.alloc_bitmap_handle^ (    {create bitmap handle}
      rend_scope_rend_k, bitmap_z);
    rend_set.iterp_on^ (rend_iterp_z_k, true); {turn interpolant ON}
    end;

  if rend_test_comp_alpha_k in comp_bitmaps then begin {ALPHA selected ?}
    rend_set.alloc_bitmap_handle^ (    {create bitmap handle}
      rend_scope_rend_k, bitmap_alpha);
    rend_set.iterp_on^ (rend_iterp_alpha_k, true); {turn interpolant ON}
    end;

  rend_test_alloc_connect;             {allocate pixel memory and connect to iterps}
  end;
{
************************************************
*
*   Subroutine REND_TEST_RESIZE
*
*   Adapt all the REND_TEST library state to the new size of the window.
*   Nothing is done if the window size did not change.
}
procedure rend_test_resize;            {update bitmaps, etc. to new draw area size}
  val_param;

var
  ix, iy: sys_int_machine_t;           {scratch integer X,Y values}
  asp: real;                           {scratch aspect ratio}

begin
  rend_get.image_size^ (ix, iy, asp);  {get new image size parameters}
  if                                   {nothing changed ?}
      (ix = image_width) and
      (iy = image_height) and
      (abs(asp - aspect) < 1.0E-5)
    then return;
  image_width := ix;                   {update new image dimensions}
  image_height := iy;
  aspect := asp;                       {update aspect ratio}

  if aspect >= 1.0
    then begin                         {image is wider than tall}
      width_2d := aspect;
      height_2d := 1.0;
      end
    else begin                         {image is taller than wide}
      width_2d := 1.0;
      height_2d := 1.0 / aspect;
      end
    ;

  rend_test_recompute_aa;              {update anti-aliasing configuration state}

  rend_test_clip_all_off;              {udpate master clip to new full draw region}
{
*   Deallocate the old pixel memory.
}
  if                                   {RGB bitmap in use ?}
      (rend_test_comp_red_k in comp_bitmaps) or
      (rend_test_comp_grn_k in comp_bitmaps) or
      (rend_test_comp_blu_k in comp_bitmaps)
      then begin
    rend_set.dealloc_bitmap^ (bitmap_rgb);
    end;
  if rend_test_comp_z_k in comp_bitmaps then begin {Z bitmap in use ?}
    rend_set.dealloc_bitmap^ (bitmap_z);
    end;
  if rend_test_comp_alpha_k in comp_bitmaps then begin {ALPHA bitmap in use ?}
    rend_set.dealloc_bitmap^ (bitmap_alpha);
    end;

  rend_test_alloc_connect;             {re-alloc pixel memory and connect to iterps}
  end;
