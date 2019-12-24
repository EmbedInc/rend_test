@echo off
rem
rem   BUILD_PROGS [-dbg]
rem
rem   Build the executable programs from this source directory.
rem
setlocal
call build_pasinit

call src_prog %srcdir% test_2d %1
call src_prog %srcdir% test_2dim %1
call src_prog %srcdir% test_3d %1
call src_prog %srcdir% test_3dt %1
call src_prog %srcdir% test_aa %1
call src_prog %srcdir% test_alpha %1
call src_prog %srcdir% test_clip %1
call src_prog %srcdir% test_quad %1
call src_prog %srcdir% test_ray %1
call src_prog %srcdir% test_shade %1
call src_prog %srcdir% test_subpix %1
call src_prog %srcdir% test_text %1
call src_prog %srcdir% test_tmap %1

goto :eof

rem   These programs are not included for now because they have old Apollo OS
rem   dependencies.
rem
rem call src_prog %srcdir% test_3dv %1
rem call src_prog %srcdir% test_tube %1
rem call src_prog %srcdir% test_tubeseg %1

rem   This program tries to cheat and get at the internals of RENDlib.
rem
rem call src_prog %srcdir% test_tmap2 %1
