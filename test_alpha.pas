{   Program to test alpha buffering capability of RENDlib.
}
program "gui" test_alpha;
%include 'rend_test_all.ins.pas';

var
  dith_on: boolean;                    {TRUE if dithering ended up ON}
  xb, yb, ofs: vect_2d_t;              {2D transformation matrix}
  p1, p2, p3: vect_2d_t;               {scratch points in 2D space}
  q1, q2, q3: vect_2d_t;               {scratch points in 2DIM space}
  strip_y: real;                       {center Y coordinate for alpha strip}
  dstrip_y: real;                      {increment for next STRIP_Y value}
  tparms: rend_text_parms_t;           {text control parameters}
  shrink: real;                        {shrink factor for strips}
  rgba1, rgba2, rgba3: rend_rgba_t;    {red, green, blue, alpha at corner points}
{
*************************************************************************************
*
*   Internal subroutine DRAW_STRIP (AFUNC,ANAM)
*
*   Draw interpolated alpha buffer test strip with alpha function AFUNC.  ANAM is
*   the name of the alpha function.
}
procedure draw_strip (
  in      afunc: rend_afunc_k_t;       {alpha function ID code}
  in      anam: univ string_var_arg_t); {name of this alpha function}
  val_param;

begin
{
*   Draw the alpha buffered strip.
}
  rend_set.alpha_on^ (true);           {turn on alpha buffering}
  rend_set.alpha_func^ (afunc);        {set alpha function}

  p1.x := 2.0*shrink;                  {lower left corner of strip}
  p1.y := strip_y - 0.5*dstrip_y + shrink;
  p2.x := p1.x + 1.0 - 4.0*shrink;     {lower right corner point}
  p2.y := p1.y;
  p3.x := p1.x;                        {upper left corner point}
  p3.y := p1.y + dstrip_y - 2.0*shrink;

  rend_get.xfpnt_2d^ (p1, q1);         {make corner points transformed to 2DIM space}
  rend_get.xfpnt_2d^ (p2, q2);
  rend_get.xfpnt_2d^ (p3, q3);

  rend_set.lin_geom_2dim^ (q1, q2, q3); {set geometry for linear interpolation}
  rgba1.red := 1.0;                    {set colors at corner points}
  rgba1.grn := 0.0;
  rgba1.blu := 1.0;
  rgba1.alpha := 0.0;
  rgba2.red := rgba1.red;
  rgba2.grn := rgba1.grn;
  rgba2.blu := rgba1.blu;
  rgba2.alpha := rgba1.alpha;
  rgba3.red := 1.0;
  rgba3.grn := 0.0;
  rgba3.blu := 1.0;
  rgba3.alpha := 1.0;
  rend_set.lin_vals_rgba^ (rgba1, rgba2, rgba3); {set linear alpha, quadratic R,G,B}
  rend_set.cpnt_2dim^ (q1.x, q1.y);    {go to lower left corner of strip}
  rend_prim.rect_2dim^ (               {draw strip as a rectangle}
    q2.x - q1.x,                       {width of rectangle}
    q3.y - q1.y);                      {height of rectangle}
{
*   Draw the label.
}
  rend_set.alpha_on^ (false);          {turn off alpha buffering}
  rend_set.rgb^ (1.0, 1.0, 1.0);       {text color}
  rend_set.iterp_flat^ (rend_iterp_alpha_k, 1.0);
  rend_set.cpnt_2d^ (-tparms.size, strip_y); {move to right center of text string}
  rend_set.dith_on^ (false);           {force dithering OFF}
  rend_prim.text^ (anam.str, anam.len); {draw the label}
  rend_set.dith_on^ (dith_on);         {restore dithering mode}

  strip_y := strip_y-dstrip_y;         {move down to next strip}
  end;
{
**************************************************************************************
*
*   Start of main routine.
}
begin
  rend_test_cmline ('TEST_ALPHA');     {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k,
      rend_test_comp_alpha_k]
    );
{
*   Do other RENDlib initialization.
}
  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;
  rend_get.dith_on^ (dith_on);         {save whether we ended up dithering or not}
{
*   Set up the 2D transform such that the active area to the right extends from
*   (0,0) to (1,1).
}
  xb.y := 0.0;                         {set the fixed transform parameters}
  yb.x := 0.0;
  if aspect >= 1.0                     {check for tall or wide}
    then begin                         {image is wider than tall}
      xb.x := 1.3333*aspect;
      yb.y := 2.0;
      ofs.x := -0.3333*aspect;
      ofs.y := -1.0;
      end
    else begin                         {image is taller than wide}
      xb.x := 1.3333;
      yb.y := 2.0/aspect;
      ofs.x := -0.3333;
      ofs.y := -1.0/aspect;
      end
    ;
  rend_set.xform_2d^ (xb, yb, ofs);
{
*   Draw the black background behind where the text goes.
}
  rend_set.rgb^ (0.0, 0.0, 0.0);
  rend_set.iterp_flat^ (rend_iterp_alpha_k, 1.0);
  rend_set.cpnt_2d^ (0.0, 0.0);
  rend_set.dith_on^ (false);           {draw background as fast as possible}
  rend_prim.rect_2d^ (-0.5*xb.x, 1.0); {draw black text region to the left}
  rend_set.dith_on^ (dith_on);         {restore dithering mode}
{
*   Draw the green interplated rectangle which will be the background for the
*   alpha buffered patches.
}
  p1.x := 0.0;                         {set anchor point for linear interpolation}
  p1.y := 0.0;
  p2.x := 1.0;
  p2.y := p1.y;
  p3.x := p1.x;
  p3.y := 1.0;

  rend_get.xfpnt_2d^ (p1, q1);         {make corner points transformed to 2DIM space}
  rend_get.xfpnt_2d^ (p2, q2);
  rend_get.xfpnt_2d^ (p3, q3);

  rend_set.lin_geom_2dim^ (q1, q2, q3); {set geometry for linear interpolation}
  rgba1.red := 0.0;                    {set colors at corner points}
  rgba1.grn := 1.0;
  rgba1.blu := 1.0;
  rgba1.alpha := 0.0;
  rgba2.red := 0.0;
  rgba2.grn := 1.0;
  rgba2.blu := 1.0;
  rgba2.alpha := 1.0;
  rgba3.red := rgba1.red;
  rgba3.grn := rgba1.grn;
  rgba3.blu := rgba1.blu;
  rgba3.alpha := rgba1.alpha;
  rend_set.lin_vals_rgba^ (rgba1, rgba2, rgba3); {set linear alpha, quadratic R,G,B}

  rend_set.force_sw_update^ (true);
  rend_set.cpnt_2d^ (0.0, 0.0);
  rend_prim.rect_2d^ (1.0, 1.0);       {draw interpolated alpha background}
  rend_set.force_sw_update^ (false);
{
*   Init before doing the 12 alpha cases.
}
  rend_get.text_parms^ (tparms);       {get current text control parameters}
  tparms.coor_level := rend_space_2d_k;
  tparms.size := 0.04;
  tparms.width := 0.85*yb.y/xb.x;
  tparms.start_org := rend_torg_mr_k;
  tparms.vect_width := 0.1;
  tparms.poly := true;
  rend_set.text_parms^ (tparms);       {set text control parameters}

  dstrip_y := 1.0/12.0;                {Y offset for each alpha strip}
  strip_y := 1.0 - 0.5*dstrip_y;       {init to center of top strip}
  shrink := 0.08*dstrip_y;             {distance to shrink strips by}
{
*   Draw the 12 alpha function cases.
}
  draw_strip (rend_afunc_clear_k, string_v('clear'));
  draw_strip (rend_afunc_a_k, string_v('a'));
  draw_strip (rend_afunc_b_k, string_v('b'));
  draw_strip (rend_afunc_over_k, string_v('over'));
  draw_strip (rend_afunc_rover_k, string_v('rover'));
  draw_strip (rend_afunc_in_k, string_v('in'));
  draw_strip (rend_afunc_rin_k, string_v('rin'));
  draw_strip (rend_afunc_out_k, string_v('out'));
  draw_strip (rend_afunc_rout_k, string_v('rout'));
  draw_strip (rend_afunc_atop_k, string_v('atop'));
  draw_strip (rend_afunc_ratop_k, string_v('ratop'));
  draw_strip (rend_afunc_xor_k, string_v('xor'));

  rend_test_end;                       {clean up and exit graphics}
  end.
