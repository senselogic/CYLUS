#!/bin/sh
set -x
../clash --include "CSS/*.css" --include "PHP//*.php" --ignore ignored --unused --missing --verbose
