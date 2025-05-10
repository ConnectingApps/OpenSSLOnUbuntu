# --- Stage 1: builder met ca-certificates voor HTTPS download ---
FROM ubuntu:25.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Installeer build-tools, wget én ca-certificates voor HTTPS
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      wget \
      ca-certificates \
      tar \
      perl \
      zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Download & compile OpenSSL 3.5.0 statisch (no-shared)
RUN wget https://www.openssl.org/source/openssl-3.5.0.tar.gz && \
    tar -xzf openssl-3.5.0.tar.gz && \
    cd openssl-3.5.0 && \
    ./config no-shared \
      --prefix=/usr/local/ssl \
      --openssldir=/usr/local/ssl \
      zlib && \
    make -j"$(nproc)" && \
    make install_sw && \
    cd / && \
    rm -rf /build/openssl-3.5.0*

# --- Stage 2: runtime met alleen de statisch gelinkte OpenSSL ---
FROM ubuntu:25.04

ENV DEBIAN_FRONTEND=noninteractive

# Alleen ca-certificates nodig om bijv. TLS-handshakes in uw dev-omgeving te laten werken
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Kopieer de statische OpenSSL-installatie
COPY --from=builder /usr/local/ssl /usr/local/ssl

# Zorg dat de nieuwe openssl altijd vooraan in PATH staat
ENV PATH="/usr/local/ssl/bin:${PATH}"

# Bij containerstart direct een bash-shell
ENTRYPOINT ["/bin/bash"]
