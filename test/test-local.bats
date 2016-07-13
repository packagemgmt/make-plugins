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

