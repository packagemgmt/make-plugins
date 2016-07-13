#! /usr/bin/env bats

cp ../make-rpm.mk .

@test "make rpm" {
	cp test_min_el5.spec_ test.spec
	make rpm # test make rpm - this should pass
}

@test "fail rpms. Should fail on el5 (missing group)" {
	skip
	cp test_min_el6.spec_ test.spec
	export OS_VERSIONS='5 6'
	make rpms
}

@test "should pass" {
	skip
	cp test_min_el5.spec_ test.spec
	export OS_VERSIONS='5 6'
	make rpms
}
