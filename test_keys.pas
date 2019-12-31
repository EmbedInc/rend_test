{   Program to show all the RENDlib keys.
}
program "gui" test_keys;
%include 'rend_test_all.ins.pas';

var
  polyp_save: rend_poly_parms_t;       {reset values for polygon parameters}
  keys_p: rend_key_ar_p_t;             {pointer to all known keys}
  nkeys: sys_int_machine_t;            {number of keys defined}
  key: sys_int_machine_t;              {1-N current key index}
  ev: rend_event_t;                    {RENDlib event}

label
  next_event, redraw, leave;
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
  write ('Key ', key.id);              {show RENDlib key ID}
  if key.name_p <> nil then begin      {this key has a name ?}
    write (' "', key.name_p^.str:key.name_p^.len, '"');
    end;
  if key.val_p <> nil then begin       {this key has a string value ?}
    write (' Val "', key.val_p^.str:key.val_p^.len, '"');
    end;
  case key.spkey.key of                {special key type ?}
rend_key_sp_func_k: write (' Func ', key.spkey.detail);
rend_key_sp_pointer_k: write (' Pnt ', key.spkey.detail);
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
  rend_test_cmline ('TEST_KEYS');      {process command line}
  rend_test_cmline_done;               {abort on unrecognized command line options}
  rend_test_graphics_init;             {init RENDlib, configure, enter graphics}
  rend_test_bitmaps (                  {create bitmaps and init interpolants}
    [ rend_test_comp_red_k,
      rend_test_comp_grn_k,
      rend_test_comp_blu_k
      ]
    );
{
*   Do other RENDlib initialization.
}
  if not set_bits_vis then begin       {no -BITS_VIS on command line ?}
    rend_set.min_bits_vis^ (24.0);     {request full color}
    end;

  rend_get.poly_parms^ (polyp_save);   {save polygon drawing parameters}
{
*   Get all the key definitions and show them.  All keys will also be enabled
*   for events.
}
  rend_get.keys^ (keys_p, nkeys);      {get keys info}

  for key := 1 to nkeys do begin       {once for each key}
    show_key (keys_p^[key]);
    rend_set.event_req_key_on^ (key, 99); {enabled events for this key}
    end;
 writeln;
{
*   Enable events to allow for refreshing the drawing.
}
  rend_set.event_req_close^ (true);
  rend_set.event_req_wiped_resize^ (true);
  rend_set.event_req_wiped_rect^ (true);
{
*   Back here to redraw the image.
}
redraw:
  rend_set.enter_level^ (1);           {enter graphics mode}
  rend_set.poly_parms^ (polyp_save);   {restore original polygon drawing parameters}
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
  case ev.ev_type of                   {which event is it ?}

rend_ev_none_k: begin
      goto next_event;
      end;

rend_ev_close_k,
rend_ev_close_user_k: begin
      goto leave;
      end;

rend_ev_resize_k,
rend_ev_wiped_rect_k,
rend_ev_wiped_resize_k: begin
      goto redraw;
      end;

rend_ev_key_k: begin
      if ev.key.down
        then write ('DOWN')
        else write ('UP');
      write (' at ', ev.key.x, ',', ev.key.y, ' ');
      show_key (ev.key.key_p^);
      goto next_event;
      end;

    end;                               {end of event type cases}

leave:
  rend_end;
  end.
