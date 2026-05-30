docker build --progress=plain "$@" --platform linux/amd64 -t rpi64-builder .
docker run --rm --platform linux/amd64 -v "$(pwd):/workspace" -w /workspace rpi64-builder bash -c "mkdir -p /build && cp -r . /build/src && cd /build/src && DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -us -uc -b --host-arch arm64 --build-profiles=cross && cp ../*.deb /workspace/"
