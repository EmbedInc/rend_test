{   Subroutine REND_TEST_COLORS_WIRE
*
*   Set the RGB colors suitably for wire frame rendering.  Red, green, and blue
*   will be set to flat, and the values will be their diffuse color.
*   Nothing is done unless wire frame drawing is enabled.
}
module rend_test_COLORS_WIRE;
define rend_test_colors_wire;
%include 'rend_test2.ins.pas';

procedure rend_test_colors_wire;       {set RGB from diffuse color for wire frame}

var
  diff: rend_suprop_val_t;             {RENDlib diffuse surface property}
  diff_on: boolean;                    {TRUE if diffuse enabled}

begin
  if wire_on then begin                {will be drawing in wire frame ?}
    rend_get.suprop^ (rend_suprop_diff_k, diff_on, diff); {get current diffuse prop}
    if diff_on
      then begin                       {diffuse colors valid}
        rend_set.rgb^ (diff.diff_red, diff.diff_grn, diff.diff_blu);
        end
      else begin                       {diffuse colors are not valid}
        rend_set.rgb^ (0.0, 0.0, 0.0);
        end
      ;
    end;
  end;
