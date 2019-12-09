{   Subroutine REND_TEST_COMMENT_DRAW
*
*   Draw the user comments, if any exist.  The variables COMMENT_FONT,
*   COMMENT_BORDER_LEFT, COMMENT_BORDER_BOTTOM, COMMENT_TEXT_SIZE, and
*   COMMENT_TEXT_WIDE will effect the comment string configuration.
*
*   All the setup is done whether the comment string is set or not.
*   This allows the application to draw additional text lines with the same
*   formatting parameters.
}
module rend_test_comment_draw;
define rend_test_comment_draw;
%include 'rend_test2.ins.pas';

procedure rend_test_comment_draw;      {draw comment string, if exists}

var
  tparms: rend_text_parms_t;           {text control parameters}

begin
  rend_get.text_parms^ (tparms);       {set up text for drawing comment string}
  tparms.coor_level := rend_space_2d_k;
  tparms.size := comment_text_size;
  tparms.width := comment_text_wide;
  tparms.height := 1.0;
  tparms.slant := 0.0;
  tparms.rot := 0.0;
  tparms.lspace := 1.0;
  tparms.start_org := rend_torg_ll_k;
  tparms.end_org := rend_torg_up_k;
  tparms.vect_width := 0.12;
  string_copy (comment_font, tparms.font);
  tparms.poly := true;
  rend_set.text_parms^ (tparms);

  rend_set.cpnt_2d^ (                  {set lower left corner of text block}
    -width_2d + comment_border_left,   {X coordinate}
    -height_2d + comment_border_bottom); {Y coordinate}

  string_list_pos_last (comments);     {go to last comment line, if any}
  while comments.str_p <> nil do begin {once for each user comment line}
    rend_prim.text^ (comments.str_p^.str, comments.str_p^.len); {draw comment line}
    string_list_pos_rel (comments, -1); {go to previous comment line}
    end;
  end;
