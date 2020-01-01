@echo off
rem
rem   BUILD_PROGS
rem
rem   Build the executable programs from this source directory.
rem
setlocal
call build_pasinit

call src_prog %srcdir% test_2d
call src_prog %srcdir% test_2dim
call src_prog %srcdir% test_3d
call src_prog %srcdir% test_3dt
call src_prog %srcdir% test_aa
call src_prog %srcdir% test_alpha
call src_prog %srcdir% test_clip
call src_prog %srcdir% test_events
call src_prog %srcdir% test_quad
call src_prog %srcdir% test_ray
call src_prog %srcdir% test_shade
call src_prog %srcdir% test_subpix
call src_prog %srcdir% test_text
call src_prog %srcdir% test_tmap

goto :eof

rem   These programs are not included for now because they have old Apollo OS
rem   dependencies.
rem
rem call src_prog %srcdir% test_3dv
rem call src_prog %srcdir% test_tube
rem call src_prog %srcdir% test_tubeseg

rem   This program tries to cheat and get at the internals of RENDlib.
rem
rem call src_prog %srcdir% test_tmap2
