# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools estack eutils flag-o-matic multilib multilib-minimal

MY_PN="wine"
WINEVER="7.7"
MAJOR_V=${WINEVER%%.*}
_winesrcdir="wine-${WINEVER}"

EGIT_REPO_URI="/home/fen/dev/wine-wayland"
GWP_V="20211122"
SRC_URI="https://github.com/varmd/${PN}/archive/refs/tags/v${PV}.tar.gz
	https://dl.winehq.org/wine/source/${MAJOR_V}.x/wine-${WINEVER}.tar.xz
	https://dev.gentoo.org/~sarnex/distfiles/wine/gentoo-wine-patches-${GWP_V}.tar.xz"
PATCHDIR="${WORKDIR}/gentoo-wine-patches"
KEYWORDS="~amd64"

DESCRIPTION="Wine, patched as to have video games running on native wayland"
HOMEPAGE="https://github.com/varmd/wine-wayland"
LICENSE="LGPL-2.1"
SLOT="${WINEVER}"

IUSE="+abi_x86_32 +abi_x86_64 +alsa custom-cflags +fontconfig +gecko gstreamer kerberos mingw nls openal opencl +opengl osmesa oss pulseaudio +realtime pcap sdl +ssl +threads +truetype udev +udisks +unwind usb vkd3d vulkan"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )"
RESTRICT="test"

BDEPEND="sys-devel/flex
	virtual/yacc
	virtual/pkgconfig"

COMMON_DEPEND="
	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	fontconfig? ( media-libs/fontconfig:=[${MULTILIB_USEDEP}] )
	gstreamer? (
		media-libs/gstreamer:1.0[${MULTILIB_USEDEP}]
		media-plugins/gst-plugins-meta:1.0[${MULTILIB_USEDEP}]
	)
	kerberos? ( virtual/krb5[${MULTILIB_USEDEP}] )
	nls? ( sys-devel/gettext[${MULTILIB_USEDEP}] )
	openal? ( media-libs/openal:=[${MULTILIB_USEDEP}] )
	opencl? ( virtual/opencl[${MULTILIB_USEDEP}] )
	opengl? (
		virtual/opengl[${MULTILIB_USEDEP}]
	)
	osmesa? ( >=media-libs/mesa-13[osmesa,${MULTILIB_USEDEP}] )
	pcap? ( net-libs/libpcap[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio[${MULTILIB_USEDEP}] )
	sdl? ( media-libs/libsdl2:=[haptic,joystick,${MULTILIB_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${MULTILIB_USEDEP}] )
	truetype? ( >=media-libs/freetype-2.0.0[${MULTILIB_USEDEP}] )
	udev? ( virtual/libudev:=[${MULTILIB_USEDEP}] )
	udisks? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	unwind? ( sys-libs/libunwind[${MULTILIB_USEDEP}] )
	usb? ( virtual/libusb:1[${MULTILIB_USEDEP}]  )
	vkd3d? ( >=app-emulation/vkd3d-1.2[${MULTILIB_USEDEP}] )
	vulkan? ( media-libs/vulkan-loader[${MULTILIB_USEDEP}] )"
RDEPEND="${COMMON_DEPEND}
	app-emulation/wine-desktop-common
	>app-eselect/eselect-wine-0.3
	gecko? ( app-emulation/wine-gecko:2.47.2[abi_x86_32?,abi_x86_64?] )
	pulseaudio? (
		realtime? ( sys-auth/rtkit )
	)
	udisks? ( sys-fs/udisks:2 )"
DEPEND="${COMMON_DEPEND}
	${BDEPEND}
	>=sys-kernel/linux-headers-2.6"

PATCHES=(
	"${PATCHDIR}/patches/${MY_PN}-6.22-winegcc.patch"
	"${PATCHDIR}/patches/${MY_PN}-4.7-multilib-portage.patch"
	"${PATCHDIR}/patches/${MY_PN}-2.0-multislot-apploader.patch"
)

pkg_setup() {
	WINE_VARIANT="wayland-${WINEVER}"

	MY_PREFIX="${EPREFIX}/usr/lib/wine-${WINE_VARIANT}"
	MY_DATAROOTDIR="${EPREFIX}/usr/share/wine-${WINE_VARIANT}"
	MY_DATADIR="${MY_DATAROOTDIR}"
	MY_DOCDIR="${EPREFIX}/usr/share/doc/${PF}"
	MY_INCLUDEDIR="${EPREFIX}/usr/include/wine-${WINE_VARIANT}"
	MY_LIBEXECDIR="${EPREFIX}/usr/libexec/wine-${WINE_VARIANT}"
	MY_LOCALSTATEDIR="${EPREFIX}/var/wine-${WINE_VARIANT}"
	MY_MANDIR="${MY_DATADIR}/man"
}

src_unpack() {
	tar xpf ../distdir/v${PV}.tar.gz
	cd "${S}"
	tar xpf ../../distdir/wine-${WINEVER}.tar.xz
	cd ..
	tar xpf ../distdir/gentoo-wine-patches-${GWP_V}.tar.xz
}

src_prepare() {
	cd ${_winesrcdir}
	local md5="$(md5sum server/protocol.def)"
	default

	ln -s "${S}"/winewayland* dlls/

	eapply "${S}"/patches/enable-wayland.patch

	eapply "${S}"/patches/fix-civ6.patch

	patch programs/explorer/desktop.c < "${S}"/patches/wayland-explorer.patch

	cp "${S}"/patches/fsync/fsync-copy/ntdll/* dlls/ntdll/unix/
	cp "${S}"/patches/fsync/fsync-copy/server/* server/

	for f in "${S}"/patches/fsync/fsync/*.patch; do
		eapply "${f}"
	done

	for f in "${S}"/patches/fsync/fsync/ntdll/*.patch; do
		eapply "${f}"
	done

	for f in "${S}"/patches/fsync/misc/*.patch; do
		eapply "${f}"
	done

	eapply "${S}"/patches/fsync/fix-rt.patch

	for _f in "${S}"/patches/fsr/*.patch; do
		eapply "${_f}"
	done
	cp "${S}"/patches/fsr/vulkan-fsr-include.c dlls/winevulkan/

	eautoreconf

	if [[ "$(md5sum server/protocol.def)" != "${md5}" ]]; then
		einfo "server/protocol.def was patched; running tools/make_requests"
		tools/make_requests || die #432348
	fi
}

src_configure() {
	export LDCONFIG=/bin/true
	use custom-cflags || strip-flags
	if use mingw; then
		export CROSSCFLAGS="${CFLAGS}"
	fi

	multilib-minimal_src_configure
}

multilib_src_configure() {

	local myconf=(
		--prefix="${MY_PREFIX}"
		--datarootdir="${MY_DATAROOTDIR}"
		--datadir="${MY_DATADIR}"
		--docdir="${MY_DOCDIR}"
		--includedir="${MY_INCLUDEDIR}"
		--libdir="${EPREFIX}/usr/$(get_libdir)/wine-${WINE_VARIANT}"
		--libexecdir="${MY_LIBEXECDIR}"
		--localstatedir="${MY_LOCALSTATEDIR}"
		--mandir="${MY_MANDIR}"
		--sysconfdir="${EPREFIX}/etc/wine"
		$(use_with alsa)
		--without-capi
		--without-cups
		$(use_with udisks dbus)
		$(use_with fontconfig)
		$(use_with ssl gnutls)
		$(use_enable gecko mshtml)
		--without-gphoto
		--without-gssapi
		$(use_with gstreamer)
		$(use_with kerberos krb5)
		$(use_with mingw)
		--without-netapi
		$(use_with nls gettext)
		$(use_with openal)
		$(use_with opencl)
		$(use_with opengl)
		$(use_with osmesa)
		$(use_with oss)
		$(use_with pcap)
		$(use_with pulseaudio pulse)
		$(use_with threads pthread)
		--without-sane
		$(use_with sdl)
		$(use_with truetype freetype)
		$(use_with udev)
		$(use_with usb)
		$(use_with unwind)
		--without-v4l2
		$(use_enable vkd3d)
		$(use_with vulkan)
		--without-x
		--without-xinerama
		--without-xrandr
		--without-xcomposite
		--without-xcursor
		--without-xfixes
		--without-xshape
		--without-xrender
		--without-xinput
		--without-xinput2
		--without-xxf86vm
		--without-xshm
		--disable-win16
		--disable-tests
	)

	local PKG_CONFIG
	tc-export PKG_CONFIG

	if use amd64; then
		if [[ ${ABI} == amd64 ]]; then
			myconf+=( --enable-win64 )
		else
			myconf+=( --disable-win64 )
		fi
	fi

	ECONF_SOURCE=${S}/${_winesrcdir}
	econf "${myconf[@]}"
	emake depend
}

multilib_src_install_all() {

	# Avoid double prefix from dosym and make_wrapper
	MY_PREFIX=${MY_PREFIX#${EPREFIX}}

	if use abi_x86_64 && ! use abi_x86_32; then
	    dosym wine64 "${MY_PREFIX}"/bin/wine # 404331
	    dosym wine64-preloader "${MY_PREFIX}"/bin/wine-preloader
	fi

	# Failglob for binloops, shouldn't be necessary, but including to stay safe
	eshopts_push -s failglob #615218
	# Make wrappers for binaries for handling multiple variants
	# Note: wrappers instead of symlinks because some are shell which use basename
	local b
	for b in "${ED%/}${MY_PREFIX}"/bin/*; do
	    make_wrapper "${b##*/}-${WINE_VARIANT}" "${MY_PREFIX}/bin/${b##*/}"
	done
	eshopts_pop
}

pkg_postinst() {
	eselect wine register "${PN}-${WINEVER}"
	eselect wine update --all --if-unset || die
}

pkg_prerm() {
	eselect wine deregister "${PN}-${WINEVER}"
	eselect wine update --all --if-unset || die
}
