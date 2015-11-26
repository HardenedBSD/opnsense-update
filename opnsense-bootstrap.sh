#!/bin/sh

# Copyright (c) 2015 Franco Fichtner <franco@opnsense.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

set -e

WORKDIR="/tmp/opnsense-bootstrap"
FLAVOUR="OpenSSL"
ARCH=$(uname -m)
VERSION="15.7"

DO_FACTORY=
DO_YES=

while getopts fn:vy OPT; do
	case ${OPT} in
	f)
		DO_FACTORY="-f"
		;;
	n)
		if [ "${OPTARG}" == "LibreSSL" ]; then
			FLAVOUR=${OPTARG}
		fi
		;;
	v)
		echo ${VERSION}-${ARCH}
		exit 0
		;;
	y)
		DO_YES="-y"
		;;
	*)
		echo "Usage: opnsense-bootstrap [-fvy] [-n flavour]" >&2
		exit 1
		;;
	esac
done

if [ "$(id -u)" != "0" ]; then
	echo "Must be root."
	exit 1
fi

if [ "$(uname -s)" != "FreeBSD" ]; then
	echo "Must be FreeBSD."
	exit 1
fi

if [ "$(uname -r | colrm 13)" != "10.1-RELEASE" ]; then
	echo "Must be 10.1."
	exit 1
fi

if [ "$(uname -m)" != "i386" -a "$(uname -m)" != "amd64" ]; then
	echo "Must be i386 or amd64"
	exit 1
fi

echo "This utility will attempt to turn this installation into the latest"
echo "OPNsense ${VERSION} release.  All packages will be deleted, the base"
echo "system and kernel will be replaced, and if all went well the system"
echo "will automatically reboot."

if [ -z "${DO_YES}" ]; then
	echo
	echo -n "Proceed with this action? [y/N]: "

	read YN
	case ${YN} in
	[yY])
		;;
	*)
		exit 0
		;;
	esac
fi

echo

export ASSUME_ALWAYS_YES=yes

pkg bootstrap
pkg install ca_root_nss

mkdir -p ${WORKDIR}/${$}
cd ${WORKDIR}/${$}
fetch https://github.com/opnsense/core/archive/stable/${VERSION}.zip
unzip ${VERSION}.zip
cd core-stable-${VERSION}

pkg delete -fa
rm -rf /usr/local/etc/pkg
if [ -n "${DO_FACTORY}" ]; then
	rm -rf /conf/*
fi

make bootstrap DESTDIR= FLAVOUR=${FLAVOUR}
pkg bootstrap
pkg install opnsense
opnsense-update -bkf
reboot
