#!/bin/sh
set -x
../cylus --include "CSS/*.css" --include "PHP//*.php" --ignore ignored --unused --missing --verbose
