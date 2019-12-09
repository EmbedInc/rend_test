{   Module of routines that deal with clipping in the RENDlib test library.
}
module rend_test_clip;
define rend_test_clip;
define rend_test_clip_all;
define rend_test_clip_all_off;
%include 'rend_test2.ins.pas';
{
****************************************
*
*   Subroutine REND_TEST_CLIP (X, Y, DX, DY)
*
*   Set new current 2DIM clip rectangle.  The requested clip rectangle is
*   clipped against the master clip rectangle.
}
procedure rend_test_clip (             {set current clip rect, merged with master}
  in      x, y: real;                  {top left corner of 2DIM clip rectangle}
  in      dx, dy: real);               {size of clip rectangle}
  val_param;

var
  xl, xr: real;                        {left/right final clip limits}
  yt, yb: real;                        {top/bottom final clip limits}

begin
  xl := max(x, clip_master.x1);
  xr := min(x + dx, clip_master.x2);
  yt := max(y, clip_master.y1);
  yb := min(y + dy, clip_master.y2);
  if (xl >= xr) or (yt >= yb)
    then begin                         {clip region is completely collapsed}
      rend_set.clip_2dim^ (
        rend_test_clip_handle,
        0.0, 0.0, 0.0, 0.0,
        true);                         {draw inside, clip outside}
      end
    else begin                         {a drawable region is still left}
      rend_set.clip_2dim^ (
        rend_test_clip_handle,
        xl, xr, yt, yb,
        true);                         {draw inside, clip outside}
      end
    ;
  end;
{
****************************************
*
*   Subroutine REND_TEST_CLIP_ALL (X, Y, DX, DY)
*
*   Set the RENDlib test library master clip rectangle.  This is intended to
*   be useful together with WIPED_RECT events.  Any clip windows set with
*   REND_TEST_CLIP are clipped to this master rectangle before being sent
*   to RENDlib.
}
procedure rend_test_clip_all (         {set master clip rectangle and enable}
  in      x, y: real;                  {top left corner of 2DIM clip rectangle}
  in      dx, dy: real);               {size of clip rectangle}
  val_param;

begin
  clip_master.x1 := max(0.0, x);
  clip_master.x2 := min(image_width, x + dx);
  clip_master.y1 := max(0.0, y);
  clip_master.y2 := min(image_height, y + dy);

  rend_set.clip_2dim^ (                {set RENDlib clip rect to new master clip}
    rend_test_clip_handle,
    clip_master.x1, clip_master.x2,
    clip_master.y1, clip_master.y2,
    true);                             {draw inside, clip outside}
  end;
{
****************************************
*
*   Subroutine REND_TEST_CLIP_ALL_OFF
*
*   Disables the master clip rectangle by setting it to the full image size.
}
procedure rend_test_clip_all_off;      {disable master clip rectangle}
  val_param;

begin
  clip_master.x1 := 0.0;
  clip_master.x2 := image_width;
  clip_master.y1 := 0.0;
  clip_master.y2 := image_height;

  rend_set.clip_2dim_on^ (rend_test_clip_handle, false); {turn off clip window}
  end;
