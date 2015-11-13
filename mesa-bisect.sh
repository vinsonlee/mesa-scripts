#!/bin/bash

MESA_DIR=$HOME/workspace/mesa.bisect
PIGLIT_DIR=$HOME/workspace/piglit

# Build with make
# swrast and softpipe
# git clean -dfxq src
# git clean -dfxq lib
# ./autogen.sh --enable-debug --enable-texture-float --with-dri-drivers=swrast --with-gallium-drivers=swrast --enable-gallium-llvm=no
# make || exit 125

# Build with scons
git clean -dfxq src
git clean -dfxq build
scons texture_float=yes || exit 125

# swrast
# export LD_LIBRARY_PATH=$MESA_DIR/lib
# export LIBGL_DRIVERS_PATH=$MESA_DIR/lib
# export LIBGL_ALWAYS_SOFTWARE=1

# softpipe
# export LD_LIBRARY_PATH=$MESA_DIR/lib
# export LIBGL_DRIVERS_PATH=$MESA_DIR/lib/gallium
# export LIBGL_ALWAYS_SOFTWARE=1

# llvmpipe
export LD_LIBRARY_PATH=$MESA_DIR/build/linux-x86_64-debug/gallium/targets/libgl-xlib
export LIBGL_DRIVERS_PATH=$MESA_DIR/build/linux-x86_64-debug/gallium/targets/libgl-xlib

# make check
# glxinfo
# $PIGLIT_DIR/bin/varying-packing-simple dmat2x3 array -auto
$PIGLIT_DIR/bin/shader_runner $PIGLIT_DIR/tests/spec/arb_gpu_shader_fp64/execution/built-in-functions/fs-ldexp-dvec4.shader_test -auto

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
