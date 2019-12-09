{   Subroutine REND_TEST_FUNC2D_VERT (T1,T2,DT1,DT2,FUNC,VERT)
*
*   Fill in the vertex descriptor for a surface that is function of two variables.
*   T1 and T2 are the independent variable values at the point we are to fill
*   in.  DT1 and DT2 are the T1 and T2 deltas to use to make
*   the two surface vectors that will be used to find the normal vector.
*   FUNC is a pointer to the function that will find the surface coordinate
*   at T1 and T2 values.
*
*   The function coordinate is stuffed into the COOR field of VERT.
*   The normal vector is stuffed into the vertex descriptor VERT as
*   the shading normal.  If the normal can't be found, then the NORM_P field
*   is set to NIL.  Otherwise, NORM_P will point to the NORM field, which will
*   set set to the shading normal vector.  The cache version is set to invalid.
}
module rend_test_FUNC2D_VERT;
define rend_test_func2d_vert;
%include 'rend_test2.ins.pas';

procedure rend_test_func2d_vert (      {fill in vertex at arbitraty function point}
  in      t1, t2: real;                {independent variables at this point}
  in      dt1, dt2: real;              {size of T1 and T2 deltas for surface vectors}
  in      func: rend_test_func2d_t;    {function to return surface coor at T1,T2}
  out     vert: rend_test_vert3d_t);   {3D vertex descriptor to fill in}
  val_param;

var
  v1, v2: vect_3d_fp1_t;               {the two surface tangent vectors}
  m: real;                             {scratch mult factor}

begin
  vert.coor := func^ (t1, t2);         {get surface point where we want normal}

  v1 := func^ (t1 + dt1, t2);          {make first surface tangent vector}
  v1.x := v1.x - vert.coor.x;
  v1.y := v1.y - vert.coor.y;
  v1.z := v1.z - vert.coor.z;

  v2 := func^ (t1, t2 + dt2);          {make second surface tangent vector}
  v2.x := v2.x - vert.coor.x;
  v2.y := v2.y - vert.coor.y;
  v2.z := v2.z - vert.coor.z;

  vert.norm.x := (v1.y * v2.z) - (v1.z * v2.y);
  vert.norm.y := (v1.z * v2.x) - (v1.x * v2.z);
  vert.norm.z := (v1.x * v2.y) - (v1.y * v2.x);
  m := sqr(vert.norm.x) + sqr(vert.norm.y) + sqr(vert.norm.z);
  if m > 1.0E-30
    then begin                         {normal vector is big enough}
(*
      m := 1.0 / sqrt(m);              {unitizing mult factor}
      vert.norm.x := vert.norm.x * m;
      vert.norm.y := vert.norm.y * m;
      vert.norm.z := vert.norm.z * m;
*)
      vert.norm_p := addr(vert.norm);
      end
    else begin                         {normal vector is too small to use}
      vert.norm_p := nil;
      end
    ;
  vert.vcache.version := rend_cache_version_invalid;
  end;
