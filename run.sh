#!/bin/bash

BASEDIR=$(dirname $(readlink -f "$0"))
LOGDIR=${BASEDIR}/output-log
mkdir -p ${LOGDIR}

cd ${BASEDIR}

_init() {
  apt update
  apt -y full-upgrade
  apt build-dep linux
  apt clean
  apt source linux
  ( cd linux-*; make olddefconfig)
}
ls linux-* >/dev/null 2>&1 || _init

_diag() {
  apt install -y dmidecode pciutils >/dev/null 2>&1
  mkdir -p output-diag
  cd output-diag

  dmidecode > dmidecode.txt
  sysctl -a > sysctl.txt 2>/dev/null
  lspci -vvv -k > lspci.txt

  dpkg -l > package-list.txt
  lsb_release -a > lsb.txt
  uname -a > uname.txt
  dmesg > dmesg.txt
}
[ -d output-diag ] || _diag

_build() {
  echo "Loop reset. Maybe system hung occurred.
ASLR Setting: $(sysctl kernel.randomize_va_space)" >> ${LOGDIR}/loop-summary.log

  for ((i=1;1;i++)); do
    STAMP=$(date +%s)
    cd ${BASEDIR}/linux-*
    time make -j16 >${LOGDIR}/build-${STAMP}.log 2>&1
    {
      [ $? -eq 0 ] && echo -n "OK: " || echo -n "NG: "
      echo "Loop: $i: ${STAMP}"
    } >> ${LOGDIR}/loop-summary.log
    make clean >/dev/null 2>&1
  done
}
_build

