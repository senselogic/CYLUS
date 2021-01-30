#!/bin/sh
set -x
dmd -m64 clash.d
rm *.o
