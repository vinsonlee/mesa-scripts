#!/usr/bin/env python

"""
Python script to test software renderers.
"""

import commands
import datetime
import os
import platform
import sys
import time

# global variables
piglit_dir = '/home/vlee/piglit'
mesa_dir = '/home/vlee/mesa.test'
llvm_dir = '/home/vlee/llvm'
test_list = 'tests/quick.py'
run_once = True
# run_once = False

# drivers = ('llvmpipe', 'softpipe')
# drivers = ('swrast',)
# drivers = ('softpipe',)
# drivers = ('vmwgfx',)
# drivers = ('llvmpipe',)
# drivers = ('llvmpipe', 'swrast')
drivers = ('llvmpipe', 'softpipe', 'swrast')

if __name__ == "__main__":
    force = False

    if '-f' in sys.argv or '--force' in sys.argv:
        force = True

    while True:
        # If there are changes in the Mesa tree, then test.
        (status, output) = commands.getstatusoutput(
            'cd %s && git pull' % mesa_dir)

        if status != 0:
            print '%s git pull failed' % mesa_dir
            time.sleep(300)
            continue

        (status, commit) = commands.getstatusoutput(
            'cd %s && git rev-parse --short HEAD'
            % mesa_dir)

        if status != 0:
            print 'git-log failed'
            sys.exit(1)

        if output == 'Already up-to-date.' and not force:
            print 'up-do-date with commit %s' % commit
            time.sleep(300)
            continue

        # Then there must have been some changes. Do some testing.
        force = False

        # build piglit
        print 'Building piglit'
        status = os.system("cd %s && git pull && cmake . && make > make.log 2>&1" % piglit_dir)
        # status = 0
        if status != 0:
            print 'piglit build failed'
            sys.exit(0)

        # build LLVM
        if 'llvmpipe' in drivers or 'vmwgfx' in drivers:
            print 'Building LLVM'
            # command = "cd %s && git pull && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON ../ && make > make.log 2>&1" % llvm_dir
            command = "cd %s/build && git pull && make > make.log 2>&1" % llvm_dir
            status = os.system(command)
            if (status != 0):
                print 'LLVM build failed'
                sys.exit(0)

        # Build and test Mesa
        print 'Testing commit %s' % (commit)

        # Make build
        # Must do a clean build because incremental build sometimes
        # gives bad results.
        if 'swrast' in drivers or 'softpipe' in drivers:
            print 'make build'
            os.system('cd %s && make clean' % mesa_dir)
            os.system('cd %s && ./autogen.sh --with-dri-drivers=swrast --with-gallium-drivers=swrast --enable-debug --enable-gallium-llvm=no --enable-texture-float' % mesa_dir)
            status = os.system("cd %s && make > make.log 2>&1" % mesa_dir)
            if (status != 0):
                print "make failed"
                continue

        # SCons build.
        if 'llvmpipe' in drivers or 'vmwgfx' in drivers:
            print 'SCons build'
            llvm_path = '%s/build/bin' % llvm_dir
            status = os.system("cd %s && PATH=%s:$PATH python2 /usr/bin/scons texture_float=yes > scons.log 2>&1" % (mesa_dir, llvm_path))
            if (status != 0):
                print 'SCons build failed'
                continue

        _time = datetime.datetime.today().strftime('%Y%m%d-%H%M')
        output_dir = '%s-%s' % (_time, commit)

        for driver in drivers:
            # run tests
            assert platform.machine() == 'x86_64'
            if driver == 'swrast':
                ld_library_path = '%s/lib' % mesa_dir
                libgl_drivers_path = '%s/lib' % mesa_dir
            elif driver == 'softpipe':
                ld_library_path = '%s/lib' % mesa_dir
                libgl_drivers_path = '%s/lib/gallium' % mesa_dir
            elif driver == 'llvmpipe':
                ld_library_path = '%s/build/linux-x86_64-debug/gallium/targets/libgl-xlib' % mesa_dir
                libgl_drivers_path = ld_library_path
            elif driver == 'vmwgfx':
                ld_library_path = '%s/build/linux-x86_64-debug/gallium/targets/dri' % mesa_dir
                libgl_drivers_path = ld_library_path
            else:
                assert False

            env_vars = 'LD_LIBRARY_PATH=%s LIBGL_DRIVERS_PATH=%s' % (ld_library_path, libgl_drivers_path)
            if driver in ('swrast', 'softpipe'):
                env_vars += " LIBGL_ALWAYS_SOFTWARE=true"

            # Run tests.
            # os.system("cd %s && LD_LIBRARY_PATH=%s LIBGL_DRIVERS_PATH=%s ./piglit-run.py %s results/%s/%s"
            #           % (piglit_dir,
            #              ld_library_path,
            #              libgl_drivers_path,
            #              test_list,
            #              driver, output_dir))
            os.system("cd %s && %s ./piglit-run.py %s results/%s/%s"
                      % (piglit_dir,
                         env_vars,
                         test_list,
                         driver, output_dir))

            # Generate webpage.
            results = os.listdir(os.path.join(piglit_dir, 'results', driver))
            results.sort()
            # Last result should be the one just generated.
            assert results[-1] == output_dir
            # Only use the last 10 results.
            results = results[-10:]
            results_list = ' '.join(['results/%s/%s' % (driver, result) for result in results])
            os.system("cd %s && ./piglit-summary-html.py summary/%s/%s %s"
                      % (piglit_dir, driver, output_dir, results_list))

        if run_once:
            sys.exit(0)

    assert False
