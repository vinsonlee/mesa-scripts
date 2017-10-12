#!/bin/bash

# Script to run Coverity on mesa.

# https://scan.coverity.com/download
# https://scan.coverity.com/projects/mesa/builds/new

set -e
set -x

# Coverity token
token='abcedefghi'

# Set Coverity path
export PATH=$PATH:$HOME/Downloads/cov-analysis-linux64-2017.07/bin

cov-configure --comptype gcc --compiler cc --template
cov-configure --comptype g++ --compiler c++ --template

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
--enable-libunwind \
--enable-nine \
--enable-omx-bellagio \
--enable-opencl \
--enable-opencl-icd \
--enable-opengl \
--enable-selinux \
--enable-texture-float \
--enable-va \
--enable-valgrind \
--enable-vdpau \
--enable-xa \
--enable-xvmc \
--with-dri-drivers=i915,i965,nouveau,r200,radeon,swrast \
--with-gallium-drivers=i915,nouveau,r300,r600,radeonsi,svga,swr,swrast,virgl,vc4 \
--with-platforms=drm,surfaceless,wayland,x11 \
--with-swr-archs=avx,avx2,knl,skx \
--with-vulkan-drivers=intel,radeon

# configure option needed on Fedora
# --with-clang-libdir=/usr/lib

# Create build script.
cat > build.sh << EOL
#!/bin/bash
set -e
set -x
make
make check

make -C src/gallium/drivers/vc5

# freedreno doesn't fully build on Linux but we can build most of the source.
ln -sf ~/Downloads/libdrm-2.4.82/freedreno/freedreno_drmif.h src/gallium/drivers/freedreno/freedreno_drmif.h
if [ ! -e src/gallium/drivers/freedreno/freedreno_drmif.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.82/include/drm/drm.h src/gallium/drivers/freedreno/drm.h
if [ ! -e  src/gallium/drivers/freedreno/drm.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.82/include/drm/drm_mode.h src/gallium/drivers/freedreno/drm_mode.h
if [ ! -e src/gallium/drivers/freedreno/drm_mode.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.82/freedreno/freedreno_ringbuffer.h src/gallium/drivers/freedreno/freedreno_ringbuffer.h
if [ ! -e src/gallium/drivers/freedreno/freedreno_ringbuffer.h ]; then
    exit 1
fi
make -C src/gallium/drivers/freedreno -i
# Build as much of etnaviv.
ln -sf ~/Downloads/libdrm-2.4.82/etnaviv/etnaviv_drmif.h src/gallium/drivers/etnaviv/etnaviv_drmif.h
if [ ! -e src/gallium/drivers/etnaviv/etnaviv_drmif.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.82/include/drm/drm.h src/gallium/drivers/etnaviv/drm.h
if [ ! -e  src/gallium/drivers/etnaviv/drm.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.82/include/drm/drm_mode.h src/gallium/drivers/etnaviv/drm_mode.h
if [ ! -e src/gallium/drivers/etnaviv/drm_mode.h ]; then
    exit 1
fi
ln -sf ~/Downloads/libdrm-2.4.82/include/drm/drm_fourcc.h src/gallium/drivers/etnaviv/drm_fourcc.h
if [ ! -e src/gallium/drivers/etnaviv/drm_fourcc.h ]; then
    exit 1
fi
make -C src/gallium/drivers/etnaviv -i
scons -j 1 texture_float=yes
EOL

chmod u+x build.sh

# Run the Coverity Build tool.
cov-build --dir cov-int ./build.sh

# Create a compress tar archive of the results.
tar czvf $project.tgz cov-int

# Submit build.
VERSION=`cat VERSION`
curl --form token=$token \
  --form email=vlee@freedesktop.org \
  --form file=@$project.tgz \
  --form version="$VERSION" \
  https://scan.coverity.com/builds?project=$project

echo "build passed"
