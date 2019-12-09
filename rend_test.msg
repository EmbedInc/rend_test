/*   Message file for RENDlib test programs and the REND_TEST library.
/*
msg command_bad
  lan english -def
    Command "%p1s" is illegal.
msg endcap_bad
  lan english -def
    The string "%p1s" is not a valid end cap style keyword.
msg err_at_line
  lan english -def
    Error encountered on line %p1i of file %p2s.
msg err_at_line_from
  lan english -def
    Called from line %p1i of file %p2s.
msg err_eof
  lan english -def
    Unexpected end of file encountered.
msg extra_on_line
  lan english -def
    Too many parameters found on this line.
msg fnam_redundant
  lan english -def
    The input file name was explicitly specified by command line option
    "%p1s" after it was already set to "%p2s".
msg infile_nest_too_deep
  lan english -def
    Input file nesting level exceeded.
msg no_images
  lan english -def
    No images provided.
msg no_pixels_anim
  lan english -def
    No pixels in animation.
msg no_view
  lan english -def
    Unable to create transformation matrix from supplied view parameters.
msg not_8_bits/pixel
  lan english -def
    Graphics device does not have exactly 8 bits/pixel.
msg not_x_window
  lan english -def
    Graphics device is not an X window.
msg parm_err
  lan english -def
    Error on attempt to get or interpret parameter to command line
    option "%p1s".
msg parm_missing
  lan english -def
    Missing parameter.
msg ray_bounds
  lan english -def
    .nfill
    3D world space bounding box used for ray tracing:
      X: %p1f8.3 %p2f8.3
      Y: %p3f8.3 %p4f8.3
      Z: %p5f8.3 %p6f8.3
msg tmap_imfile_npower2
  lan english -def
    Texture map image file is not power of two pixels wide.  Image
    file size is %p1i x %p2i.
msg tmap_imfile_ntall
  lan english -def
    Texture map image file is not tall enough.  Texture map image files
    must be at least 1 1/2 times taller than wide.  Image file size
    is %p1i x %p2i.
msg too_many_frames
  lan english -def
    Too many frames in animation.  %p1 were found, but only %p2 can be
    handled.
msg too_many_tokens
  lan english -def
    Too many tokens found.
msg vert_info_select_bad
  lan english -def
    Illegal per-vertex information selector.
msg vert_n_bad
  lan english -def
    Illegal number of verticies specified.
msg vert_typeselect_order_bad
  lan english -def
    Per-vertex data selector out of order.
msg vert_shnorm_too_small
  lan english -def
    Shading normal too small for vertex %p1i.
/*
/*   Program GEO
/*
msg geodraw_stats
  lan english -def
    .nfill
    Draw Time =%p1f8.1 Sec, =%p8f8.2 Min, =%p9f8.2 / Hour
    X Range     %p2f9.2 %p3f9.2
    Y Range     %p4f9.2 %p5f9.2
    Z Range     %p6f9.2 %p7f9.2
/*
/*   Program NFF
/*
msg nff_times1
  lan english -def
    .nfill
    Task                    Real Seconds
    ------------------------------------
    Gather Scene Info             %p1f6.1
    Render Scene                  %p2f6.1
    Filter Image                  %p6f6.1
    Read, Draw, Filter Benchmark  %p7f6.1
    Other Program Overhead        %p3f6.1
    TOTAL                         %p4f6.1
msg nff_times2
  lan english -def
    .nfill
    Task                    Real Seconds
    ------------------------------------
    Gather Scene Info             %p1f6.1
    Read In and Store Primitives  %p5f6.1
    Render Scene                  %p2f6.1
    Filter Image                  %p6f6.1
    Read, Draw, Filter Benchmark  %p7f6.1
    Other Program Overhead        %p3f6.1
    TOTAL                         %p4f6.1
/*
/*   Program XANIM
/*
msg xanim_times
  lan english -def
    .nfill
    Color model:       %p8s
    Zoomed frame size: %p1ix%p2i pixels
    Zoom factor:       %p7f7.0
    Create frames:     %p3f9.1  mS/frame
    Ave vectors/frame: %p4f7.0
    Animate frames:    %p5f9.1  mS/frame
    Animation rate:    %p6f9.1  Hertz
msg xanim_vectfile_open
  lan english -def
    Error on attempt to open vector overlay file with generic name "%p1s".
msg xanim_vectfile_read
  lan english -def
    Error occurred on attempt to read from vector overlay file.
msg xanim_pc_overflow
  lan english -def
    Pseudo color table overflow.
/*
/*   Program AATEST
/*
msg aatest_filt_bad
  lan english -def
    Unrecognized filtering method name "%p1s".
msg aatest_filt_parm_err
  lan english -def
    Error encountered while trying to get the command line parameters
    for the filtering method.
msg aatest_filt2
  lan english -def
    Multiple -FILT command line options encountered.
msg aatest_samp_bad
  lan english -def
    Unrecognized sampling method name "%p1s".
msg aatest_samp_parm_err
  lan english -def
    Error encountered while trying to get the command line parameters
    for the sampling method.
msg aatest_samp2
  lan english -def
    Multiple -SAMP command line options encountered.
msg aatest_scene_bad
  lan english -def
    Unrecognized scene name "%p1s".
msg aatest_scene2
  lan english -def
    Multiple -SCENE command line options encountered.
