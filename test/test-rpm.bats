#! /usr/bin/env bats

cp ../make-rpm.mk .

@test "make rpm" {
	cp test_min_el5.spec_ test.spec
	rpmdev-wipetree
	make rpm # test make rpm - this should pass
	stat ~/rpmbuild/RPMS/noarch/test-0.0.0-1.el6.noarch.rpm
}

