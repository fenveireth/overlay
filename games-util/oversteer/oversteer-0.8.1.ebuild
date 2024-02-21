EAPI=8
PYTHON_COMPAT=( python3_11 )
inherit python-single-r1 meson xdg-utils
DESCRIPTION="Graphical application to configure Logitech Wheels"
HOMEPAGE="https://github.com/berarma/oversteer"
SRC_URI="https://github.com/berarma/oversteer/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="$(python_gen_cond_dep '
	dev-python/evdev[${PYTHON_USEDEP}]
	dev-python/matplotlib[${PYTHON_USEDEP}]
	dev-python/pyudev[${PYTHON_USEDEP}]
	dev-python/pyxdg[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
	')"

src_prepare() {
	eapply_user
	sed -i 's/Utility;//' data/org.berarma.Oversteer.desktop.in
	rm oversteer/*.swp
}

src_configure() {
	local emesonargs=(
		-D python=$EPYTHON
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	python_optimize
}

pkg_postinst() {
	xdg_icon_cache_update
}

