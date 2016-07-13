#! /usr/bin/env bats

cp ../make-rpm.mk .

@test "make rpms. Should fail on el5 (missing group)" {
	cp test_min_el6.spec_ test.spec
	export OS_VERSIONS='5 6'
	run make rpms
    [ $status = 2 ]
}

@test "make rpms. should pass" {
	cp test_min_el5.spec_ test.spec
	export OS_VERSIONS='5 6'
	run make rpms
	[ $status = 0 ]
	stat 5/test-0.0.0-1.el5.noarch.rpm
    stat 6/test-0.0.0-1.el6.noarch.rpm
}
