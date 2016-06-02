# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit eutils user systemd #multilib

DESCRIPTION="Recorder for storing and accessing location data published by OwnTracks apps."
HOMEPAGE="http://owntracks.org/ https://github.com/owntracks/recorder"
SRC_URI="https://github.com/owntracks/recorder/archive/${PV}.tar.gz -> recorder-${PV}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+mqtt http lua sodium"
REQUIRED_USE="|| ( mqtt http )"
S="${WORKDIR}/recorder-${PV}"

DEPEND="${RDEPEND}
	net-misc/curl
	dev-libs/libconfig
	mqtt? ( app-misc/mosquitto )
	lua? ( dev-lang/lua )
	sodium? ( dev-libs/libsodium )"

pkg_setup() {
	enewgroup owntracks
	enewuser owntracks -1 -1 -1 owntracks
}

src_prepare() {
	cp config.mk.in config.mk
	epatch "${FILESDIR}/no-http.patch"
	sed -i 's:^# OTR_TOPICS="owntracks/+/+":OTR_TOPICS="owntracks/+/+":' etc/ot-recorder.default || die
	default
}

src_configure() {
	sed -e "s:INSTALLDIR = /usr/local:INSTALLDIR = /usr\nMAKEOPTS = -j1:" \
		-e "s:CONFIGFILE = /etc/defaults/ot-recorder:CONFIGFILE = /etc/ot-recorder:" \
		-i config.mk || die

	makeopts=(
		"WITH_MQTT=$(usex mqtt)"
		"WITH_HTTP=$(usex http)"
		"WITH_LUA=$(usex lua)"
		"WITH_ENCRYPT=$(usex sodium)"
	)

	einfo "${makeopts[@]}"
}

src_compile() {
	emake -j 1 "${makeopts[@]}"
}

src_install() {
	emake "${makeopts[@]}" DESTDIR="${D}" prefix=/usr install

	keepdir /var/spool/owntracks/recorder/store
	use http && keepdir /var/spool/owntracks/recorder/htdocs
	fowners -R owntracks:owntracks /var/spool/owntracks/recorder
	dodoc README.md Changelog
	doinitd "${FILESDIR}/ot-recorder"
	systemd_dounit "${FILESDIR}/ot-recorder.service"
}

pkg_postinst() {
	if [ ! -f /var/spool/owntracks/recorder/store/ghash/data.mdb ]; then
		elog "You must initialise the recorder database with"
		elog "    emerge --config ${CATEGORY}/${PN}"
		elog ""
	fi
}

pkg_config() {
	"${ROOT}"/usr/sbin/ot-recorder --initialize
	chown -R owntracks:owntracks /var/spool/owntracks/recorder/store/ghash
}
