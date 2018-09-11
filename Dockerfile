FROM debian:stretch-slim

ENV LANG=C

ENV NODE_VERSION 8.12.0

ADD 01_nodoc /etc/dpkg/dpkg.cfg.d/
ADD 02_nolocale /etc/dpkg/dpkg.cfg.d/

RUN apt-get update -q=2 \
    && apt-get upgrade -q=2 -y \
    && apt-get install --no-install-recommends -q -y \
        ca-certificates \
        curl \
        dirmngr \
        git \
        gnupg \
        libbz2-1.0 \
        libssl1.1 \
        tar \
        xz-utils \
        zlib1g \
    && rm -rf /usr/share/locale/* \
        /usr/share/doc/* \
        /usr/share/groff/* \
        /usr/share/info/* \
        /usr/share/linda/* \
        /usr/share/lintian/* \
        /usr/share/man/* \
# Node release team GPG keys
# https://github.com/nodejs/node#release-team
    && set -ex \
    && for key in \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
        77984A986EBC2AA786BC0F66B01FBB92821C587A \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        ; do \
            gpg --recv-keys "$key" ; \
        done \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1

FROM debian:stretch-slim

COPY --from=0 /usr/local/bin /usr/local/bin
COPY --from=0 /usr/local/include /usr/local/include
COPY --from=0 /usr/local/lib /usr/local/lib

RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# Update npm to the latest version and move the node_modules/ dir in
# place. Should prevent weird errors when running 'npm install' afterwards.
RUN cd / \
    && npm install -q npm \
    && rm -rf /usr/local/lib/node_modules/ \
    && mv node_modules/ /usr/local/lib/ \
    && chown -R node:node /home/node

USER node
CMD ["node"]
