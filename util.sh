#!/bin/sh
set -x

_logfilter() {
  grep -E -v '^(Get:|Preparing|Unpacking|Setting up|Processing triggers|Removing)'
}

_createchroot() {
  for ARCH in amd64; do \
    for DIST in stable testing unstable; do \
      LANG=C sbuild-createchroot --arch=$ARCH --include=eatmydata,ccache,gnupg $DIST \
           /srv/chroot/$DIST-$ARCH-sbuild http://deb.debian.org/debian; \
    done;
  done
}

_updatechroot() {
  {
  sudo apt update && sudo apt -y full-upgrade && sudo apt -y autoremove --purge && sudo apt clean
  schroot -l | awk -F : '/sbuild/{print $2}' | while read CHROOT
  do
    sudo sbuild-update -udcar $CHROOT
  done
  } | _logfilter
}

_fixchroot() {
  for conf in $(grep -l '^union-type=none' /etc/schroot/chroot.d/*-sbuild*); do
#    sudo sed -i -e 's/union-type=none/union-type=overlay\n/' "$conf"
#    echo 'union-overlay-directory=/dev/shm' | sudo tee --append "$conf"
    echo 'command-prefix=eatmydata' | sudo tee --append "$conf"
#   echo 'command-prefix=/var/cache/ccache-sbuild/sbuild-setup,eatmydata' | sudo tee --append "$conf"
  done
}

_cleanchroot() {
  sudo schroot --end-session --all-sessions
}

_buildpackage() {
  sbuild -j $(nproc) --build-dir=/output -A -s -d unstable --source-only-changes #| _logfilter
}

_sbuild() {
  local TARGET=$2

  case "$TARGET" in
    "*.dsc")
      WORK=$PWD
    ;;
    "")
      WORK=$PWD
    ;;
    *)
    ;;
  esac

  docker run -it --rm --cap-add SYS_ADMIN -v $WORK:/work \
         -v [~/path/to/pkgs]:/output \
         -v [~/.sbuildrc]:/home/builder/.sbuildrc \
         -e http_proxy=http://[your-apt-cacher]:3142 \
         lurdan/sbuildenv /usr/local/bin/util.sh buildpackage
}

_try() {
  docker run -it --rm --cap-add SYS_ADMIN -v $PWD:/work \
         -v [~/deb/output]:/output \
         -v [~/.sbuildrc]:/home/builder/.sbuildrc \
         -e http_proxy=http://192.168.200.240:3142 \
         lurdan/sbuildenv /bin/bash
}

_$*
