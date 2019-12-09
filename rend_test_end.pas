{   Subroutine REND_TEST_END
*
*   The application routine is all done drawing.  Now exit RENDlib in the
*   appropriate way.  The may require writing the bitmap to an image file and/or
*   waiting for the user to hit an exit key.
}
module rend_test_end;
define rend_test_end;
%include 'rend_test2.ins.pas';

procedure rend_test_end;               {all done drawing, exit in standard way}

var
  stat: sys_err_t;

begin
  if img_on then begin                 {supposed to write final image ?}
    rend_test_image_write (stat);      {write bitmap to image file}
    sys_error_abort (stat, 'rend', 'rend_write_image', nil, 0);
    end;
  rend_set.enter_level^ (0);           {make sure we are out of graphics mode}

  if user_wait then begin              {wait for user to request to exit the program}
    rend_get.wait_exit^ ([rend_waitex_msg_k]);
    end;

  rend_end;                            {completely close down RENDlib}
  end;
