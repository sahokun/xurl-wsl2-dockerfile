FROM debian:bookworm-slim

ARG XURL_VERSION=1.0.3

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    iproute2 \
    socat \
    && rm -rf /var/lib/apt/lists/*

# アーキテクチャに応じた xurl バイナリをインストール
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
        amd64)  XURL_ARCH="x86_64" ;; \
        arm64)  XURL_ARCH="arm64"  ;; \
        i386)   XURL_ARCH="i386"   ;; \
        *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL \
      "https://github.com/xdevplatform/xurl/releases/download/v${XURL_VERSION}/xurl_Linux_${XURL_ARCH}.tar.gz" \
      | tar -xzC /usr/local/bin xurl && \
    chmod +x /usr/local/bin/xurl

WORKDIR /root

# OAuth 2.0 コールバックポート (X Developer Portal に登録した URL に合わせること)
EXPOSE 8080

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
