#!/bin/bash

# Script to run Coverity on mesa.

# https://scan.coverity.com/download
# https://scan.coverity.com/projects/mesa/builds/new

set -e
set -x

# Coverity token
token='abcedefghi'

# Set Coverity path
export PATH=$PATH:$HOME/Downloads/cov-analysis-linux64-8.5.0/bin

project='mesa'

# Clean everything.
me=`basename "$0"`
git clean -dfxq --exclude $me --exclude build.log

git pull

./autogen.sh \
--enable-debug \
--enable-dri \
--enable-dri3 \
--enable-egl \
--enable-gallium-tests \
--enable-gbm \
--enable-gles1 \
--enable-gles2 \
--enable-glx \
--enable-glx-tls \
--enable-nine \
--enable-omx \
--enable-opencl \
--enable-opencl-icd \
--enable-opengl \
--enable-r600-llvm-compiler \
--enable-selinux \
--enable-shader-cache \
--enable-sysfs \
--enable-texture-float \
--enable-va \
--enable-valgrind \
--enable-vdpau \
--enable-xa \
--enable-xvmc \
--with-egl-platforms=drm,wayland,x11 \
--with-dri-drivers=i915,i965,nouveau,r200,radeon,swrast \
--with-gallium-drivers=i915,ilo,nouveau,r300,r600,radeonsi,svga,swr,swrast,virgl \
--with-vulkan-drivers=intel

# configure option needed on Fedora
# --with-clang-libdir=/usr/lib

# Create build script.
cat > build.sh << EOL
#!/bin/bash
set -e
set -x
make
make -C src/gallium/drivers/vc4
make check
# freedreno doesn't fully build on Linux but we can build most of the source.
ln -sf ~/Downloads/libdrm-2.4.70/freedreno/freedreno_drmif.h src/gallium/drivers/freedreno/freedreno_drmif.h
if [ ! -e src/gallium/drivers/freedreno/freedreno_drmif.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.70/include/drm/drm.h src/gallium/drivers/freedreno/drm.h
if [ ! -e  src/gallium/drivers/freedreno/drm.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.70/include/drm/drm_mode.h src/gallium/drivers/freedreno/drm_mode.h
if [ ! -e src/gallium/drivers/freedreno/drm_mode.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.70/freedreno/freedreno_ringbuffer.h src/gallium/drivers/freedreno/freedreno_ringbuffer.h
if [ ! -e src/gallium/drivers/freedreno/freedreno_ringbuffer.h]; then
    exit 1
fi
make -C src/gallium/drivers/freedreno -i
scons -j 1 texture_float=yes
EOL

chmod u+x build.sh

# Run the Coverity Build tool.
cov-build --dir cov-int ./build.sh

# Create a compress tar archive of the results.
tar czvf $project.tgz cov-int

# Submit build.
curl --form token=$token \
  --form email=vlee@freedesktop.org \
  --form file=@$project.tgz \
  https://scan.coverity.com/builds?project=$project

echo "build passed"
