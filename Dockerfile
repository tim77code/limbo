FROM ubuntu

# Use --no-cache to update caching of this:
RUN apt-get update

RUN set -ex; \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install apt-utils; \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
      apt-transport-https \
      ca-certificates \
      curl \
      locales \
      lsb-release \
      software-properties-common \
    ; \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - ; \
    locale-gen en_US.UTF-8; \
    :

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN set -ex; \
    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
      docker-ce \
      gcc \
      gnupg2 \
      libffi-dev \
      libssl-dev \
      python3 \
      python3-dev \
      python3-pip \
    ; \
    ln -s /usr/bin/python3 /usr/bin/python; \
    ln -s /usr/bin/pip3 /usr/bin/pip; \
    pip install --upgrade pip setuptools; \
    pip install --upgrade awscli; \
    curl -o /usr/local/bin/ecs-cli \
            https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest; \
    chmod +x /usr/local/bin/ecs-cli; \
    :

ADD requirements.txt /app/
WORKDIR /app
RUN pip install -r requirements.txt

ADD bin/limbo /app/bin/limbo
ADD limbo /app/limbo/
ADD setup.py /app/
RUN set -ex; \
    python setup.py install; \
    rm -rf build dist limbo.egg-info; \
    :

ADD test /app/test/

ADD bin/ecs.sh /app/bin/ecs.sh
ADD bin/ecr.sh /app/bin/ecr.sh
ENV PATH "$PATH:/app/bin"
ADD docker-compose.ecs.yml /app/

ENTRYPOINT ["/usr/local/bin/limbo"]
