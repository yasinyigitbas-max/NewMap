#!/bin/bash
# Linux build of native/src (cloud session only): same flags as build.sh's targets, linux defines
set -e
N=/home/user/NewMap/native
G=/opt/native_tools/godot-cpp
O=/opt/native_tools/obj; mkdir -p $O $N/bin
INC="-I$G/gdextension -I$G/include -I$G/gen/include -I$N/src"
CF="-std=c++17 -fno-exceptions -fPIC -fvisibility=hidden -O2 -DLINUXBSD_ENABLED -DUNIX_ENABLED -DTHREADS_ENABLED -DHOT_RELOAD_ENABLED -DDEBUG_ENABLED -DNDEBUG -DGDEXTENSION -Wall -Wno-unused-parameter -Wno-unused-variable -ftrivial-auto-var-init=zero"
ls $N/src/*.cpp | xargs -P4 -I{} sh -c 'f={}; o='$O'/$(basename $f .cpp).o; if [ ! -f $o ] || [ $f -nt $o ] || [ -n "$FORCE" ]; then g++ '"$CF $INC"' -c $f -o $o 2>&1 | grep -E "error|Error" | head -5; fi'
g++ -shared -o $N/bin/libcoronado_city.linux.x86_64.so $O/*.o $G/bin/libgodot-cpp.linux.template_debug.x86_64.a -Wl,--no-undefined -lpthread
sed '/^\[libraries\]/a linux.debug.x86_64 = "res://native/bin/libcoronado_city.linux.x86_64.so"\nlinux.release.x86_64 = "res://native/bin/libcoronado_city.linux.x86_64.so"' $N/coronado_city.gdextension.in > $N/coronado_city.gdextension
ls -la $N/bin/
