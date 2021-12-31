#!/bin/sh
set -eu #x
die(){ ev=$1; shift; for msg in "$@"; do echo "${msg}"; done; exit "${ev}"; }
prefix=${HOME}/local
make=make
test -x Configure || die 1 "ERROR: Wrong directory, 'cd' to the project root first."
mkdir -p build
cd build
if [ ! -f config.h ]; then
    ../Configure -Dmksymlinks -de -Dprefix="${prefix}"
fi
if [ ! -f "${prefix}/bin/perl" -o ! -f x2p/a2p ]; then
    ${make}
    ${make} test
    ${make} install
fi
echo "all done for ${0##*/}"
