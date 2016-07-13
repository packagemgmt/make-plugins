#! /usr/bin/env bats

cp ../make-rpm.mk .

cp test_min_el5.spec_ test.spec

@test "upload el6" {
	skip
	export OS_VERSIONS='6'
	make uploadrpms
}

