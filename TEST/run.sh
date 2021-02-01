#!/bin/sh
set -x
../clash --include "CSS/*.css" --include "PHP//*.php" --unused --missing --verbose
