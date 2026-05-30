FROM debian:trixie
ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture arm64

# Keep the Raspberry Pi archive below Debian (priority 100 < the default 500).
# The rpt archive ships some core multi-arch libraries (notably libc6) at a
# higher version than Debian, e.g. libc6 2.41-12+rpt1+deb13u2 vs Debian's
# 2.41-12+deb13u3. A cross-install requires libc6:amd64 (for the native build
# tools) and libc6:arm64 (the target libc) to be the *exact same* version, but
# libc6:amd64 only exists in Debian. If apt preferred the rpt arm64 libc the two
# would diverge and the build-dependency set would become unsatisfiable
# (libc6:amd64 Breaks libc6:arm64 != <amd64 version>). Pinning rpt low makes
# Debian win for any package present in both, while rpt-exclusive packages stay
# installable.
RUN printf 'Package: *\nPin: origin archive.raspberrypi.com\nPin-Priority: 100\n' \
    > /etc/apt/preferences.d/00-raspberrypi-lowprio

# The stock Debian sources (deb.debian.org) serve every release architecture,
# so they provide both the native amd64 build tools and the arm64 host
# libraries. The third-party repos below only publish arm64 packages, so each
# is pinned to [arch=arm64]; otherwise `apt-get update` would 404 looking for a
# non-existent amd64 index on those hosts.

# Raspberry Pi archive (arm64 only).
RUN echo "deb [arch=arm64 trusted=yes] http://archive.raspberrypi.com/debian/ trixie main" > /etc/apt/sources.list.d/raspi.list
RUN apt-get update && \
    apt-get install -y --no-install-recommends raspberrypi-archive-keyring && \
    rm -rf /var/lib/apt/lists/*
RUN echo "deb [arch=arm64] http://archive.raspberrypi.com/debian/ trixie main" > /etc/apt/sources.list.d/raspi.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    devscripts \
    equivs \
    curl \
    crossbuild-essential-arm64

# Target-arch C++ runtime as a real multiarch package. crossbuild-essential
# only provides libstdc++ via libstdc++6-arm64-cross, which installs under the
# compiler sysroot (/usr/aarch64-linux-gnu/lib) where dpkg-shlibdeps does not
# look. Without the proper libstdc++6:arm64 (installed under
# /usr/lib/aarch64-linux-gnu), the final dh_shlibdeps step fails to resolve the
# library's ${shlibs:Depends} ("cannot find library libstdc++.so.6"). Its
# version must match libstdc++6:amd64 (Multi-Arch: same); the rpt pin above
# keeps both coming from Debian so they stay in lockstep.
RUN apt-get install -y --no-install-recommends libstdc++6:arm64

RUN curl -fsSL https://zarcsis.github.io/dronerepo/repo.key | tee /etc/apt/trusted.gpg.d/dronerepo.asc

# DroneProUkr package repo (arm64 only).
RUN echo "deb [arch=arm64] https://zarcsis.github.io/dronerepo/ trixie main" > /etc/apt/sources.list.d/dronerepo.list

WORKDIR /workspace

# Install the build-dependencies resolved for the arm64 host architecture:
# the build tools stay native (cmake/debhelper/pkgconf are Multi-Arch: foreign)
# while the libraries (libssl-dev, Multi-Arch: same) come from arm64.
COPY debian/control debian/control
RUN apt-get update && mk-build-deps -i -r --host-arch arm64 -t 'apt-get -y --no-install-recommends' debian/control

CMD ["/bin/bash"]
