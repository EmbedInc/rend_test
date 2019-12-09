program "gui" test_text;
%include 'rend_test_all.ins.pas';

const
  pi = 3.141593;
  deg_rad = pi/180.0;                  {mult factor to convert degrees to radians}

var
  color_backg: rend_rgb_t :=           {background color}
    [red := 0.15, grn := 0.15, blu := 0.60];

  tparms: rend_text_parms_t;           {text control parameters}
  vparms: rend_vect_parms_t;           {generic vector control parameters}
  sx, sy: real;                        {saved coordinate point}
  color_txt: rend_rgb_t;               {color to be used by TXT calls}
  txt_xor: boolean;                    {TRUE when text being drawn in XOR mode}
{
******************************************
*
*   Internal subroutine TXT_COLOR (R,G,B)
*
*   Set color to be used by future TXT calls.
}
procedure txt_color (
  in      r, g, b: real);              {red, green, blue color (0.0 to 1.0)}
  val_param;

var
  color: rend_rgb_t;                   {scratch color value}

begin
  if txt_xor
    then begin                         {text will be drawn in XOR mode}
      color.red := r;
      color.grn := g;
      color.blu := b;
      rend_get.color_xor^ (color_backg, color, color_txt);
      end
    else begin                         {using normal INSERT pixel function}
      color_txt.red := r;
      color_txt.grn := g;
      color_txt.blu := b;
      end
    ;
  end;
{
******************************************
*
*   Internal subroutine TXT (S)
*
*   Draw the text string.  Size is computed automatically by truncating trailing
*   blanks.
}
procedure txt (
  in      s: string);                  {the character string to draw}

var
  v: string_var80_t;                   {var string of text S}
  bv: vect_2d_t;                       {TXDRAW space baseline vector}
  up: vect_2d_t;                       {TXDRAW space character cell UP vector}
  ll: vect_2d_t;                       {lower left corner of text string box}
  cp: vect_2d_t;                       {saved current point}

begin
  v.max := sizeof(v.str);
  string_vstring (v, s, sizeof(s));    {make var string of input string}

  rend_get.txbox_txdraw^ (             {get box around text string char cells}
    v.str, v.len,                      {text string characters and length}
    bv,                                {baseline vector}
    up,                                {char cell up vector}
    ll);                               {lower left coordinate of text box}
  rend_get.cpnt_txdraw^ (cp.x, cp.y);  {save existing current point}

  rend_set.rgb^ (                      {set color for drawing text string box}
    color_txt.red * 0.5,
    color_txt.grn * 0.5,
    color_txt.blu * 0.5);

  rend_set.cpnt_txdraw^ (ll.x, ll.y);  {go to lower left text box corner}
  rend_prim.rvect_txdraw^ (bv.x, bv.y); {outline the text string box}
  rend_prim.rvect_txdraw^ (up.x, up.y);
  rend_prim.rvect_txdraw^ (-bv.x, -bv.y);
  rend_prim.rvect_txdraw^ (-up.x, -up.y);
  rend_set.cpnt_txdraw^ (cp.x, cp.y);  {restore TXDRAW space current point}

  rend_set.rgb^ (color_txt.red, color_txt.grn, color_txt.blu); {set color for drawing text string}
  rend_prim.text^ (v.str, v.len);      {draw the text string}
  end;
{
******************************************
*
*   Local subroutine FONT_PATHNAME (GNAM, FNAM)
*
*   Make the full font file name in FNAM from the generic font name in GNAM.
}
procedure font_pathname (              {make font file pathname from generic name}
  in      gnam: univ string_var_arg_t; {generic font name}
  in out  fnam: univ string_var_arg_t); {returned font file name}
  val_param;

var
  name: string_leafname_t;             {var string copy of GNAM}

begin
  name.max := sizeof(name.str);        {init local var string}

  string_vstring (name, gnam, sizeof(gnam)); {make var string generic font name}
  sys_cognivis_dir ('fonts', fnam);    {start with Cognivision fonts directory}
  string_append1 (fnam, '/');
  string_append (fnam, name);
  end;
{
******************************************
*
*   Start of main routine.
}
begin
  txt_xor := false;                    {init to not drawing text in XOR mode}
  rend_test_cmline ('TEST_TEXT');      {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k
      ]
    );
  rend_set.iterp_shade_mode^ (rend_iterp_red_k, rend_iterp_mode_flat_k);
  rend_set.iterp_shade_mode^ (rend_iterp_grn_k, rend_iterp_mode_flat_k);
  rend_set.iterp_shade_mode^ (rend_iterp_blu_k, rend_iterp_mode_flat_k);
{
*   Clear the whole image to the background color.
}
  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;
  rend_set.rgb^ (                      {set background color value}
    color_backg.red, color_backg.grn, color_backg.blu);
  rend_prim.clear^;

  rend_get.text_parms^ (tparms);       {get current text control parameters}
  rend_get.vect_parms^ (vparms);       {get current vector control parameters}
{
*   Draw a box so that we can draw text at known locations later.
}
  rend_set.rgb^ (0.5, 0.5, 0.5);       {color of outer box}
  rend_set.cpnt_2d^ (0.9, 0.9);
  rend_prim.vect_2d^ (-0.9, 0.9);
  rend_prim.vect_2d^ (-0.9, -0.9);
  rend_prim.vect_2d^ (0.9, -0.9);
  rend_prim.vect_2d^ (0.9, 0.9);

  vparms.poly_level := rend_space_2dim_k; {draw crosshairs in the box}
  vparms.width := 4;
  vparms.start_style.style := rend_end_style_rect_k;
  vparms.end_style.style := rend_end_style_rect_k;
  rend_set.vect_parms^ (vparms);
  rend_set.rgb^ (0.0, 0.0, 0.0);
  rend_set.cpnt_2d^ (0.9, 0.0);
  rend_prim.vect_2d^ (-0.9, 0.0);
  rend_set.cpnt_2d^ (0.0, 0.9);
  rend_prim.vect_2d^ (0.0, -0.9);
{
*   Draw text at all the TORG points relative to the box.
}
  txt_color (1.0, 1.0, 1.0);
  vparms.poly_level := rend_space_none_k;
  rend_set.vect_parms^ (vparms);
  tparms.coor_level := rend_space_2d_k;
  tparms.size := 0.05;
  tparms.poly := false;
  tparms.start_org := rend_torg_ul_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (-0.9, 0.9);
  txt ('upper left');
  tparms.start_org := rend_torg_um_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (0.0, 0.9);
  txt ('upper mid');
  tparms.start_org := rend_torg_ur_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (0.9, 0.9);
  txt ('upper right');
  tparms.start_org := rend_torg_ml_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (-0.9, 0.0);
  txt ('mid left');
  tparms.start_org := rend_torg_mid_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (0.0, 0.0);
  txt ('mid');
  tparms.start_org := rend_torg_mr_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (0.9, 0.0);
  txt ('mid right');
  tparms.start_org := rend_torg_ll_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (-0.9, -0.9);
  txt ('lower left');
  tparms.start_org := rend_torg_lm_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (0.0, -0.9);
  txt ('lower mid');
  tparms.start_org := rend_torg_lr_k;
  rend_set.text_parms^ (tparms);
  rend_set.cpnt_2d^ (0.9, -0.9);
  txt ('lower right');
{
*   Draw slanted text.
}
  rend_set.cpnt_2d^ (0.0, 0.6);
  tparms.size := 0.1;
  tparms.poly := true;
  tparms.start_org := rend_torg_um_k;
  tparms.slant := 15.0 * deg_rad;
  rend_set.text_parms^ (tparms);
  txt ('Slant 15');
  tparms.slant := -15.0 * deg_rad;
  rend_set.text_parms^ (tparms);
  txt ('Slant -15');
{
*   Draw rotated text.
}
  rend_set.cpnt_2d^ (0.0, -0.3);
  tparms.start_org := rend_torg_mid_k;
  tparms.slant := 0.0;
  tparms.rot := 15.0 * deg_rad;
  rend_set.text_parms^ (tparms);
  txt ('Rotate 15');
  txt ('Line 2.');
{
*   Draw the "equation".
}
  rend_set.cpnt_2d^ (-1.0, 0.0);
  txt_color (1.0, 1.0, 0.0);
  tparms.start_org := rend_torg_ml_k;
  tparms.slant := 0.0;
  tparms.rot := 0.0;
  tparms.size := 0.22;
  tparms.end_org := rend_torg_mr_k;
  tparms.vect_width := 0.08;
  tparms.width := 0.75;
  font_pathname ('sanserif.h', tparms.font);
  rend_set.text_parms^ (tparms);
  txt ('X =');
  font_pathname ('music.h', tparms.font);
  rend_set.text_parms^ (tparms);
  txt (' l');                          {integral sign}
  rend_get.cpnt_2d^ (sx, sy);          {save current point after integral sign}
  rend_set.cpnt_2d^ (sx, sy+0.25);
  font_pathname ('sanserif.h', tparms.font);
  tparms.size := 0.13;
  rend_set.text_parms^ (tparms);
  txt ('t');
  rend_set.cpnt_2d^ (sx-0.15, sy-0.25);
  txt ('0');
  rend_set.cpnt_2d^ (sx, sy);          {restore to after integral sign}
  tparms.size := 0.25;
  rend_set.text_parms^ (tparms);
  txt ('sin(');
  font_pathname ('simplex.h', tparms.font);
  rend_set.text_parms^ (tparms);
  txt ('Z');                           {upper case theta}
  font_pathname ('sanserif.h', tparms.font);
  rend_set.text_parms^ (tparms);
  txt (')d');
  font_pathname ('greek.simplex.h', tparms.font);
  rend_set.text_parms^ (tparms);
  txt ('Z');                           {upper case theta}
  font_pathname ('sanserif.h', tparms.font);
  rend_set.text_parms^ (tparms);
{
*   Test XOR pixel functions for red, green, and blue.
}
  rend_prim.flush_all^;
  sys_wait (1.0);                      {wait before drawing XOR}

  tparms.size := 0.2;
  tparms.width := 0.8;
  tparms.height := 1.0;
  tparms.slant := 0.0;
  tparms.rot := 0.0;
  tparms.lspace := 1.0;
  tparms.vect_width := 0.13;
  font_pathname ('simplex.h', tparms.font);
  tparms.coor_level := rend_space_2d_k;
  tparms.start_org := rend_torg_ul_k;
  tparms.end_org := rend_torg_ul_k;
  tparms.poly := true;
  rend_set.text_parms^ (tparms);

  rend_set.iterp_pixfun^ (rend_iterp_red_k, rend_pixfun_xor_k); {set XOR pixfun mode}
  rend_set.iterp_pixfun^ (rend_iterp_grn_k, rend_pixfun_xor_k);
  rend_set.iterp_pixfun^ (rend_iterp_blu_k, rend_pixfun_xor_k);
  txt_xor := true;                     {indicate text will be drawn with XOR pixfun}
  rend_set.cpnt_2d^ (-0.95, -0.20);

  txt_color (1.0, 0.0, 0.0);
  txt ('RED');
  rend_prim.flush_all^;
  sys_wait (1.5);
  txt ('RED');

  txt_color (0.0, 1.0, 0.0);
  txt ('GREEN');
  rend_prim.flush_all^;
  sys_wait (1.5);
  txt ('GREEN');

  txt_color (0.0, 0.0, 1.0);
  txt ('BLUE');
  rend_prim.flush_all^;
  sys_wait (1.5);
  txt ('BLUE');

  txt_color (1.0, 1.0, 1.0);
  txt ('WHITE');
  rend_prim.flush_all^;
  sys_wait (1.5);
  txt ('WHITE');

  rend_prim.flush_all^;
  sys_wait (1.0);

  rend_test_end;                       {clean up and exit graphics}
  end.
