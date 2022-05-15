# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..10} )
inherit distutils-r1

DESCRIPTION="An API wrapper for Discord written in Python"
HOMEPAGE="https://discordpy.rtfd.org/"
SRC_URI="https://github.com/Rapptz/discord.py/archive/refs/tags/v${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm64 x86"
IUSE=""

RDEPEND="dev-python/aiohttp[${PYTHON_USEDEP}]"
BDEPEND=${RDEPEND}

src_unpack() {
	default
	mv discord* ${P}
}
