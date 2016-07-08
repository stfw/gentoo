# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit systemd

HOMEPAGE="https://www.zerotier.com/"
DESCRIPTION="ZeroTier is a software-based managed Ethernet switch for planet Earth."
SRC_URI="https://github.com/zerotier/ZeroTierOne/archive/${PV}.tar.gz"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
S="${WORKDIR}/ZeroTierOne-${PV}"

RDEPEND="net-libs/http-parser
	net-libs/miniupnpc
	net-libs/libnatpmp
	dev-libs/json-glib"

DEPEND="${RDEPEND}
	app-text/ronn"

QA_PRESTRIPPED="/usr/sbin/zerotier-one"

src_install() {
	emake DESTDIR="${D}" install
	dodoc README.md AUTHORS.md
	doinitd "${FILESDIR}"/zerotier-one
	systemd_dounit "${FILESDIR}"/zerotier-one.service
}

pkg_postinst() {
	elog "If you previously had ZeroTier-One installed from their generic"
	elog "script, you may need to rejoin your network(s) with"
	elog ""
	elog "\"zerotier-cli join <network>\""
	elog ""
}
