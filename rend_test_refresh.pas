{   Function REND_TEST_REFRESH
*
*   This is a layered function for simple graphics programs that wait on
*   events at the end of the program to either exit or refresh the image.
*
*   RENDlib will be closed and FALSE returned on a CLOSE, CLOSE_USER, or
*   STDIN_LINE event.
*
*   TRUE will be returned on a RESIZE, WIPED_RESIZE, or WIPED_RECT event.
*   The REND_TEST library will already be updated to any new draw area
*   size.  The REND_TEST library master clip rectangle will be set
*   appropriately on a WIPED_RECT event.
}
module rend_test_refresh;
define rend_test_refresh;
%include 'rend_test2.ins.pas';

function rend_test_refresh             {wait on events, TRUE if refresh needed}
  :boolean;                            {TRUE for refresh, FALSE on RENDlib closed}

var
  event: rend_event_t;                 {RENDlib event descriptor}

label
  event_wait, done_prog;

begin
  rend_set.enter_level^ (0);           {make sure we are out of graphics mode}

  if not rend_get.close_corrupt^ then begin {closing device won't wipe out image ?}
    goto done_prog;                    {all done with program}
    end;

  rend_test_refresh := true;           {init to a refresh is needed}

event_wait:                            {back here to wait for another event}
  rend_event_get (event);              {get next RENDlib event}
  case event.ev_type of                {what kind of event is this ?}
{
*   We exit RENDlib on all these events.
}
rend_ev_stdin_line_k,                  {a line of standard input text is available}
rend_ev_close_k,                       {draw device was closed}
rend_ev_close_user_k: begin            {user aksed to close device}
  goto done_prog;
  end;
{
*   The draw area size has changed, and we can now redraw all the pixels.
}
rend_ev_resize_k,
rend_ev_wiped_resize_k: begin
  rend_set.enter_rend^;                {enter graphics mode}
  rend_test_resize;                    {update state to new draw area size}
  return;
  end;
{
*   A rectangular region of pixels was previously corrupted, and we are now
*   able to draw into them again.
}
rend_ev_wiped_rect_k: begin
  rend_set.enter_rend^;                {enter graphics mode}
  rend_test_clip_all (                 {set master clip rectangle to the region}
    event.wiped_rect.x, event.wiped_rect.y,
    event.wiped_rect.dx, event.wiped_rect.dy);
  return;
  end;
{
*   Not an event we care about.  All these events are just ignored.
}
    end;                               {end of event type cases}
  goto event_wait;                     {back and wait for another event}
{
*   All done with program.  Clean up and then return indicating no refresh
*   is needed.
}
done_prog:
  user_wait := false;                  {prevent REND_TEST_END from waiting}
  rend_test_end;                       {perform final cleanup and exit}
  rend_test_refresh := false;
  end;
