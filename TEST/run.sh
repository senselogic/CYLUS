#!/bin/sh
set -x
../chyle --include "CSS/*.css" --include "PHP//*.php" --ignore ignored --unused --missing --verbose
