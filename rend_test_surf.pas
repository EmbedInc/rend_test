{   Subroutine REND_TEST_SURF (T1_MIN,T1_MAX,T1_SEG,T2_MIN,T2_MAX,T2_SEG,FUNC)
*
*   Draw the 3D surface produced by an arbitrary function of 2 variables.
*   T1_MIN and T1_MAX indicate the min and max values to use for the first
*   independent variable.  T1_SEG indicates the number of segments the
*   T1_MIN to T1_MAX interval will be divided up into.  T2_MIN, T2_MAX, and
*   T2_SEG are the same values for the second dependent variable.
*   FUNC is a pointer to the function that will return the surface coordinate
*   given the two independent variable values.
}
module rend_test_SURF;
define rend_test_surf;
%include 'rend_test2.ins.pas';

procedure rend_test_surf (             {draw surface that is function of 2 variables}
  in      t1_min, t1_max: real;        {range of first independent variable}
  in      t1_seg: sys_int_machine_t;   {number of segments to break T1 into}
  in      t2_min, t2_max: real;        {range of second independent variable}
  in      t2_seg: sys_int_machine_t;   {number of segments to break T2 into}
  in      func: rend_test_func2d_t);   {function to return surface coor at T1,T2}
  val_param;

var
  vert1, vert2, vert3, vert4:          {vertex descriptors of current patch}
    rend_test_vert3d_t;
  ul_p, ll_p, ur_p, lr_p:              {pointers to UL, LL, UR, and LR patch verts}
    rend_test_vert3d_p_t;
  gnorm: vect_3d_t;                    {geometric normal vector of curr patch}
  v1, v2: vect_3d_t;                   {scratch 3d vectors}
  p: univ_ptr;                         {used for flipping vertex pointers}
  t1, t2: real;                        {current independent parameter values}
  t2u: real;                           {T2 at top of current patch row}
  dt1, dt2: real;                      {T1 and T2 delta values for one patch}
  dt1n, dt2n: real;                    {T1,T2 deltas for evaluating normal vector}
  i, j: sys_int_machine_t;             {loop counters}

begin
  rend_test_vert3d_init (vert1);       {init vertex descriptors}
  rend_test_vert3d_init (vert2);
  rend_test_vert3d_init (vert3);
  rend_test_vert3d_init (vert4);

  ul_p := addr(vert1);                 {init upper/lower left/right vertex pointers}
  ur_p := addr(vert2);
  ll_p := addr(vert3);
  lr_p := addr(vert4);

  dt1 := (t1_max - t1_min) / t1_seg;   {make variable increments}
  dt2 := (t2_max - t2_min) / t2_seg;
  dt1n := dt1 * 0.01;
  dt2n := dt2 * 0.01;

  t2 := t2_min;                        {init to bottom row}
  for i := 1 to t2_seg do begin        {up the T2 = constant rows}
    t2u := t2 + dt2;                   {T2 at top of this row}
    t1 := t1_min;                      {init to left end of current row}
    rend_test_func2d_vert (t1, t2, dt1n, dt2n, func, ll_p^); {init patch left verticies}
    rend_test_func2d_vert (t1, t2u, dt1n, dt2n, func, ul_p^);

    for j := 1 to t1_seg do begin      {accross this row of patches}
      t1 := t1 + dt1;                  {make T1 at patch right edge}
      rend_test_func2d_vert (t1, t2, dt1n, dt2n, func, lr_p^); {make right verticies}
      rend_test_func2d_vert (t1, t2u, dt1n, dt2n, func, ur_p^);

      v1.x := ur_p^.coor.x - ll_p^.coor.x; {vectors for finding geometric normal}
      v1.y := ur_p^.coor.y - ll_p^.coor.y;
      v1.z := ur_p^.coor.z - ll_p^.coor.z;

      v2.x := ul_p^.coor.x - ll_p^.coor.x;
      v2.y := ul_p^.coor.y - ll_p^.coor.y;
      v2.z := ul_p^.coor.z - ll_p^.coor.z;

      gnorm.x := (v1.y * v2.z) - (v1.z * v2.y);
      gnorm.y := (v1.z * v2.x) - (v1.x * v2.z);
      gnorm.z := (v1.x * v2.y) - (v1.y * v2.x);
      rend_test_tri (ll_p^, ur_p^, ul_p^, gnorm); {draw upper left triangle}

      v2.x := lr_p^.coor.x - ll_p^.coor.x; {vector for finding geometric normal}
      v2.y := lr_p^.coor.y - ll_p^.coor.y;
      v2.z := lr_p^.coor.z - ll_p^.coor.z;

      gnorm.x := (v2.y * v1.z) - (v2.z * v1.y);
      gnorm.y := (v2.z * v1.x) - (v2.x * v1.z);
      gnorm.z := (v2.x * v1.y) - (v2.y * v1.x);
      rend_test_tri (ll_p^, lr_p^, ur_p^, gnorm); {lower right triangle}

      p := ul_p;                       {old left edge is now new right edge}
      ul_p := ur_p;
      ur_p := p;
      p := ll_p;
      ll_p := lr_p;
      lr_p := p;
      end;                             {back for next patch accross this row}

    t2 := t2u;                         {old top becomes new bottom}
    end;                               {back for next row up}
  end;
