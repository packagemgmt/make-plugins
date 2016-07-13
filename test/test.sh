#! /bin/bash

set -e
set -x
set -o pipefail

cp ../make-rpm.mk .
make rpm # test make rpm
export OS_VERSIONS='5 6'
RELEASE=SNAPSHOT make uploadrpms  # test uploading to snapshot repo
make uploadrpms  # test uploading to release repo
artifact delete ${REPOSITORY_URL}/content/repositories/packages-el6/com/example # crean after uploading to release repo so we can run it twice (be idempotent)
