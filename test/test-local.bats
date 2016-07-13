#! /usr/bin/env bats

cp ../make-rpm.mk .

@test "make rpm" {
	make rpm # test make rpm - this should pass
}

@test "fail rpms. Should fail on el5 (missing group)" {
	cp test_min_el6.spec test.spec
	export OS_VERSIONS='5 6'
	make rpms
}

@test "should pass" {
	cp test_min_el5.spec test.spec
	export OS_VERSIONS='5 6'
	make rpms
}
