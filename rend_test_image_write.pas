{   Subroutine REND_TEST_IMAGE_WRITE
}
module rend_test_image_write;
define rend_test_image_write;
%include 'rend_test2.ins.pas';

procedure rend_test_image_write (      {write IMG_FNAM image file, AA if needed}
  out     stat: sys_err_t);            {completion status code}

var
  it_on: rend_iterps_t;                {set of interpolants originally on}
  it: rend_iterp_k_t;
  ofs: sys_int_machine_t;              {offset within bitmap pixel}

begin
  if aa.on and (not aa.done) then begin {need to do anti-aliasing ?}
    rend_set.enter_rend^;              {make sure we are in graphics mode}
    it_on := rend_get.iterps_on_set^;  {save which interpolants originally on}
    for it := firstof(it) to lastof(it) do begin
      rend_set.iterp_on^ (it, false);  {disable all interpolants}
      end;
    ofs := 0;
    if rend_iterp_red_k in it_on then begin {RED originally on ?}
      rend_set.iterp_on^ (rend_iterp_red_k, true); {enable interpolant}
      rend_set.iterp_src_bitmap^ (rend_iterp_red_k, bitmap_rgb, ofs); {set AA source}
      rend_set.iterp_aa^ (rend_iterp_red_k, true); {enable for anti-aliasing}
      rend_set.iterp_flat^ (rend_iterp_red_k, 0.0); {set to easy interpolation}
      ofs := ofs + 1;
      end;
    if rend_iterp_grn_k in it_on then begin {GREEN originally on ?}
      rend_set.iterp_on^ (rend_iterp_grn_k, true); {enable interpolant}
      rend_set.iterp_src_bitmap^ (rend_iterp_grn_k, bitmap_rgb, ofs); {set AA source}
      rend_set.iterp_aa^ (rend_iterp_grn_k, true); {enable for anti-aliasing}
      rend_set.iterp_flat^ (rend_iterp_grn_k, 0.0); {set to easy interpolation}
      ofs := ofs + 1;
      end;
    if rend_iterp_blu_k in it_on then begin {BLUE originally on ?}
      rend_set.iterp_on^ (rend_iterp_blu_k, true); {enable interpolant}
      rend_set.iterp_src_bitmap^ (rend_iterp_blu_k, bitmap_rgb, ofs); {set AA source}
      rend_set.iterp_aa^ (rend_iterp_blu_k, true); {enable for anti-aliasing}
      rend_set.iterp_flat^ (rend_iterp_blu_k, 0.0); {set to easy interpolation}
      end;
    if rend_iterp_alpha_k in it_on then begin {ALPHA originally on ?}
      rend_set.iterp_on^ (rend_iterp_alpha_k, true); {enable interpolant}
      rend_set.iterp_src_bitmap^ (rend_iterp_alpha_k, bitmap_alpha, 0); {set AA src}
      rend_set.iterp_aa^ (rend_iterp_alpha_k, true); {enable for anti-aliasing}
      rend_set.iterp_flat^ (rend_iterp_alpha_k, 0.0); {set to easy interpolation}
      end;
    rend_set.zon^ (false);             {disable Z compares}
    rend_set.alpha_on^ (false);        {disable alpha blending}
    rend_set.cpnt_2dimi^ (0, 0);       {go to where to put filtered rectangle}
    rend_prim.anti_alias^ (            {filter image into top left corner}
      aa.pixx, aa.pixy,                {destination rectangle size}
      aa.borderx, aa.bordery);         {top left of source rectangle}
    aa.done := true;                   {anti-aliasing has now been done}
    end;                               {done handling anti-aliasing}

  rend_set.enter_level^ (0);           {make sure we are out of graphics mode}

  rend_set.image_write^ (              {write bitmap data to image output file}
    img_fnam,                          {generic image file name}
    0, 0,                              {top left source pixel}
    aa.pixx, aa.pixy,                  {size of region to write}
    stat);
  end;
