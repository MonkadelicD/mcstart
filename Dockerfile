FROM ubuntu:26.04

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      tmux \
      tree \
      vim \
      shellcheck \
      openjdk-8-jdk \
      openjdk-17-jdk \
      openjdk-21-jdk \
      openjdk-25-jdk \
 && rm -rf /var/lib/apt/lists/*

COPY mcstart /usr/local/bin/mcstart
COPY test-servers.sh /usr/local/bin/test-servers
RUN chmod 0755 /usr/local/bin/mcstart /usr/local/bin/test-servers

ENV HOME=/home/vitadmin
WORKDIR /home/vitadmin
USER ${UID}:${GID}

CMD ["test-servers", "quick"]
