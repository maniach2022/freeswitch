FROM debian:bullseye-slim
LABEL maintainer="DevOps <devops@freeswitch.org>"

# Setting environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV FS_USER=freeswitch
ENV FS_GROUP=freeswitch
ENV FS_HOME=/opt/freeswitch

# Create FreeSWITCH user and group
RUN groupadd -r ${FS_GROUP} && \
    useradd -r -g ${FS_GROUP} -d ${FS_HOME} ${FS_USER}

# Install basic tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build tools
    build-essential \
    cmake \
    automake \
    autoconf \
    libtool-bin \
    pkg-config \
    git \
    ca-certificates \
    # Core dependencies
    libssl-dev \
    zlib1g-dev \
    libdb-dev \
    unixodbc-dev \
    libncurses5-dev \
    libexpat1-dev \
    libgdbm-dev \
    bison \
    erlang-dev \
    libtpl-dev \
    libtiff5-dev \
    uuid-dev \
    # Core codec dependencies
    libogg-dev \
    libspeex-dev \
    libspeexdsp-dev \
    # Required libraries
    libpcre2-dev \
    libedit-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    nasm \
    # Module dependencies
    libldns-dev \
    python3-dev \
    libavformat-dev \
    libswscale-dev \
    libswresample-dev \
    liblua5.2-dev \
    libopus-dev \
    libpq-dev \
    libsndfile1-dev \
    libflac-dev \
    libvorbis-dev \
    libshout3-dev \
    libmpg123-dev \
    libmp3lame-dev \
    # Additional libraries
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build dependencies
WORKDIR /usr/src

# Clone required libraries
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks && \
    git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip && \
    git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp && \
    git clone https://github.com/signalwire/signalwire-c /usr/src/libs/signalwire-c

# Build and install libks
WORKDIR /usr/src/libs/libks
RUN cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && \
    make -j$(nproc) install

# Build and install sofia-sip
WORKDIR /usr/src/libs/sofia-sip
RUN ./bootstrap.sh && \
    ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && \
    make -j$(nproc) && \
    make install

# Build and install spandsp
WORKDIR /usr/src/libs/spandsp
RUN ./bootstrap.sh && \
    ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && \
    make -j$(nproc) && \
    make install

# Build and install signalwire-c
WORKDIR /usr/src/libs/signalwire-c
RUN PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && \
    make install

# Copy the FreeSWITCH source code
COPY . /usr/src/freeswitch

# Build FreeSWITCH
WORKDIR /usr/src/freeswitch
RUN ./bootstrap.sh -j && \
    ./configure --enable-portable-binary \
                --prefix=${FS_HOME} \
                --with-rundir=/var/run/freeswitch \
                --with-logdir=/var/log/freeswitch && \
    make -j$(nproc) && \
    make install && \
    make cd-sounds-install && \
    make cd-moh-install

# Cleanup source and build dependencies
RUN apt-get update && apt-get -y install --no-install-recommends \
        libssl1.1 \
        libpcre2-8-0 \
        libsqlite3-0 \
        libspeex1 \
        libspeexdsp1 \
        libedit2 \
        libogg0 \
        libvorbis0a \
        libvorbisenc2 \
        libvorbisfile3 \
        libtiff5 \
        libopus0 \
        libsndfile1 \
        libflac8 \
        libshout3 \
        libmpg123-0 \
        libmp3lame0 \
        libcurl4 \
        libncurses5 \
        uuid-dev \
        libavformat58 \
        libswscale5 \
        libswresample3 \
        libldns2 \
        libdb5.3 \
        libsodium23 \
    && apt-get purge -y --auto-remove \
        build-essential \
        cmake \
        automake \
        autoconf \
        libtool-bin \
        pkg-config \
        git \
        ca-certificates \
        libssl-dev \
        zlib1g-dev \
        libdb-dev \
        unixodbc-dev \
        libncurses5-dev \
        libexpat1-dev \
        libgdbm-dev \
        bison \
        erlang-dev \
        libtpl-dev \
        libtiff5-dev \
        libogg-dev \
        libspeex-dev \
        libspeexdsp-dev \
        libpcre2-dev \
        libedit-dev \
        libsqlite3-dev \
        libcurl4-openssl-dev \
        nasm \
        libldns-dev \
        python3-dev \
        libavformat-dev \
        libswscale-dev \
        libswresample-dev \
        liblua5.2-dev \
        libopus-dev \
        libpq-dev \
        libsndfile1-dev \
        libflac-dev \
        libvorbis-dev \
        libshout3-dev \
        libmpg123-dev \
        libmp3lame-dev \
        libsodium-dev \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/src/* \
    && ldconfig

# Create necessary directories and set permissions
RUN mkdir -p /var/lib/freeswitch/storage /var/lib/freeswitch/recordings /var/lib/freeswitch/db \
             /var/log/freeswitch /var/run/freeswitch && \
    chown -R ${FS_USER}:${FS_GROUP} ${FS_HOME} /var/lib/freeswitch /var/log/freeswitch /var/run/freeswitch

# Set working directory and volume
WORKDIR ${FS_HOME}
VOLUME ["${FS_HOME}/conf", "${FS_HOME}/recordings", "${FS_HOME}/storage"]

# Expose FreeSWITCH ports
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5066/tcp 7443/tcp
EXPOSE 8021/tcp
EXPOSE 16384-32768/udp

# Switch to the FreeSWITCH user
USER ${FS_USER}

# Set the entry point
ENTRYPOINT ["${FS_HOME}/bin/freeswitch"]
CMD ["-nonat", "-nf", "-nc"]