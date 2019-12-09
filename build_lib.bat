@echo off
rem
rem   BUILD_LIB [-dbg]
rem
rem   Build the REND_TEST library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_arrow
call src_pas %srcdir% %libname%_bitmaps
call src_pas %srcdir% %libname%_box
call src_pas %srcdir% %libname%_cap
call src_pas %srcdir% %libname%_cap_rad
call src_pas %srcdir% %libname%_clip
call src_pas %srcdir% %libname%_cmline
call src_pas %srcdir% %libname%_cmline_done
call src_pas %srcdir% %libname%_colors_wire
call src_pas %srcdir% %libname%_comblock.
call src_pas %srcdir% %libname%_comblock
call src_pas %srcdir% %libname%_comment_draw
call src_pas %srcdir% %libname%_cone
call src_pas %srcdir% %libname%_cyl
call src_pas %srcdir% %libname%_draw_2d
call src_pas %srcdir% %libname%_end
call src_pas %srcdir% %libname%_func2d_vert
call src_pas %srcdir% %libname%_graphics_init
call src_pas %srcdir% %libname%_image_write
call src_pas %srcdir% %libname%_perp_left
call src_pas %srcdir% %libname%_perp_right
call src_pas %srcdir% %libname%_recompute_aa
call src_pas %srcdir% %libname%_refresh
call src_pas %srcdir% %libname%_sphere
call src_pas %srcdir% %libname%_surf
call src_pas %srcdir% %libname%_tmap_read
call src_pas %srcdir% %libname%_tri
call src_pas %srcdir% %libname%_tri_reading_sw
call src_pas %srcdir% %libname%_vert3d_init
call src_pas %srcdir% %libname%_xf3d
call src_pas %srcdir% %libname%_xform2d

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
