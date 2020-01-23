#!/bin/sh
set -x

_createchroot() {
  for ARCH in amd64; do \
    for DIST in stable testing unstable; do \
      LANG=C sbuild-createchroot --arch=$ARCH --include=eatmydata,ccache,gnupg $DIST \
           /srv/chroot/$DIST-$ARCH-sbuild http://deb.debian.org/debian; \
    done;
  done
}

_updatechroot() {
  schroot -l | awk -F : '/sbuild/{print $2}' | while read CHROOT
  do
    sudo sbuild-update -udcar $CHROOT
  done
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
  sbuild --build-dir=/output -d unstable
}

_$1
