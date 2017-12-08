#!/bin/bash

VERSION=`cat ../VERSION`
echo $"#define TCC_VERSION \"$VERSION\"" > ../config.h

PSTR="$(echo $MSYSTEM | cut -c 6-)"

cargs="-Iinclude/winapi -D__TCCFORK_ALIGN_WORK_AROUND"

if [ $PSTR = "64" ]; then
	target=$"-DTCC_TARGET_PE -DTCC_TARGET_X86_64 $cargs"
	CC="gcc -Os -s -fno-strict-aliasing -Wno-incompatible-pointer-types"
	P=64
fi
if [ $PSTR = "32" ]; then
	target=$"-DTCC_TARGET_PE -DTCC_TARGET_I386 $cargs"
	CC="gcc -Os -s -fno-strict-aliasing -Wno-incompatible-pointer-types"
	P=32
fi

#tools
eval "$CC $target tools/tiny_impdef.c -o tiny_impdef.exe"

eval "$CC $target tools/tiny_libmaker.c -o tiny_libmaker.exe"

#libtcc
mkdir -p libtcc
if [ ! -f "libtcc/libtcc.h" ]; then
	cp ../libtcc.h libtcc/libtcc.h
fi

eval "$CC $target -shared -DLIBTCC_AS_DLL -DONE_SOURCE ../libtcc.c -o libtcc.dll -Wl,-out-implib,libtcc/libtcc.a"

eval "./tiny_impdef libtcc.dll -o libtcc/libtcc.def"

#tcc
eval "$CC $target ../tcc.c -o tcc.exe -ltcc -Llibtcc"

#copy_std_includes
cp -r ../include/*.h include

#libtcc1.a
eval "./tcc $target -c ../lib/libtcc1.c"
eval "./tcc $target -c lib/crt1.c"
eval "./tcc $target -c lib/wincrt1.c"
eval "./tcc $target -c lib/dllcrt1.c"
eval "./tcc $target -c lib/dllmain.c"
eval "./tcc $target -c lib/chkstk.S"

if [ $PSTR = "32" ]; then
	eval "./tcc $target -c ../lib/alloca86.S"
	eval "./tcc $target -c ../lib/alloca86-bt.S"
	eval "./tcc $target -c ../lib/bcheck.c"
	eval "./tiny_libmaker lib/libtcc1.a libtcc1.o alloca86.o alloca86-bt.o crt1.o wincrt1.o dllcrt1.o dllmain.o chkstk.o bcheck.o"
fi

if [ $PSTR = "64" ]; then
	eval "./tcc $target -c ../lib/alloca86_64.S"
	eval "./tiny_libmaker lib/libtcc1.a libtcc1.o alloca86_64.o crt1.o wincrt1.o dllcrt1.o dllmain.o chkstk.o"
fi 

rm *.o
