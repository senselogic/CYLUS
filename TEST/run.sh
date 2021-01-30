#!/bin/sh
set -x
../clash --missing --unused --verbose "CSS/*.css" "PHP//*.php"
