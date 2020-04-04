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
  flog:                                {log output file name}
    %include '(cog)lib/string_treename.ins.pas';
  sout:                                {output line}
    %include '(cog)lib/string132.ins.pas';
  conn_log: file_conn_t;               {connection to log output file}
  logfile: boolean;                    {TRUE if writing to log file, not STDOUT}

  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  stat: sys_err_t;                     {completion status code}

label
  next_opt, parm_bad, done_opts,
  resize, redraw, next_event, leave;
{
********************************************************************************
*
*   Subroutine WLINE
*
*   Write the current output line, then reset the output line to empty.
}
procedure wline;
  val_param;

var
  stat: sys_err_t;

begin
  if logfile
    then begin
      file_write_text (sout, conn_log, stat); {write line to log file}
      sys_error_abort (stat, '', '', nil, 0);
      end
    else begin
      writeln (sout.str:sout.len);     {write the line to standard output}
      end
    ;

  sout.len := 0;                       {reset the pending output line to blank}
  end;
{
********************************************************************************
*
*   Subroutine WCHAR (C)
*
*   Write the single character C.  C is written directly if it is printable.  If
*   not, it is written as a decimal integer within "<" and ">".
}
procedure wchar (                      {write character to output line}
  in      c: char);                    {character to write}
  val_param;

begin
  if (ord(c) >= 32) and (ord(c) <= 126) then begin {printable character ?}
    string_append1 (sout, c);
    return;
    end;
{
*   Not a printable character.
}
  string_append1 (sout, '<');
  string_append_intu (sout, ord(c), 0);
  string_append1 (sout, '>');
  end;
{
********************************************************************************
*
*   Subroutine WVSTR (VSTR)
*
*   Add the var string VSTR to the current output line.
}
procedure wvstr (                      {write string to output line}
  in      vstr: univ string_var_arg_t); {the string to write}
  val_param;

var
  ii: sys_int_machine_t;

begin
  for ii := 1 to vstr.len do begin
    wchar (vstr.str[ii]);
    end;
  end;
{
********************************************************************************
*
*   Subroutine WSTR (STR)
*
*   Add the Pascal string STR to the current output line.
}
procedure wstr (                       {write Pascal string to output line}
  in      str: string);                {the string to write}
  val_param;

var
  vstr: string_var132_t;

begin
  vstr.max := size_char(vstr.str);     {init local var string}

  string_vstring (vstr, str, size_char(str)); {convert to var string}
  wvstr (vstr);                        {write the var string to the output line}
  end;
{
********************************************************************************
*
*   Subroutine WINT (II)
*
*   Write the integer value of II in decimal to the current output line.
}
procedure wint (                       {write integer to output line}
  in      ii: sys_int_machine_t);      {the integer value to write}
  val_param;

var
  tk: string_var32_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_int (tk, ii);               {make integer value string}
  wvstr (tk);                          {add it to the output line}
  end;
{
********************************************************************************
*
*   Subroutine WFP_FIXED (FP, DIGR)
*
*   Write floating point value with fixed number of fraction digits.
}
procedure wfp_fixed (                  {write FP, fixed number of fraction digits}
  in      fp: real;                    {the value to write}
  in      digr: sys_int_machine_t);    {number of digits right of decimal point}
  val_param;

var
  tk: string_var32_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_fp_fixed (                  {convert value to string}
    tk,                                {output string}
    fp,                                {input value}
    digr);                             {digits right of decimal point}
  wvstr (tk);                          {write the string to the output line}
  end;
{
********************************************************************************
*
*   Subroutine WICOOR (IX, IY)
*
*   Write integer 2D coordinate to the output line.
}
procedure wicoor (                     {write integer X,Y to output line}
 in      ix, iy: sys_int_machine_t);   {coordinate to write}
  val_param;

begin
 wint (ix);
 wstr (',');
 wint (iy);
 end;
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
  wint (key.id);                       {show RENDlib key ID}
  if key.name_p <> nil then begin      {this key has a name ?}
    wstr (' "'); wvstr (key.name_p^); wstr ('"');
    end;
  if key.val_p <> nil then begin       {this key has a string value ?}
    wstr (' Val "');
    wvstr (key.val_p^);
    wstr ('"');
    end;

  case key.spkey.key of                {special key type ?}
rend_key_sp_func_k: begin
      wstr (' Func '); wint (key.spkey.detail);
      end;
rend_key_sp_pointer_k: begin
      wstr (' Pointer '); wint (key.spkey.detail);
      end;
rend_key_sp_arrow_left_k: begin
      wstr (' Left arrow');
      end;
rend_key_sp_arrow_right_k: begin
      wstr (' Right arrow');
      end;
rend_key_sp_arrow_up_k: begin
      wstr (' Up arrow');
      end;
rend_key_sp_arrow_down_k: begin
      wstr (' Down arrow');
      end;
rend_key_sp_pageup_k: begin
      wstr (' Page Up');
      end;
rend_key_sp_pagedn_k: begin
      wstr (' Page Down');
      end;
rend_key_sp_del_k: begin
      wstr (' Delete');
      end;
rend_key_sp_home_k: begin
      wstr (' Home');
      end;
rend_key_sp_end_k: begin
      wstr (' End');
      end;
    end;                               {end of special key cases}

  wline;
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  logfile := false;                    {init to not writing to log file}
  rend_test_cmline ('TEST_EVENTS');    {process standard RENDlib test command line options}
{
*   Back here each new command line option.
}
next_opt:
  rend_test_cmline_token (opt, stat);  {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-LOG',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -LOG fnam
}
1: begin
  rend_test_cmline_token (flog, stat); {get log file name}
  end;
{
*   Unrecognized command line option.
}
otherwise
    writeln ('Command line option "', opt.str:opt.len, '" is unrecognized.');
    sys_bomb;
    end;                               {end of command line option case statement}

  if not sys_error(stat) then goto next_opt;

parm_bad:                              {jump here on got illegal parameter}
  writeln ('Bad parameter to command line option "', opt.str:opt.len, '".');
  sys_bomb;

done_opts:                             {done with all the command line options}
  if flog.len > 0 then begin           {log output file name provided ?}
    file_open_write_text (             {open the log output file}
      flog,                            {file name}
      '.txt',                          {file name suffix}
      conn_log,                        {returned connection to the log file}
      stat);                           {completion status}
    sys_error_abort (stat, '', '', nil, 0);
    logfile := true;                   {indicate to write to log file}
    end;

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
    wstr ('Key ');
    show_key (keys_p^[key]);
    rend_set.event_req_key_on^ (key, 99); {enabled events for this key}
    end;
  wline;
{
*   Enable events to test them.
}
  rend_set.event_req_close^ (true);
  rend_set.event_req_pnt^ (true);
  rend_set.event_req_rotate_on^ (1.0);
  rend_set.event_req_translate^ (true);
  rend_set.event_req_wiped_resize^ (true);
  rend_set.event_req_wiped_rect^ (true);
  rend_event_req_stdin_line (true);
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
  wstr ('Size ');
  wicoor (image_width, image_height);
  wstr (' aspect ');
  wfp_fixed (aspect, 3);
  wline;

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
    wline;                             {leave blank line to show the time gap}
    end;
  tlast := tev;                        {update time of last event for next time}

  case ev.ev_type of                   {which event is it ?}

rend_ev_none_k: begin
      wstr ('NONE');
      wline;
      end;

rend_ev_close_k: begin
      wstr ('CLOSE');
      wline;
      goto leave;
      end;

rend_ev_resize_k: begin
      wstr ('RESIZE');
      wline;
      goto redraw;
      end;

rend_ev_wiped_rect_k: begin
      wstr ('WIPED RECT');
      wstr (' buf '); wint (ev.wiped_rect.bufid);
      wstr (' coor '); wicoor (ev.wiped_rect.x, ev.wiped_rect.y);
      wstr (' size '); wicoor (ev.wiped_rect.dx, ev.wiped_rect.dy);
      wline;
      goto redraw;
      end;

rend_ev_wiped_resize_k: begin
      wstr ('WIPED RESIZE');
      wline;
      goto resize;
      end;

rend_ev_key_k: begin
      wstr ('KEY ');
      if ev.key.down
        then wstr ('down')
        else wstr ('up');
      wstr (' at '); wicoor (ev.key.x, ev.key.y);
      wstr (', ID '); show_key (ev.key.key_p^);
      end;

rend_ev_scrollv_k: begin
      wstr ('SCROLLV ');
      if ev.scrollv.n >= 0
        then begin
          wint (ev.scrollv.n);
          if ev.scrollv.n > 0 then begin
            wstr (' up');
            end;
          end
        else begin
          wint (-ev.scrollv.n);
          wstr (' down');
          end
        ;
      wline;
      end;

rend_ev_pnt_enter_k: begin
      wstr ('PNT ENTER at ');
      wicoor (ev.pnt_enter.x, ev.pnt_enter.y);
      wline;
      end;

rend_ev_pnt_exit_k: begin
      wstr ('PNT EXIT at ');
      wicoor (ev.pnt_exit.x, ev.pnt_exit.y);
      wline;
      end;

rend_ev_pnt_move_k: begin
      wstr ('PNT MOVE at ');
      wicoor (ev.pnt_move.x, ev.pnt_move.y);
      wline;
      end;

rend_ev_close_user_k: begin
      wstr ('CLOSE USER');
      wline;
      goto leave;
      end;

rend_ev_stdin_line_k: begin
      rend_get_stdin_line (s);
      wstr ('STDIN LINE "'); wvstr (s); wstr ('"');
      wline;
      end;

rend_ev_xf3d_k: begin
      wstr ('XF3D');
      wline;
      end;

    end;                               {end of event type cases}
  goto next_event;                     {back to get the next event}

leave:
  rend_end;
  if logfile then begin                {writing to log file ?}
    file_close (conn_log);             {close the log file}
    end;
  end.
