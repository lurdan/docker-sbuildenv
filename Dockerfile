FROM debian:sid AS base
MAINTAINER lurdan@gmail.com

RUN echo "deb-src http://deb.debian.org/debian sid main contrib\n" >> /etc/apt/sources.list.d/source.list && \
  apt update && apt -y full-upgrade && apt -y install --no-install-recommends build-essential devscripts debhelper sudo && apt -y autoremove --purge && apt clean

RUN adduser builder && \
    gpasswd -a builder sudo && \
    echo 'Defaults visiblepw'             >> /etc/sudoers && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    echo 'Set disable_coredump false' > /etc/sudo.conf

WORKDIR /work

FROM base AS sbuild

RUN DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends sbuild schroot lintian-brush piuparts git-buildpackage pristine-tar quilt vim && \
  apt -y autoremove && apt clean && sbuild-adduser builder && newgrp sbuild
COPY util.sh /usr/local/bin
RUN mkdir /output && chown builder /output && util.sh createchroot

USER builder
RUN cp /usr/share/doc/sbuild/examples/example.sbuildrc /home/builder/.sbuildrc
