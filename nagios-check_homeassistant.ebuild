# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Nagios plugin to check if Home Assistant is running."
HOMEPAGE="https://github.com/wimvr/nagios-check_homeassistant"
SRC_URI="https://github.com/wimvr/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 x86"

DEPEND="dev-libs/libxml2"
RDEPEND="${DEPEND}"
BDEPEND=""

src_install() {
	exeinto /usr/lib64/nagios/plugins/
	doexe check_homeassistant.sh
	dodoc README
}

