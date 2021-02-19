#!/bin/sh
set -x
dmd -m64 cylus.d
rm *.o
