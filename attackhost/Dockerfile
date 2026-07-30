FROM kalilinux/kali-rolling

RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server \
        socat \
        netcat-openbsd \
        net-tools \
        procps \
        coreutils \
        sed \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd

COPY chroot_setup.sh /root/chroot_setup.sh
RUN chmod +x /root/chroot_setup.sh

COPY attackhost/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
