#!/bin/bash

# Script to run Coverity on piglit.
# https://scan.coverity.com/download
# https://scan.coverity.com/projects/piglit/builds/new

set -e
set -x

# Coverity token
token='abcedefghi'

# Set Coverity path
export PATH=$PATH:$HOME/Downloads/cov-analysis-linux64-7.7.0.4/bin

project='piglit'

# Clean everything.
me=`basename "$0"`
git clean -dfxq --exclude $me --exclude build.log

git pull

cmake -DPIGLIT_BUILD_CL_TESTS=1

# Run the Coverity Build tool.
cov-build --dir cov-int make

# Create a compress tar archive of the results.
tar czvf $project.tgz cov-int

# Submit build.
curl --form token=$token \
  --form email=vlee@freedesktop.org \
  --form file=@piglit.tgz \
  https://scan.coverity.com/builds?project=$project

echo "build passed"
