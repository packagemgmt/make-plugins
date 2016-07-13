#! /usr/bin/env bats

cp ../make-rpm.mk .

@test "make rpm" {
	make rpm # test make rpm - this should pass
}

@test "fail rpms. Should fail on el5 (missing group)" {
	skip
	export OS_VERSIONS='5 6'
	make rpms
}

@test "test upload with snapshots" {
	RELEASE=SNAPSHOT make uploadrpms  # test uploading to snapshot repo
}

@test "test classic upload" {
	make uploadrpms  # test uploading to release repo
}

artifact delete ${REPOSITORY_URL}/content/repositories/packages-el6/com/example # crean after uploading to release repo so we can run it twice (be idempotent)
