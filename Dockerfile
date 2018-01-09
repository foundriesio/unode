FROM bitnami/minideb

ENV DEBIAN_FRONTEND=noninteractive

ENV DISABLE_WELCOME_MESSAGE 1
ENV NAMI_DEBUG 1
ENV DISABLE_LAUNCH_TRACKING 1

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 8.9.4

RUN groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# Node release team GPG keys
# https://github.com/nodejs/node#release-team
RUN install_packages gnupg dirmngr
RUN set -ex \
    && for key in \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
        56730D5401028683275BD23C23EFEFE93C4CFFFE \
        77984A986EBC2AA786BC0F66B01FBB92821C587A \
    ; do \
    gpg --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
  done

RUN install_packages \
    ca-certificates \
    curl \
    git \
    tar \
    xz-utils \
    libc6 \
    libssl1.1 \
    zlib1g \
    libbz2-1.0 \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Update npm to the latest version and move the node_modules/ dir in
# place. Should prevent weird errors when running 'npm install' afterwards.
RUN cd / \
    && npm install npm \
    && rm -rf /usr/local/lib/node_modules/ \
    && mv node_modules/ /usr/local/lib/ \
    && chown -R node:node /home/node

USER node
CMD ["node"]
