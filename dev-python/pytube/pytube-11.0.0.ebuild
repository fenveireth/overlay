# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..10} )
inherit distutils-r1

DESCRIPTION="A Python library (and command-line utility) for downloading YouTube Videos"
HOMEPAGE="https://pytube.io/"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="Unlicense"
SLOT="0"
KEYWORDS="amd64 arm64 x86"
IUSE=""

RDEPEND=""
BDEPEND=${RDEPEND}

distutils_enable_tests pytest
