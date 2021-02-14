#!/bin/sh
set -x
dmd -m64 chyle.d
rm *.o
