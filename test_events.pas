{   Program to show all the RENDlib keys, then show all the events received by
*   the graphics device.
}
program "gui" test_events;
%include 'rend_test_all.ins.pas';

const
  tgap = 0.200;                        {time between events to show a gap, seconds}
  vwid = 1.0 / 300.0;                  {vector width, fraction of min dimension}

var
  keys_p: rend_key_ar_p_t;             {pointer to all known keys}
  nkeys: sys_int_machine_t;            {number of keys defined}
  key: sys_int_machine_t;              {1-N current key index}
  vparms: rend_vect_parms_t;           {vector drawing parameters}
  ev: rend_event_t;                    {RENDlib event}
  tlast: sys_clock_t;                  {time last event received}
  tev: sys_clock_t;                    {time current event received}
  ii: sys_int_machine_t;               {scratch integer}
  r: real;                             {scratch floating point}
  s:                                   {scratch string}
    %include '(cog)lib/string132.ins.pas';

label
   resize, redraw, next_event, leave;
{
********************************************************************************
*
*   Subroutine SHOW_KEY (KEY)
*
*   Show the configuration of the RENDlib key KEY.
}
procedure show_key (                   {show the configuration of a RENDlib key}
  in      key: rend_key_t);            {RENDlib key descriptor}
  val_param;

begin
  write (key.id);                      {show RENDlib key ID}
  if key.name_p <> nil then begin      {this key has a name ?}
    write (' "', key.name_p^.str:key.name_p^.len, '"');
    end;
  if key.val_p <> nil then begin       {this key has a string value ?}
    write (' Val "', key.val_p^.str:key.val_p^.len, '"');
    end;
  case key.spkey.key of                {special key type ?}
rend_key_sp_func_k: write (' Func ', key.spkey.detail);
rend_key_sp_pointer_k: write (' Pointer ', key.spkey.detail);
rend_key_sp_arrow_left_k: write (' Left arrow');
rend_key_sp_arrow_right_k: write (' Right arrow');
rend_key_sp_arrow_up_k: write (' Up arrow');
rend_key_sp_arrow_down_k: write (' Down arrow');
      end;                             {end of special key cases}
  writeln;
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  rend_test_cmline ('TEST_EVENTS');    {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k
      ]
    );
{
*   Get all the key definitions and show them.  All keys will also be enabled
*   for events.
}
  rend_get.keys^ (keys_p, nkeys);      {get keys info}

  for key := 1 to nkeys do begin       {once for each key}
    write ('Key ');
    show_key (keys_p^[key]);
    rend_set.event_req_key_on^ (key, 99); {enabled events for this key}
    end;
 writeln;
{
*   Enable events to allow for refreshing the drawing.
}
  rend_set.event_req_close^ (true);
  rend_set.event_req_pnt^ (true);
  rend_set.event_req_rotate_on^ (1.0);
  rend_set.event_req_translate^ (true);
  rend_set.event_req_wiped_resize^ (true);
  rend_set.event_req_wiped_rect^ (true);
{
*   Do other initialization.
}
  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;

  rend_get.vect_parms^ (vparms);       {get initial vector drawing parameters}
  vparms.subpixel := true;             {enable sub-pixel addressing}
  vparms.start_style.style := rend_end_style_rect_k;
  vparms.end_style.style := rend_end_style_rect_k;
  vparms.width := 2.0 * vwid;          {width when drawing vectors as polgons}

  tlast :=                             {init last event time to guaranteed gap}
    sys_clock_sub (
      sys_clock,                       {start with the current time}
      sys_clock_from_fp_rel (tgap * 2.0) {minus twice the gap time}
      );
{
*   Back here to adjust to new window size.
}
resize:
  rend_test_resize;                    {update to the current draw area size}
  string_f_fp_fixed (s, aspect, 3);
  writeln ('Size ', image_width, ',', image_height, ' aspect ', s.str:s.len);

  ii := min(image_width, image_height); {get minimum dimension in pixels}
  r := ii * vwid;                      {make raw vector width in pixels}
  if r < 2.0
    then begin                         {would be too thin, draw pixel vectors}
      vparms.poly_level := rend_space_none_k; {draw as integer vectors}
      end
    else begin                         {wide enough}
      vparms.poly_level := rend_space_2d_k; {convert to vectors in 2D space}
      end
    ;
  rend_set.vect_parms^ (vparms);       {update vector drawing parameters}
{
*   Back here to redraw the image.
}
redraw:
  rend_set.enter_level^ (1);           {enter graphics mode}
{
*   Clear the whole image to the background color.
}
  rend_set.rgb^ (0.15, 0.15, 0.6);     {background color value}
  rend_prim.clear_cwind^;              {clear whole image to background color}
{
*   Draw diagonals.
}
  rend_set.rgb^ (1.0, 1.0, 1.0);       {diagonal lines foreground color}
  rend_set.cpnt_2d^ (width_2d, 0.0);
  rend_prim.vect_2d^ (0.0, height_2d);
  rend_prim.vect_2d^ (-width_2d, 0.0);
  rend_prim.vect_2d^ (0.0, -height_2d);
  rend_prim.vect_2d^ (width_2d, 0.0);

  rend_set.exit_rend^;                 {leave graphics mode}
{
*   Wait for the next event and handle it.
}
next_event:
  rend_event_get (ev);                 {get the next event}

  tev := sys_clock;                    {save time this event was received}
  r := sys_clock_to_fp2 (              {make seconds since previous event}
    sys_clock_sub (tev, tlast) );
  if r >= tgap then begin              {time gap since last event ?}
    writeln;                           {leave blank line to show the time gap}
    end;
  tlast := tev;                        {update time of last event for next time}

  case ev.ev_type of                   {which event is it ?}

rend_ev_none_k: begin
      writeln ('NONE');
      goto next_event;
      end;

rend_ev_close_k: begin
      writeln ('CLOSE');
      goto leave;
      end;

rend_ev_resize_k: begin
      writeln ('RESIZE');
      goto redraw;
      end;

rend_ev_wiped_rect_k: begin
      write ('WIPED RECT');
      write (' buf ', ev.wiped_rect.bufid);
      write (' coor ', ev.wiped_rect.x, ',', ev.wiped_rect.y);
      writeln (' size ', ev.wiped_rect.dx, ',', ev.wiped_rect.dy);
      goto redraw;
      end;

rend_ev_wiped_resize_k: begin
      writeln ('WIPED RESIZE');
      goto resize;
      end;

rend_ev_key_k: begin
      write ('KEY ');
      if ev.key.down
        then write ('down')
        else write ('up');
      write (' at ', ev.key.x, ',', ev.key.y, ', ID ');
      show_key (ev.key.key_p^);
      goto next_event;
      end;

rend_ev_pnt_enter_k: begin
      writeln ('PNT ENTER at ', ev.pnt_enter.x, ',', ev.pnt_enter.y);
      goto next_event;
      end;

rend_ev_pnt_exit_k: begin
      writeln ('PNT EXIT at ', ev.pnt_exit.x, ',', ev.pnt_exit.y);
      goto next_event;
      end;

rend_ev_pnt_move_k: begin
      writeln ('PNT MOVE at ', ev.pnt_move.x, ',', ev.pnt_move.y);
      goto next_event;
      end;

rend_ev_close_user_k: begin
      writeln ('CLOSE USER');
      goto leave;
      end;

rend_ev_stdin_line_k: begin
      rend_get_stdin_line (s);
      writeln ('STDIN LINE "', s.str:s.len, '"');
      goto next_event;
      end;

rend_ev_xf3d_k: begin
      writeln ('XF3D');
      goto next_event;
      end;

    end;                               {end of event type cases}

leave:
  rend_end;
  end.
