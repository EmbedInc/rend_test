{   Subroutine REND_TEST_RECOMPUTE_AA
*
*   Recompute the anti-aliasing configuration state given a possibly new
*   image size.  The following anti-aliasing state is assumed to be already
*   correctly set, in addition to IMAGE_WIDTH, IMAGE_HEIGHT, and ASPECT.
*
*     NX, NY - Subpixel factors for each dimension.
*
*   The following anti-aliasing state is set:
*
*     PIXX, PIXY - Final filtered image size in pixels.
*     SUBPIXX, SUBPIXY - Subpixel image size without border.
*     BORDERX, BORDERY - width of border in subpixels.
*     ASPECT - Aspect ratio of final filtered image.
*     SCALE2D - 2D transform shrink factor to account for border.
*     OFS2D - 2D transform offset to account for border.
*
*   Any other fields are not touched.
}
module rend_test_recompute_aa;
define rend_test_recompute_aa;
%include 'rend_test2.ins.pas';

procedure rend_test_recompute_aa;      {set AA state from shrink and image size}

var
  scalex, scaley: real;                {2DIM space to UNIT space scale factors}

begin
  if aa.on
    then begin                         {anti-aliasing is enabled}
      rend_set.aa_scale^ (1.0/aa.nx, 1.0/aa.ny); {set anti-aliasing scale factor}
      rend_get.aa_border^ (            {find number of pixels to add around edge}
        aa.borderx, aa.bordery);
      end
    else begin                         {anti-aliasing is not in use}
      aa.borderx := 0;
      aa.bordery := 0;
      end
    ;
  aa.pixx := (image_width - 2*aa.borderx) div aa.nx;
  aa.pixy := (image_height - 2*aa.bordery) div aa.ny;
  aa.subpixx := aa.pixx * aa.nx;
  aa.subpixy := aa.pixy * aa.ny;
  aa.aspect :=                         {aspect ratio of final filtered image}
    aspect / (image_width / image_height) * (aa.pixx / aa.pixy);
  aa.scale2d := min(                   {2D scale factor to account for border}
    aa.subpixx / (aa.subpixx + 2*aa.borderx),
    aa.subpixy / (aa.subpixy + 2*aa.bordery));
  if aspect >= 1.0
    then begin                         {image is wider than tall}
      scalex := 2.0 * aspect / image_width;
      scaley := 2.0 / image_height;
      end
    else begin                         {image it taller than wide}
      scalex := 2.0 / image_width;
      scaley := 2.0 / (aspect * image_height);
      end
    ;
  aa.ofs2d.x :=
    (0.5*(image_width - aa.subpixx) - aa.borderx) * scalex;
  aa.ofs2d.y :=
    (0.5*(image_height - aa.subpixy) - aa.bordery) * scaley;
  end;
