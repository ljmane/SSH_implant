FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server \
        openssh-client \
        netcat-openbsd \
        wget \
        procps \
        coreutils \
        sed \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd

# Lab-only account simulating a foothold already obtained on this "target".
# Password is a throwaway for local container testing, not a real credential.
RUN useradd -m -s /bin/bash target_user \
    && echo 'target_user:LabPassword123!' | chpasswd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
