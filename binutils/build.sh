#!/bin/sh
set -eu

V=2.47
SHA256=154ab23b60070e8f27013c22977f1129425d67d1e8acd6e13010e617811e4cff
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1785024000}"

if [ $# -lt 1 ]; then
    echo "usage: $0 <platform> [--host=<triplet>]" >&2
    exit 2
fi
PLATFORM=$1
HOST=
case "${2:-}" in
    --host=*) HOST=${2#--host=} ;;
    "") ;;
    *) echo "unknown argument: $2" >&2; exit 2 ;;
esac
EXE=
case "$PLATFORM" in
    win-*) EXE=.exe ;;
esac
case "$PLATFORM" in
    mac-*) export MACOSX_DEPLOYMENT_TARGET=11.0 ;;
    *) export CC="${HOST:+$HOST-}gcc --static" ;;
esac

OUT=$PWD/bin-$PLATFORM
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
export CFLAGS="-g -O2 -ffile-prefix-map=$W=/binutils" CXXFLAGS="-g -O2 -ffile-prefix-map=$W=/binutils" ZERO_AR_DATE=1
cd "$W"
curl -fsSLO "https://sourceware.org/pub/binutils/releases/binutils-$V.tar.xz"
echo "$SHA256  binutils-$V.tar.xz" | shasum -a 256 -c -
tar xf "binutils-$V.tar.xz"
mkdir build
cd build
"../binutils-$V/configure" ${HOST:+--host="$HOST"} --target=i686-w64-mingw32 --prefix=/ \
    --disable-nls --disable-werror --disable-gas --disable-gdb --disable-gdbserver --disable-sim --disable-gprof \
    --disable-gprofng --disable-plugins --disable-multilib --disable-shared --enable-deterministic-archives \
    --without-zstd --without-msgpack --without-debuginfod
make -j"$(getconf _NPROCESSORS_ONLN)" MAKEINFO=true all-ld all-binutils

mkdir -p "$OUT"
cp "ld/ld-new$EXE" "$OUT/ld$EXE"
cp "binutils/windres$EXE" "$OUT/windres$EXE"
"${HOST:+$HOST-}strip" "$OUT/ld$EXE" "$OUT/windres$EXE"
cp "../binutils-$V/COPYING3" "$OUT/COPYING"
