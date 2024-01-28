FROM python:3.11-bookworm
RUN apt-get update && apt-get upgrade -yqq && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  build-essential \
  libxi-dev \
  libglew-dev \
  llvm-dev \
  libgl1-mesa-dri \
  python3-pip \
  xinit \
  xvfb && \
  rm -f /usr/share/applications/x11vnc.desktop
RUN apt-get remove -y python-pip && \
  wget https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  pip install supervisor-stdout
RUN apt-get -y clean && \
  pip install -U pip && pip install pipenv && \
  curl -sSL https://install.python-poetry.org | python - && \
  rm -rf /var/lib/apt/lists/*
RUN pip install neat-python opencv-python-headless
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/bin/dumb-init
RUN chmod 0777 /usr/bin/dumb-init
COPY ./app /app
WORKDIR /app
RUN NODE_VERSION="$(curl -fsSL https://nodejs.org/dist/latest/SHASUMS256.txt | head -n1 | awk '{ print $2}' | awk -F - '{ print $2}')" \
  ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    arm64) ARCH='arm64';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && for key in $(curl -sL https://raw.githubusercontent.com/nodejs/docker-node/HEAD/keys/node.keys); do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs
RUN corepack enable yarn
RUN npm install mineflayer prismarine-viewer node-canvas-webgl
RUN npm install
ENTRYPOINT ["/usr/bin/dumb-init", "--", "xvfb-run", "-s", "-ac -screen 0 1280x1024x24"]
CMD ["/app/Start.sh"]