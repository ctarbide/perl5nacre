#!/bin/sh
set -eu #x
die(){ ev=$1; shift; for msg; do echo "${msg}"; done; exit "${ev}"; }
prefix=${HOME}/local
make=${MAKE:-make}
test -x Configure || die 1 "ERROR: Wrong directory, 'cd' to the project root first."
mkdir -p build
cd build
if [ ! -f config.h ]; then
    ../Configure -des -Dmksymlinks \
        -Dprefix="${prefix}" \
        -Dcc=gcc
fi
if [ ! -f "${prefix}/bin/perl" -o ! -f x2p/a2p ]; then
    ${make} all 2>&1 | tee ../make-all.log
    ${make} test 2>&1 | tee ../make-test.log
    ${make} install 2>&1 | tee ../make-install.log
fi
echo "all done for ${0##*/}"
