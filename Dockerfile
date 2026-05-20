FROM debian:trixie
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "deb [trusted=yes] http://archive.raspberrypi.com/debian/ trixie main" > /etc/apt/sources.list.d/raspi.list
RUN apt-get update && \
    apt-get install -y --no-install-recommends raspberrypi-archive-keyring && \
    rm -rf /var/lib/apt/lists/*
RUN echo "deb http://archive.raspberrypi.com/debian/ trixie main" > /etc/apt/sources.list.d/raspi.list
RUN apt-get update && apt-get install -y --no-install-recommends \
    devscripts \
    equivs \
    curl

RUN curl -fsSL https://zarcsis.github.io/dronerepo/repo.key | tee /etc/apt/trusted.gpg.d/dronerepo.asc

RUN echo "deb https://zarcsis.github.io/dronerepo/ trixie main" > /etc/apt/sources.list.d/dronerepo.list

WORKDIR /workspace

COPY debian/control debian/control
RUN apt-get update && mk-build-deps -i -r -t 'apt-get -y --no-install-recommends' debian/control

CMD ["/bin/bash"]
