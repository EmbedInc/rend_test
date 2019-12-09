{   Subroutine REND_TEST_VERT3D_INIT (VERT)
*
*   Initialize a 3D vertex descriptor to the conventions of the REND_TEST
*   library.  The coordinate, shading normal, and cache pointers will be filled
*   in to point to that information in the vertex descriptor.  The cache version
*   will be set to the current version - 1.
}
module rend_test_VERT3D_INIT;
define rend_test_vert3d_init;
%include 'rend_test2.ins.pas';

procedure rend_test_vert3d_init (      {initialize one of our 3D vertex descriptors}
  out     vert: rend_test_vert3d_t);   {vertex, will set pointers and version}

begin
  vert.coor_p := addr(vert.coor);
  vert.norm_p := addr(vert.norm);
  vert.vcache_p := addr(vert.vcache);
  vert.vcache.version := version_vcache - 1;
  end;
