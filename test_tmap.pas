{   Program to test texture mapping capability of RENDlib.
}
program "gui" test_tmap;
%include 'rend_test_all.ins.pas';

const
  max_msg_parms = 4;                   {max parameters we can pass messages}

var
  tmap_bitmap: rend_bitmap_handle_t;   {handle to texture map source bitmap}
  img: img_conn_t;                     {connection handle to texture map image}
  xb, yb, ofs: vect_2d_t;              {2D transformation matrix}
  p4, p5, p6: vect_2d_t;               {scratch points in 2D space}
  q1, q2, q3, q4, q5, q6: vect_2d_t;   {scratch points in 2DIM space}
  scale: real;                         {scratch scale factor}
  poly: rend_2dverts_t;                {coordinates for a polygon}
  msg_parm:                            {parameter reference for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {system-independent error code}

label
  redraw;

begin
  rend_test_cmline ('TEST_TMAP');      {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}

  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k
      ]
    );

  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;
{
*   Read the texture map image file and init the texture mapping state.
}
  img_open_read_img (                  {open texture map image file for read}
    tmap_fnam,                         {image file name}
    img,                               {image connection handle}
    stat);
  sys_msg_parm_vstr (msg_parm[1], tmap_fnam);
  sys_error_abort (stat, 'img', 'open_read', msg_parm, 1);

  rend_test_tmap_read (                {read tmap image file and init tmap state}
    img,                               {image file connection handle}
    tmap_bitmap);                      {returned handle to new texture map bitmap}
{
*   Draw the background.
}
  rend_set.tmap_on^ (false);           {disable texture mapping for now}
  rend_set.rgb^ (0.2, 0.2, 0.2);
  rend_prim.clear_cwind^;
  rend_set.tmap_on^ (true);            {draw texture mapped prims from now on}
{
*   Set up transform.  We will draw within a +-1 square.
}
  scale := 0.8;
  xb.x := 0.966 * scale;
  xb.y := 0.259 * scale;
  yb.x := -0.259 * scale;
  yb.y := 0.966 * scale;
  ofs.x := 0.0;
  ofs.y := 0.0;
  rend_set.xform_2d^ (xb, yb, ofs);    {set new current 2D transform}
{
*   Back here to redraw image due to refresh event.
}
redraw:
  rend_set.enter_level^ (1);           {make sure we are in graphics mode}
{
*   Draw triangle using INSERT texture mapping function.
}
  rend_set.tmap_func^ (rend_tmapf_insert_k); {set texture mapping function}

  poly[1].x := 1.0;                    {set 2D space triangle coordinates}
  poly[1].y := 1.0;
  poly[2].x := -1.0;
  poly[2].y := 1.0;
  poly[3].x := -1.0;
  poly[3].y := -1.0;
  p4.x := 0.0;
  p4.y := 1.0;
  p5.x := -1.0;
  p5.y := 0.0;
  p6.x := 0.0;
  p6.y := 0.0;

  rend_get.xfpnt_2d^ (poly[1], q1);    {transform points to 2DIM space}
  rend_get.xfpnt_2d^ (poly[2], q2);
  rend_get.xfpnt_2d^ (poly[3], q3);
  rend_get.xfpnt_2d^ (p4, q4);
  rend_get.xfpnt_2d^ (p5, q5);
  rend_get.xfpnt_2d^ (p6, q6);

  rend_set.iterp_flat^ (rend_iterp_red_k, 0.0); {colors ignored, set to flat interp}
  rend_set.iterp_flat^ (rend_iterp_grn_k, 0.0);
  rend_set.iterp_flat^ (rend_iterp_blu_k, 0.0);

  rend_set.quad_geom_2dim^ (q1, q2, q3, q4, q5, q6); {quad interpolation anchor points}
  rend_set.quad_vals^ (rend_iterp_u_k,
    1.0, 0.0, 0.0, 0.15, 0.0, 0.15);
  rend_set.quad_vals^ (rend_iterp_v_k,
    0.0, 0.0, 1.0, 0.0, 0.85, 0.85);

  rend_prim.poly_2d^ (3, poly);        {draw the triangle}
{
*   Draw triangle using illuminated texture map.
}
  rend_set.tmap_func^ (rend_tmapf_ill_k); {set texture mapping function}

  poly[1].x := 1.0;                    {set 2D space triangle coordinates}
  poly[1].y := 1.0;
  poly[2].x := -1.0;
  poly[2].y := -1.0;
  poly[3].x := 1.0;
  poly[3].y := -1.0;
  p4.x := 1.0;
  p4.y := 0.0;
  p5.x := 0.0;
  p5.y := 0.0;
  p6.x := 0.0;
  p6.y := -1.0;

  rend_get.xfpnt_2d^ (poly[1], q1);    {transform points to 2DIM space}
  rend_get.xfpnt_2d^ (poly[2], q2);
  rend_get.xfpnt_2d^ (poly[3], q3);
  rend_get.xfpnt_2d^ (p4, q4);
  rend_get.xfpnt_2d^ (p5, q5);
  rend_get.xfpnt_2d^ (p6, q6);

  rend_set.lin_geom_2dim^ (q1, q2, q3); {set anchor points for linear interpolation}
  rend_set.lin_vals^ (rend_iterp_red_k, 0.0, 1.0, 1.0);
  rend_set.lin_vals^ (rend_iterp_grn_k, 1.0, 0.0, 1.0);
  rend_set.lin_vals^ (rend_iterp_blu_k, 1.0, 1.0, 0.0);

  rend_set.quad_geom_2dim^ (q1, q2, q3, q4, q5, q6); {quad interpolation anchor points}
  rend_set.quad_vals^ (rend_iterp_u_k,
    1.0, 0.0, 1.0, 1.0, 0.15, 0.15);
  rend_set.quad_vals^ (rend_iterp_v_k,
    0.0, 1.0, 1.0, 0.85, 0.85, 1.0);

  rend_prim.poly_2d^ (3, poly);        {draw the triangle}

  if rend_test_refresh then goto redraw;
  end.
