#!/bin/sh
set -x
dmd -O -m64 cylus.d
rm *.o
