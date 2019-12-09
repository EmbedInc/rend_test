{   Function REND_TEST_TRI_READING_SW
*
*   Returns TRUE if the REND_TEST_TRI primitive would perform a read-modify-write
*   operation to the software bitmap under the current conditions.
}
module rend_test_tri_reading_sw;
define rend_test_tri_reading_sw;
%include 'rend_test2.ins.pas';

function rend_test_tri_reading_sw      {TRUE if REND_TEST_TRI will read SW bitmap}
  :boolean;
  val_param;

var
  reading: boolean;

begin
  if wire_on
    then begin                         {REND_TEST_TRI will draw outline vectors}
      rend_get.reading_sw_prim^ (rend_prim.vect_3d, reading);
      end
    else begin                         {REND_TEST_TRI will draw solid triangle}
      rend_get.reading_sw_prim^ (rend_prim.tri_3d, reading);
      end
    ;
  rend_test_tri_reading_sw := reading; {pass back result}
  end;
