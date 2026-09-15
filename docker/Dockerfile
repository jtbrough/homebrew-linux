FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Standard Homebrew-on-Linux build prerequisites + inspection tools.
# https://docs.brew.sh/Homebrew-on-Linux#requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        procps \
        curl \
        file \
        git \
        ca-certificates \
        sudo \
        locales \
        binutils \
        pkg-config \
        patchelf \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Primary sudo-capable test user (non-interactive sudo for scripted validation).
RUN useradd -m -s /bin/bash tester \
    && usermod -aG sudo tester \
    && echo "tester ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tester \
    && chmod 0440 /etc/sudoers.d/tester

# Secondary unprivileged user for multi-user execution checks.
RUN useradd -m -s /bin/bash seconduser

# /opt must not pre-exist with linuxbrew artifacts; confirm clean slate.
RUN test ! -e /home/linuxbrew && test ! -e /opt/homebrew

COPY install.sh /usr/local/bin/homebrew-install.sh
RUN chmod 755 /usr/local/bin/homebrew-install.sh

USER tester
WORKDIR /home/tester

CMD ["/bin/bash"]
