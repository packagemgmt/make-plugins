#! /bin/bash

set -e
set -x
set -o pipefail

cp ../make-rpm.mk .
make rpm
make uploadrpms
