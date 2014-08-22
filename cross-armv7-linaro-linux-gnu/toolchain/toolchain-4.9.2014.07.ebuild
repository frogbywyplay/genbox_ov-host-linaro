# Copyright 2006-2013 Wyplay. All Rights Reserved.

EAPI=1

inherit eutils

DESCRIPTION="Linaro official binary toolchain release"
HOMEPAGE="http://www.linaro.org/linux-on-arm/"
SRC_URI="mirror://linaro/gcc-linaro-arm-linux-gnueabihf-4.9-2014.07_linux.tar.bz2"


LICENSE="GPL"
SLOT="0"
KEYWORDS="~x86-host" # Working but masked as gcc 4.9 is not mature enough
IUSE=""
RESTRICT="strip nomirror"

DEPEND=""
RDEPEND="dev-util/ccache"
PROVIDE="virtual/${CATEGORY}-gcc
virtual/${CATEGORY}-glibc"

CTNG_PREFIX="gcc-linaro-arm-linux-gnueabihf-4.9-2014.07_linux"

S="${WORKDIR}/${CTNG_PREFIX}"

COMPILER_DIR="/opt/toolchains/${CTNG_PREFIX}"
COMPILER_TOPDIR="${COMPILER_DIR}/bin"


SYSTEM_TUPLES="${CATEGORY/cross-}"
CT_PREFIX="arm-linux-gnueabihf"
ORIG_SYSTEM_TUPLES="arm-linux-gnueabihf"

XGCC_VERSION="4.9.1"
XBINUTILS_VERSION="2.24.0"
BINUTILS_BIN_PATH="/usr/${CHOST}/${SYSTEM_TUPLES}/binutils-bin/${XBINUTILS_VERSION}"
BINUTILS_LIB_PATH="/usr/lib/binutils/${SYSTEM_TUPLES}/${XBINUTILS_VERSION}"
GCC_BIN_PATH="/usr/${CHOST}/${SYSTEM_TUPLES}/gcc-bin/${XGCC_VERSION}"
GCC_LIB_PATH="/usr/lib/gcc/${SYSTEM_TUPLES}/${XGCC_VERSION}"

src_install() {
	rm -rf ${S}/share/doc
	dodir ${COMPILER_DIR}
	cp -a ${S}/* ${D}/${COMPILER_DIR}

	# another setup
	dosym "${COMPILER_DIR}/lib/gcc/${CT_PREFIX}/${XGCC_VERSION}" "${GCC_LIB_PATH}"

	# install binutils ldscripts
	dosym "${COMPILER_DIR}/${CT_PREFIX}/lib/ldscripts" "${BINUTILS_LIB_PATH}"


	sed -e "s|@COMPILER_DIR@|${COMPILER_DIR}|g" \
		-e "s|@TUPLES@|${SYSTEM_TUPLES}|g" \
		-e "s|@CT_PREFIX@|${ORIG_SYSTEM_TUPLES}|g" "${FILESDIR}"/"${SYSTEM_TUPLES}"-GCC-BIN > "${T}"/"${SYSTEM_TUPLES}"-GCC-BIN

	# install a directory used by gcc/binutils-config
	dodir "${GCC_BIN_PATH}"
	exeinto "${GCC_BIN_PATH}"
	for ii in c++ cpp g++ gcc gcc-${XGCC_VERSION}; do
		newexe "${T}"/"${SYSTEM_TUPLES}"-GCC-BIN "${SYSTEM_TUPLES}"-$ii
	done

	sed -e "s|@COMPILER_DIR@|${COMPILER_DIR}|g" -e "s|@TUPLES@|${SYSTEM_TUPLES}|g" -e "s|@CT_PREFIX@|${CT_PREFIX}|g" "${FILESDIR}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN > "${T}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN
	dodir "${BINUTILS_BIN_PATH}"
	exeinto "${BINUTILS_BIN_PATH}"
	for ii in ar as ld nm objcopy objdump ranlib strip; do
		newexe "${T}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN $ii
	done

	sed -e "s|@COMPILER_DIR@|${COMPILER_DIR}|g" \
		-e "s|@TUPLES@|${SYSTEM_TUPLES}|g" \
		-e "s|@CT_PREFIX@|${ORIG_SYSTEM_TUPLES}|g" "${FILESDIR}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN-2 > "${T}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN-2
	for ii in addr2line c++filt gprof readelf size strings; do
		newexe "${T}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN-2 $ii
	done

	# create required file for gcc-config
	cat > ${T}/gcc-config.env.d << EOF
LDPATH="${GCC_LIB_PATH}"
CTARGET=${SYSTEM_TUPLES}
GCC_PATH="${GCC_BIN_PATH}"
EOF
	insinto /etc/env.d/gcc
	newins ${T}/gcc-config.env.d ${SYSTEM_TUPLES}-${XGCC_VERSION}

	cat > ${T}/binutils-config.env.d << EOF
TARGET="${SYSTEM_TUPLES}"
VER="${XBINUTILS_VERSION}"
LIBPATH="${BINUTILS_LIB_PATH}"
FAKE_TARGETS="${SYSTEM_TUPLES}"
EOF
	insinto /etc/env.d/binutils
	newins ${T}/binutils-config.env.d "${SYSTEM_TUPLES}-${XBINUTILS_VERSION}"
}

pkg_postinst() {
	gcc-config "${SYSTEM_TUPLES}-${XGCC_VERSION}"
	binutils-config "${SYSTEM_TUPLES}-${XBINUTILS_VERSION}"
	ccache-config --install-links ${SYSTEM_TUPLES}
}
