#!/bin/sh
set -x
dmd -O -inline -m64 cylus.d
rm *.o
