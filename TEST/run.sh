#!/bin/sh
set -x
../cylus --include "CSS/*.css" --include "PHP//*.php" --ignore selected --unused --missing --verbose
