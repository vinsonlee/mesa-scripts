#!/bin/bash

# Build with make
# swrast and softpipe
make clean
git clean -dfx src
./autogen.sh --enable-debug --enable-texture-float --with-dri-drivers=swrast --with-gallium-drivers=swrast --enable-gallium-llvm=no --disable-xvmc --disable-dri3
make || exit 125

# Build with scons
# git clean -dfx src
# rm -rf build/linux-x86_64-debug/glsl
# scons llvm=0 || exit 125

# swrast
# export LD_LIBRARY_PATH=$HOME/mesa.bisect/lib
# export LIBGL_DRIVERS_PATH=$HOME/mesa.bisect/lib
# export LIBGL_ALWAYS_SOFTWARE=1

# softpipe
export LD_LIBRARY_PATH=$HOME/mesa.bisect/lib
export LIBGL_DRIVERS_PATH=$HOME/mesa.bisect/lib/gallium

# llvmpipe
# export LD_LIBRARY_PATH=$HOME/mesa.bisect/build/linux-x86_64-debug/gallium/targets/libgl-xlib
# export LIBGL_DRIVERS_PATH=$HOME/mesa.bisect/build/linux-x86_64-debug/gallium/targets/libgl-xlib

# make check
# glxinfo
# glxinfo | grep 8.0-devel
# glxinfo | grep GL_EXT_texture_compression_s3tc
# $HOME/piglit/bin/glean -t depthStencil --quick | grep PASS
# $HOME/piglit/bin/glsl-arb-fragment-coord-conventions -auto
# $HOME/piglit/bin/arb_multisample-pushpop -auto
# $HOME/piglit/bin/fbo-blit-stretch -auto
# $HOME/piglit/bin/glsl-uniform-out-of-bounds-2 -auto
# $HOME/piglit/bin/depthstencil-render-miplevels 1024 s=z24_s8 -auto
# $HOME/piglit/bin/getteximage-formats -auto
# $HOME/piglit/bin/ext_texture_integer-api-teximage -auto
# $HOME/piglit/bin/fbo-alphatest-formats -auto
# $HOME/piglit/bin/fbo-blending-formats -auto
# $HOME/piglit/bin/fbo-luminance-alpha -auto
# $HOME/piglit/bin/texelFetch fs isampler1D -auto -fbo
# $HOME/piglit/bin/fbo-generatemipmap-array -auto
# $HOME/piglit/bin/mipmap-setup -auto
# $HOME/piglit/bin/texelFetch offset fs isampler2DArray -auto
# $HOME/piglit/bin/ext_framebuffer_multisample-negative-copypixels -auto
# $HOME/piglit/bin/shader_runner $HOME/piglit/tests/shaders/glsl-mat-from-int-ctor-03.shader_test -auto
# $HOME/piglit/bin/shader_runner $HOME/piglit/tests/spec/glsl-1.30/execution/vs-attrib-ivec4-implied.shader_test -auto
# $HOME/piglit/bin/shader_runner $HOME/piglit/tests/shaders/glsl-const-folding-01.shader_test -auto
# $HOME/piglit/bin/shader_runner $HOME/piglit/tests/spec/glsl-1.30/execution/clipping/fs-clip-distance-interpolated.shader_test -auto
# $HOME/piglit/bin/shader_runner $HOME/piglit/generated_tests/spec/glsl-1.30/execution/interpolation/interpolation-noperspective-gl_BackColor-flat-distance.shader_test -auto
# glxinfo | grep '3.0 Mesa 8.1'
# $HOME/piglit/bin/glslparsertest $HOME/piglit/tests/spec/glsl-1.30/preprocessor/if/if-arg-must-be-defined-01.frag fail 1.30
# $HOME/piglit/bin/timer_query -auto
# $HOME/piglit/bin/get-renderbuffer-internalformat GL_EXT_texture_snorm -auto
# $HOME/piglit/bin/arb_uniform_buffer_object-getintegeri_v -auto
# $HOME/piglit/bin/fbo-clear-formats GL_ARB_depth_buffer_float stencil -auto
# $HOME/mesa.bisect/build/linux-x86_64-debug/glsl/builtin_compiler/builtin_compiler comment.vert
# ./src/glsl/builtin_compiler/builtin_compiler comment.vert
# $HOME/piglit/bin/gl-1.0-edgeflag -auto
# $HOME/piglit/bin/arb_debug_output-api_error -auto
$HOME/piglit/bin/shader_runner $HOME/piglit/tests/spec/glsl-1.50/execution/geometry/generate-zero-primitives.shader_test -auto 


status=$?

# segfault
if [[ $status == 134 ]]; then
    status=34
fi

# assert
if [[ $status == 133 ]]; then
    status=33
fi

if [[ $status > 128 ]]; then
    status=8
fi

exit $status
