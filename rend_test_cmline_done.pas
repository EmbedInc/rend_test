{   Subroutine REND_TEST_CMLINE_DONE
*
*   Abort with error if any unused command line tokens remain.  Unused command
*   line tokens are stored in the string list CMLINE.
}
module rend_test_CMLINE_DONE;
define rend_test_cmline_done;
%include 'rend_test2.ins.pas';

procedure rend_test_cmline_done;       {abort if unused command line tokens exist}

var
  msg_parm:                            {message parameter references}
    array[1..1] of sys_parm_msg_t;

begin
  if cmline.n <= 0 then return;        {no problem, CMLINE is empty ?}

  string_list_pos_abs (cmline, 1);     {position to first unused command line token}
  sys_msg_parm_vstr (msg_parm[1], cmline.str_p^);
  sys_message_bomb ('string', 'cmline_opt_bad', msg_parm, 1);
  end;
