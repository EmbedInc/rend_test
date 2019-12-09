@echo off
rem
rem   Define the variables for running builds from this source library.
rem
set srcdir=rend
set buildname=test
call treename_var "(cog)source/rend/test" sourcedir
set libname=rend_test
set fwname=
call treename_var "(cog)src/%srcdir%/debug_%fwname%.bat" tnam
make_debug "%tnam%"
call "%tnam%"
