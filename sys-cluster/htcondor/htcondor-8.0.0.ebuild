# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
PYTHON_COMPAT=( python{2_5,2_6,2_7} )

inherit cmake-utils python-r1 python-single-r1

DESCRIPTION="Workload management system for compute-intensive jobs"
HOMEPAGE="http://www.cs.wisc.edu/htcondor/"
SRC_URI="condor_src-${PV}-all-all.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="boinc cgroup contrib curl dmtcp doc kbdd kerberos libvirt management postgres python soap ssl xml"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

DEPEND="sys-libs/zlib
	dev-libs/libpcre
	dev-libs/boost[${PYTHON_USEDEP}]
	boinc? ( sci-misc/boinc )
	cgroup? ( dev-libs/libcgroup )
	curl? ( net-misc/curl[ssl?] )
	dmtcp? ( sys-apps/dmtcp )
	libvirt? ( app-emulation/libvirt )
	kerberos? ( virtual/krb5 )
	kbdd? ( x11-libs/libX11 )
	management? ( net-libs/qmf )
	postgres? ( dev-db/postgresql-base )
	python? ( ${PYTHON_DEPS} )
	soap? ( net-libs/gsoap[ssl?] )
	ssl? ( dev-libs/openssl )
	xml? ( dev-libs/libxml2 )"

RDEPEND="${DEPEND}
	mail-client/mailx"

RESTRICT=fetch

S="${WORKDIR}/condor-${PV}"

src_configure() {
	local mycmakeargs="
		$(cmake-utils_use_have boinc backfill)
		$(cmake-utils_use_have boinc)
		$(cmake-utils_use_with cgroup libcgroup)
		$(cmake-utils_use_want contrib)
		$(cmake-utils_use_have dmtcp)
		$(cmake-utils_use_want doc man_pages)
		$(cmake-utils_use_with libvirt)
		$(cmake-utils_use_have kbdd)
		$(cmake-utils_use_with kerberos krb5)
		$(cmake-utils_use_with postgres postgresql)
		$(cmake-utils_use_with python python_bindings)
		$(cmake-utils_use_with management)
		$(cmake-utils_use_with soap gsoap)
		$(cmake-utils_use_with ssl openssl)
		$(cmake-utils_use_with xml libxml2)"
	cmake-utils_src_configure
}