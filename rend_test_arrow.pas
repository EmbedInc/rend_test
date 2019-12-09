{   Subroutine REND_TEST_ARROW (DX,DY,DZ,RAD_SHAFT,RAD_HEAD,LEN_HEAD,CAP_START)
*
*   Draw an arrow.  The arrow will be a cylender with a cone on the end.
*   DX,DY,DZ is the displacement of the arrow tip from the current point.  The
*   arrow starts at the current point.  RAD_SHAFT is the radius of the arrow
*   shaft.  RAD_HEAD is the outer radius of the arrow head cone.  LEN_HEAD is
*   the absolute length of the arrow head.  CAP_START indicates what type of cap
*   to use for the cylender end at the start of the arrow.
}
module rend_test_ARROW;
define rend_test_arrow;
%include 'rend_test2.ins.pas';

procedure rend_test_arrow (            {draw an arrow with conical head}
  in      dx, dy, dz: real;            {arrow displacement, starts at current point}
  in      rad_shaft: real;             {arrow shaft radius}
  in      rad_head: real;              {max radius of arrow head}
  in      len_head: real;              {length of arrow head}
  in      cap_start: rend_test_cap_k_t); {what kind of cap to put at arrow start}
  val_param;

var
  cpnt: vect_3d_t;                     {starting current point, arrow start coor}
  len_all: real;                       {length of whole arrow}
  len_cyl: real;                       {length of arrow cylender (shaft)}
  m: real;                             {scratch mult factor}
  v: vect_3d_t;                        {scratch vector}

begin
  rend_get.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {get arrow start coordinate}
  len_all := sqrt(sqr(dx) + sqr(dy) + sqr(dz)); {length of whole arrow}
  len_cyl := len_all - len_head;       {length of cylender to draw}

  m := len_cyl / len_all;              {mult factor for making cylender vector}
  v.x := dx * m;                       {vector along length of cylender}
  v.y := dy * m;
  v.z := dz * m;
  if len_cyl > 0.0 then begin          {there is enough shaft left to draw ?}
    rend_test_cyl (                    {draw arrow shaft as cylender}
      v.x, v.y, v.z,                   {cylender displacement vector}
      rad_shaft,                       {cylender radius}
      cap_start,                       {starting cap type}
      rend_test_cap_none_k);           {ending cap type}
    end;

  rend_set.cpnt_3d^ (                  {set current point to start of arrow head}
    cpnt.x + v.x,
    cpnt.y + v.y,
    cpnt.z + v.z);
  m := len_head / len_all;             {mult factor for making cone vector}
  v.x := dx * m;                       {make cone axis vector}
  v.y := dy * m;
  v.z := dz * m;
  rend_test_cone (v.x, v.y, v.z, rad_head); {draw arrow head cone}

  rend_set.cpnt_3d^ (cpnt.x, cpnt.y, cpnt.z); {restore current point}
  end;
